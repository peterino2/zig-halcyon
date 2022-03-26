const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const tokenizer = @import("tokenizer.zig");
const TokenStream = tokenizer.TokenStream;
const TokenType = tokenizer.TokenStream.TokenType;

pub const storyStartLabel =  "@__STORY_START__";
pub const storyEndLabel =  "@__STORY_END__";

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
        var node = rv.newNodeWithContent("@__STORY_END__", allocator) catch unreachable;
        rv.setLabel(node, "@__STORY_END__") catch unreachable;
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
        var node =  Node{
            .id = self.textContent.items.len - 1,
            .generation = 0, // todo..
        };
        try self.instances.append(node);

        if(node.id == 1)
        {
            try self.setLabel(node, "@__STORY_START__");
        }
        return node;
    }

    pub fn setLabel(self: *Self,  id: Node, label: []const u8) !void {
        try self.labels.put(label, id);
    }

    pub fn findNodeByLabel(self: Self, label: []const u8) ?Node {
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

    pub fn addChoicesBySlice(self:*Self, node:Node, choices: []const Node, alloc: std.mem.Allocator) !void {
        var value = try self.choices.getOrPut(node);
        value.value_ptr.* = try ArrayList(Node).initCapacity(alloc, choices.len);
        try value.value_ptr.appendSlice(choices);
    }

    pub fn addSpeaker(self: *Self, node: Node, speaker: NodeString ) !void {
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

fn makeSimpleTestStory(alloc: std.mem.Allocator) !StoryNodes {
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

    var story = StoryNodes.init(alloc);

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
        try story.setLink(node, finalNode);
        try story.setLink(choiceNodes[1], node);


        node = try story.newNodeWithContent("Don't be stupid you can't pick both!", alloc);
        try story.setLinkByLabel(node, "hello");
        try story.setLink(choiceNodes[2], node);
    }
    return story;
}

pub const Interactor = struct { 
    story: *const StoryNodes,
    node: Node,
    isRecording: bool,
    history: ArrayList(Node),

    const Self = @This();

    pub fn startRecording(self: *Self) void {
        self.isRecording = true;
    }

    pub fn showHistory(self: Self) void {
        for(self.history.items) |i|
        {
            std.debug.print("{d} ", .{i.id});
        }
        std.debug.print("\n", .{});
    }

    pub fn init(story: *const StoryNodes, alloc: std.mem.Allocator) Interactor {
        return Interactor{
            .story = story,
            .node = story.findNodeByLabel("@__STORY_START__") orelse unreachable,
            .history = ArrayList(Node).init(alloc),
            .isRecording = false,
        };
    }

    pub fn deinit(self: *Self) void
    {
        self.history.deinit();
    }

    pub fn displayCurrentContent(self: Self) void
    {
        const str = if(self.story.speakerName.get(self.node)) |speaker| speaker.asUtf8Native() else "narrator" ;
        std.debug.print("{d}> {s}: {s}\n", .{ self.node.id, str, self.story.textContent.items[self.node.id].asUtf8Native()});
    }

    pub fn iterateChoicesList(self: *Self, iter: []const usize) !void
    {
        var currentChoiceIndex: usize = 0;
        var story = self.story;

        while(self.node.id > 0) // the zero node is when it is done
        {
            self.displayCurrentContent();
            if(self.isRecording) 
            {
                try self.history.append(self.node);
            }

            if(story.nextNode.contains(self.node))
            {
                self.node = story.nextNode.get(self.node).?;
            }
            else if(story.choices.contains(self.node))
            {
                self.node = story.choices.get(self.node).?.items[iter[currentChoiceIndex]];
                currentChoiceIndex += 1;
            }
        }

        if(self.isRecording) 
        {
            try self.history.append(self.node);
        }
    }
};

fn testChoicesList(story: StoryNodes, choicesList: []const usize, alloc:std.mem.Allocator) !void
{
    var interactor = Interactor.init(&story, alloc);
    defer interactor.deinit();
    interactor.startRecording();
    try interactor.iterateChoicesList(choicesList); // path 1
    interactor.showHistory();
}

test "manual simple storyNode" {

    const alloc = std.testing.allocator;
    var story = try makeSimpleTestStory(alloc);
    defer story.deinit();
    {
        std.debug.print("\nPath 1 test -----\n", .{});
        try testChoicesList(story, &.{0}, alloc);
    }
    {
        std.debug.print("\nPath 2 test -----\n", .{});
        try testChoicesList(story, &.{1}, alloc);
    }
    {
        std.debug.print("\nPath 3 test -----\n", .{});
        try testChoicesList(story, &.{2, 2, 1}, alloc);
    }
}

// should be invalid after parser run is complete
pub const ParserRunContext = struct {
    const ParseState = enum {
        default,
        attributeDefinition,
        funcArgsParse
    };
    const Self = @This();

    tokenStream: TokenStream,
    isParsing: bool = true,
    tokenIndex: usize = 0,
    tabLevel: usize = 0,
    newLining: bool = false,
    lineNumber: usize = 1,
    shouldBreak: bool = false,
    parseState: Self.ParseState = .default,
    shouldPrint: bool = false,

    pub fn DoParse(source: []const u8, alloc: std.mem.Allocator, showPrintOut: bool) !StoryNodes {
        var self = Self{
            .tokenStream = try TokenStream.MakeTokens(source, alloc),
            .shouldPrint = showPrintOut
        };
        defer self.deinit();
        while(self.isParsing)
        {
            const tokType = self.tokenStream.token_types.items[self.tokenIndex];
            const tokData = self.tokenStream.tokens.items[self.tokenIndex];
            _ = tokData;
            self.shouldBreak = false;

            if(self.shouldPrint)
            {
                if(tokType == TokenType.NEWLINE)
                {
                    std.debug.print("newline: ========== <{s}> end of line number: {d} ========== \n", .{@tagName(tokType), self.lineNumber});
                }
                else if(tokType == TokenType.COMMENT)
                {
                    std.debug.print("comment: `{s}`\t<{s}> tab: {d}\n", .{tokData, @tagName(tokType), self.tabLevel});
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
                    std.debug.print("{s}: `{s}`\t<{s}> tab: {d}\n", .{@tagName(self.parseState), tokData, @tagName(tokType), self.tabLevel});
                }
            }

            if(!self.shouldBreak and self.newLining and tokType == TokenType.SPACE)
            {
                // do a look ahead and consume values as needed tab level of 4 spaces == 1 tab
                var spaceCount: usize = 0;
                var j: usize = self.tokenIndex;
                var seeking = true;
                while(seeking) {
                    if(self.tokenStream.token_types.items[j] == TokenType.SPACE)
                    {
                        spaceCount = spaceCount + 1;
                        if(spaceCount == 4)
                        {
                            self.tabLevel += 1;
                            spaceCount = 0;
                        }
                    }
                    else {
                        seeking = false;
                        break;
                    }
                    j += 1;
                }
                self.tokenIndex = j - 1;
            }
            switch(self.parseState) {
                .default => {
                    if(!self.shouldBreak and tokType == TokenType.L_SQBRACK)
                    {
                        self.shouldBreak = true;
                        self.parseState = .attributeDefinition;
                    }
                    if(!self.shouldBreak and tokType == TokenType.AT)
                    {
                        if(self.tokenIndex + 1 >= self.tokenStream.token_types.items.len) 
                            try parserPanic(ParserError.UnexpectedTokenError, "Unexpected end of file");
                        if(self.tokenStream.token_types.items[self.tokenIndex + 1] != TokenType.LABEL) // error, expected label after @ 
                            try parserPanic(ParserError.UnexpectedTokenError, "unexpected token");

                        if(self.shouldPrint) 
                            std.debug.print("{s}: `{s}`\t<{s}>  tab: {d}\n", 
                                .{@tagName(self.parseState), self.tokenStream.tokens.items[self.tokenIndex+1], @tagName(TokenType.LABEL), self.tabLevel}
                            );

                        if(std.mem.eql(u8, self.tokenStream.tokens.items[self.tokenIndex + 1], "goto"))
                        {
                            // todo this creates a link
                            self.tokenIndex += 1;
                        }
                        //else if (std.mem.eql(u8, tokStream.tokens[i + 1], "if")){
                        //}
                        else
                        {
                            if(self.tokenIndex + 2 >= self.tokenStream.token_types.items.len) unreachable; // we expected arguments but reached end of file
                            {
                                if(self.tokenStream.token_types.items[self.tokenIndex + 2] == TokenType.L_PAREN)
                                {
                                    self.shouldBreak = true;
                                    self.parseState = .funcArgsParse;
                                    self.tokenIndex += 1; // consume the L_Paren
                                }
                            }
                        }
                        self.tokenIndex += 1;
                    }
                },
                .attributeDefinition => {
                    if(!self.shouldBreak and tokType == TokenType.R_SQBRACK)
                    {
                        self.shouldBreak = true;
                        self.parseState = .default;
                    }
                },
                .funcArgsParse => {
                    if(!self.shouldBreak and tokType == TokenType.R_PAREN)
                    {
                        self.shouldBreak = true;
                        self.parseState = .default;
                    }
                }
            }

            if(tokType == TokenType.NEWLINE)
            {
                self.tabLevel = 0;
                self.lineNumber += 1;
                self.newLining = true;
                self.shouldBreak = true;
            }
            if(self.tokenIndex + 1 >= self.tokenStream.tokens.items.len)
            {
                self.isParsing = false;
                if(self.shouldPrint)
                std.debug.print("endOfFile: <EOF> \n", .{});
                continue;
            }
            self.tokenIndex += 1;
        }

        return StoryNodes.init(alloc);
    }

    fn deinit(self: *Self) void
    {
        self.tokenStream.deinit();
    }
};

test "parse Simple with statemachine"
{
    var story = try ParserRunContext.DoParse(tokenizer.easySampleData, std.testing.allocator, false);
    defer story.deinit();
}
