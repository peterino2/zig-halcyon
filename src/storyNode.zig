const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const parser = @import("parser.zig");
const TokenStream = parser.TokenStream;

pub const Node = struct {
    id: usize = 0,
    generation: u32 = 0,
};

pub const LocKey = struct {
    key: u32,
    keyName: ArrayList(u8),

    const Self = @This();

    // generates a new localization id with a random value (todo)
    pub fn newAutoKey(alloc: std.mem.Allocator) ! LocKey {
        return LocKey{
            .key = 0,
            .keyName = ArrayList(u8).init(alloc)
        };
    }

    pub fn deinit(self : *Self) void
    {
        self.keyName.deinit();
    }
};

pub const NodeString = struct { 
    string: ArrayList(u8),
    locKey: LocKey,

    const Self = @This();

    pub fn initAuto(alloc: std.mem.Allocator) Self
    {
        return  NodeString {
            .string = try ArrayList(u8).init(alloc),
            .locKey = LocKey.newAutoKey(alloc),
        };
    }

    pub fn deinit(self : *Self) void {
        self.string.deinit();
        self.locKey.deinit();
    }

    pub fn setUtf8NativeText(self: *Self, text: []const u8) *Self
    {
        if(self.string.items.len > 0)
        {
            try self.string.clearAndFree();
        }
        try self.string.appendSlice(text);
        return self;
    }
    
    pub fn fromUtf8(text: []const u8, alloc: std.mem.Allocator) !NodeString
    { 
        var rv = NodeString {
            .string = try ArrayList(u8).initCapacity(alloc, text.len),
            .locKey = try LocKey.newAutoKey(alloc),
        };

        _ = try rv.string.appendSlice(text);

        return rv;
    }

    // returns the native text
    pub fn asUtf8Native(self: Self) ![]const u8{
        return self.string.items;
    }
};

pub const NodeStringView = []const u8;

pub const NodeType = enum(u8) {
    Dead, // set to this to effectively mark this node as dead
    Text,
    Response,
};

const StoryNodesError = error {
    InstancesNotExistError,
    GeneralError
};

const StoryNodes = struct {
    instances: ArrayList(Node),
    textContent: ArrayList(NodeString),
    speakerName: AutoHashMap(Node, NodeString),
    choices: AutoHashMap(Node, ArrayList(Node)),
    nextNode: AutoHashMap(Node, Node),
    labels: std.StringHashMap(Node),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        var rv = Self{
            .instances = ArrayList(Node).initCapacity(allocator, 0xffff) catch unreachable,
            .textContent = ArrayList(NodeString).initCapacity(allocator, 0xffff) catch unreachable,
            .speakerName = AutoHashMap(Node, NodeString).init(allocator),
            .choices = AutoHashMap(Node, ArrayList(Node)).init(allocator),
            .nextNode = AutoHashMap(Node, Node).init(allocator),
            .labels = std.StringHashMap(Node).init(allocator),
        };
        _ = rv.newNodeWithContent("@__END_OF_STORY_NULL__", allocator) catch unreachable;
        return rv;
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
        {
            var i: usize = 0;
            while (i < self.textContent.items.len) {
                self.textContent.items[i].deinit();
                i+=1;
            }
            self.textContent.deinit();
        }

        {
            var iter = self.speakerName.iterator();
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
            }
            self.speakerName.deinit();
        }

        {
            var iter = self.choices.iterator();
            var i:usize = 0;
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
                i+=1;
            }
            self.choices.deinit();
        }

        self.nextNode.deinit();
        self.labels.deinit();
    }

    pub fn newNodeWithContent(self: *Self, content: []const u8, alloc: std.mem.Allocator) !Node {
        var newString = try NodeString.fromUtf8(content, alloc);
        try self.textContent.append(newString);
        var rv =  Node{
            .id = self.textContent.items.len - 1,
            .generation = 0, // todo..
        };
        try self.instances.append(rv);
        return rv;
    }

    pub fn setLabel(self: *Self,  id: Node, label: []const u8) !void {
        try self.labels.put(label, id);
    }

    pub fn findNodeByLabel(self: *Self, label: []const u8) ?Node {
        if (self.labels.contains(label)) {
            return self.labels.getEntry(label).?.value_ptr.*;
        }
        else { 
            return null;
        }
    }

    pub fn setLinkByLabel(self: *Self,  id: Node, label: []const u8) !void {
        var next = self.findNodeByLabel(label) orelse return StoryNodesError.InstancesNotExistError;
        try self.nextNode.put(id, next);
    }

    pub fn setLink(self: *Self, from: Node, to: Node) !void {
        try self.nextNode.put(from, to);
    }
    
    pub fn setEnd(self:*Self, node: Node) !void {
        try self.setLink(node, try self.getNodeFromExplicitId(0));
    }

    pub fn getNodeFromExplicitId(self: Self, id: anytype) StoryNodesError!Node {
        if(id < self.instances.items.len) {
            return self.instances.items[id];
        }
        else {
            return StoryNodesError.InstancesNotExistError;
        }
    }

    pub fn addChoicesBySlice(self:*Self, node:Node, choices: []const Node, alloc: std.mem.Allocator) !void
    {
        var value = try self.choices.getOrPut(node);
        value.value_ptr.* = try ArrayList(Node).initCapacity(alloc, choices.len);
        try value.value_ptr.appendSlice(choices);
    }

    pub fn addSpeaker(self: *Self, node: Node, speaker: NodeString ) !void
    {
        try self.speakerName.put(node, speaker);
    }
};

test "init and deinit" 
{
    var x = StoryNodes.init(std.testing.allocator);
    defer x.deinit();
}


const ParserError = error {
    GeneralParserError,
    UnexpectedTokenError
};

pub fn parserPanic(e: ParserError, message: []const u8) !void{
    std.debug.print("Parser Error!: {s}", .{message});
    return e;
}

test "manual simple storyNode" {
    //[hello]
    //$: Hello!
    //$: I'm going to ask you a question.
    //: Do you like cats or dogs?
    //> Cats:
    //    $: Hmm I guess we can't be friends
    //> Dogs:
    //    $: Nice!
    //    Lee: Yeah man they're delicious
    //> Both:
    //    $: Don't be stupid you have to pick one.
    //    @goto hello
    //$: you walk away in disgust
    //@end

    const alloc = std.testing.allocator;
    var story = StoryNodes.init(alloc);
    defer story.deinit();

    // node 0
    var currentNode = try story.newNodeWithContent("Hello!", alloc);
    try story.setLabel(currentNode, "hello");
    var lastNode = currentNode;

    // node 1
    currentNode = try story.newNodeWithContent("I'm going to ask you a question. Do you like cats or dogs?", alloc);
    try story.setLink(lastNode, currentNode);
    lastNode = currentNode;

    const finalNode = try story.newNodeWithContent("You walk away in disgust", alloc);
    try story.setEnd(finalNode);

    // create nodes for responses
    const catNode = try story.newNodeWithContent("Hmm I guess we can't be friends.", alloc);
    try story.setLink(catNode, finalNode);

    // next node
    {
        const choiceNodes: []Node = &.{
            try story.newNodeWithContent("Cats", alloc),
            try story.newNodeWithContent("Dogs", alloc),
            try story.newNodeWithContent("Both", alloc),
        };

        try story.addChoicesBySlice(lastNode, choiceNodes, alloc);

        var node = try story.newNodeWithContent("Don't be stupid you can't pick both!", alloc);
        try story.setLink(choiceNodes[0], catNode);

        node = try story.newNodeWithContent("Yeah man they're delicious!", alloc);
        try story.addSpeaker(node, try NodeString.fromUtf8("Lee", alloc));
        try story.setLink(node, lastNode);
        try story.setLink(choiceNodes[1], node);


        node = try story.newNodeWithContent("Don't be stupid you can't pick both!", alloc);
        try story.setLinkByLabel(node, "hello");
        try story.setLink(choiceNodes[2], node);
    }

}

test "Parse simple" {
    const TokenType = parser.TokenStream.TokenType;
    _ = TokenType;

    var tokStream = try TokenStream.MakeTokens(parser.easySampleData, std.testing.allocator);
    defer tokStream.deinit();

    // tokStream.test_display();
    const ParseState = enum{
        default,
        attributeDefinition,
        funcArgsParse,
    };

    var parseState:ParseState = .default;
    var isParsing = true;
    var story = StoryNodes.init(std.testing.allocator);
    defer story.deinit();

    var currentAttributes = ArrayList(NodeString).init(std.testing.allocator);
    defer currentAttributes.deinit();

    std.debug.print("\n\nStateMachine Pass: > \n", .{});
    var i: usize = 0;
    var tabLevel: usize = 0;
    var lineNumber: usize = 1;
    var newLining: bool = true;
    while(isParsing)
    {
        const tokType = tokStream.token_types.items[i];
        const tokData = tokStream.tokens.items[i];
        _ = tokData;
        var shouldBreak = false;

        if(tokType == TokenType.NEWLINE)
        {
            std.debug.print("newline: ========== <{s}> end of line number: {d} ========== \n", .{@tagName(tokType), lineNumber});
        }
        else if(tokType == TokenType.COMMENT)
        {
            std.debug.print("comment: `{s}`\t<{s}> tab: {d}\n", .{tokData, @tagName(tokType), tabLevel});
        }
        else if(
            tokType == TokenType.R_SQBRACK or 
            tokType == TokenType.R_PAREN or 
            tokType == TokenType.SPACE or
            tokType == TokenType.L_SQBRACK or
            tokType == TokenType.L_PAREN
        )
        {
        }
        else {
            std.debug.print("{s}: `{s}`\t<{s}> tab: {d}\n", .{@tagName(parseState), tokData, @tagName(tokType), tabLevel});
        }

        if(!shouldBreak and newLining and tokType == TokenType.SPACE)
        {
            // do a look ahead and consume values as needed tab level of 4 spaces == 1 tab
            var spaceCount: usize = 0;
            var j: usize = i;
            var seeking = true;
            while(seeking) {
                if(tokStream.token_types.items[j] == TokenType.SPACE)
                {
                    spaceCount = spaceCount + 1;
                    if(spaceCount == 4)
                    {
                        tabLevel += 1;
                        spaceCount = 0;
                    }
                }
                else {
                    seeking = false;
                    break;
                }
                j += 1;
            }
            i = j - 1;
        }
        switch(parseState) {
            .default => {
                if(!shouldBreak and tokType == TokenType.L_SQBRACK)
                {
                    shouldBreak = true;
                    parseState = .attributeDefinition;
                }
                if(!shouldBreak and tokType == TokenType.AT)
                {
                    if(i + 1 >= tokStream.token_types.items.len) 
                        try parserPanic(ParserError.UnexpectedTokenError, "Unexpected end of file");
                    if(tokStream.token_types.items[i + 1] != TokenType.LABEL) // error, expected label after @ 
                        try parserPanic(ParserError.UnexpectedTokenError, "unexpected token");
                    std.debug.print("{s}: `{s}`\t<{s}>  tab: {d}\n", .{@tagName(parseState), tokStream.tokens.items[i+1], @tagName(TokenType.LABEL), tabLevel});
                    if(std.mem.eql(u8, tokStream.tokens.items[i + 1], "goto"))
                    {
                        // todo this creates a link
                        i += 1;
                    }
                    //else if (std.mem.eql(u8, tokStream.tokens[i + 1], "if")){
                    //}
                    else
                    {
                        if(i + 2 >= tokStream.token_types.items.len) unreachable; // we expected arguments but reached end of file
                        {
                            if(tokStream.token_types.items[i + 2] == TokenType.L_PAREN)
                            {
                                shouldBreak = true;
                                parseState = .funcArgsParse;
                                i += 1; // consume the L_Paren
                            }
                        }
                    }
                    i += 1;
                }
            },
            .attributeDefinition => {
                if(!shouldBreak and tokType == TokenType.R_SQBRACK)
                {
                    shouldBreak = true;
                    parseState = .default;
                }
            },
            .funcArgsParse => {
                if(!shouldBreak and tokType == TokenType.R_PAREN)
                {
                    shouldBreak = true;
                    parseState = .default;
                }
            }
        }

        if(tokType == TokenType.NEWLINE)
        {
            tabLevel = 0;
            lineNumber += 1;
            newLining = true;
            shouldBreak = true;
        }
        if(i + 1 >= tokStream.tokens.items.len)
        {
            isParsing = false;
            std.debug.print("endOfFile: ========== <{s}> end of line number: {d} ========== \n", .{ @tagName(tokType), lineNumber});
            continue;
        }
        i += 1;
    }
    // tokStream.test_display();

    _ = story;
    _ = i;
}