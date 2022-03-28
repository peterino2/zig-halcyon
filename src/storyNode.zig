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
            try self.setLabel(node, storyStartLabel);
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
            std.debug.print("!! unable to find label {s}", .{label});
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
            .node = story.findNodeByLabel(storyStartLabel) orelse unreachable,
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

pub const ParseNodes = struct {
    const Self= @This();
    const TokenWindow = struct{
        startIndex: usize = 0,
        endIndex: usize = 1,
    };

    tokenStream: TokenStream,
    isParsing: bool = true,
    tabLevel: usize = 0,
    newLining: bool = false,
    lineNumber: usize = 1,
    story: StoryNodes,
    // tokenWindows: ArrayList(TokenWindow), // consumed token terminals get pushed back here
    currentTokenWindow: TokenWindow = .{},

    fn matchFunctionCallGeneric( slice: []const TokenType, data: anytype, functionName: []const u8) bool {
        if(slice.len < 4 ) return false;

        if(data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if(!std.mem.eql(u8, data[1], functionName)) return false;

        if(
           slice[0] == TokenType.AT and
           slice[1] == TokenType.LABEL and 
           slice[2] == TokenType.L_PAREN and
           slice[slice.len - 1] == TokenType.R_PAREN
        ) {
            return true;
        } 

        return false;
    }

    // checks if a sequence of tokens matches the @set(...) directive
    fn tokMatchSet( slice: []const TokenType, data: []const []const u8) bool {
        if(slice.len < 4) return false;
        if(slice[0] != TokenType.AT)  return false;
        if(slice[1] != TokenType.LABEL)  return false;
        if(slice[1] != TokenType.L_PAREN)  return false;
        if(slice[slice.len-1] != TokenType.R_PAREN)  return false;

        if(data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if(!std.mem.eql(u8, data[1], "set")) return false;

        return true;
    }

    fn tokMatchGoto( slice: []const TokenType, data:anytype) bool {
        if(slice.len < 3) return false;
        if(slice[0] != TokenType.AT)  return false;
        if(slice[slice.len - 1] != TokenType.LABEL)  return false;
        if(data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if(!std.mem.eql(u8, data[1], "goto")) return false;

        return true;
    }

    fn tokMatchIf(slice: []const TokenType, data:anytype) bool {
        return matchFunctionCallGeneric(slice, data, "if");
    }

    fn tokMatchElif(slice: []const TokenType, data:anytype) bool {
        return matchFunctionCallGeneric(slice, data, "elif");
    }

    fn tokMatchElse(slice: []const TokenType, data:anytype) bool {
        if(slice.len < 2) return false;

        if(data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if(!std.mem.eql(u8, data[1], "else")) return false;

        if(
           slice[0] == TokenType.AT and
           slice[1] == TokenType.LABEL
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchGenericDirective(slice: []const TokenType) bool {
        if(slice.len < 4 ) return false;

        if(
           slice[0] == TokenType.AT and
           slice[1] == TokenType.LABEL and 
           slice[2] == TokenType.L_PAREN and
           slice[slice.len - 1] == TokenType.R_PAREN
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchTabSpace(slice: []const TokenType, data: anytype) bool {
        if(slice.len < 4) return false;
        var i: u32 = 0;
        while(i < slice.len)
        {
            if((slice[i] != TokenType.SPACE) or (data[i][0] != ' ')) {
                if(i % 4 != 0)
                std.debug.print("!! inconsistent tabbing, todo. cause some errors here\n", .{});
                return false;
            }
            i += 1;
        }
        return true;
    }

    fn tokMatchDialogueWithSpeaker(slice: []const TokenType) bool {
        if(slice.len < 3 ) return false;

        if(
           (slice[0] == TokenType.LABEL or slice[0]== TokenType.SPEAKERSIGN) and
           slice[1] == TokenType.COLON and 
           slice[2] == TokenType.STORY_TEXT
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchDialogueContinuation(slice: []const TokenType) bool {
        if(slice.len < 2 ) return false;

        if(
           slice[0] == TokenType.COLON and 
           slice[1] == TokenType.STORY_TEXT
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchComment(slice: []const TokenType) bool {
        if(slice.len < 2 ) return false;

        if(
           slice[0] == TokenType.HASHTAG and
           slice[1] == TokenType.COMMENT
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchLabelDeclare(slice: []const TokenType) bool {
        if(slice.len < 3 ) return false;

        if(
           slice[0] == TokenType.L_SQBRACK and
           slice[1] == TokenType.LABEL and 
           slice[2] == TokenType.R_SQBRACK
        ) {
            return true;
        } 

        return false;
    }

    fn tokMatchDialogueChoice(slice: []const TokenType) bool {
        if(slice.len < 2 ) return false;

        var searchSlice = slice;

        if(searchSlice[0] == TokenType.LABEL) {
            searchSlice = slice[1..];
        }

        if(searchSlice[0] == TokenType.R_ANGLE and searchSlice[searchSlice.len-1] == TokenType.STORY_TEXT)
        {
            return true;
        }

        return false;
    }

    pub fn DoParse(source: []const u8, alloc:std.mem.Allocator) !StoryNodes {
        var self = Self{
            .tokenStream = try TokenStream.MakeTokens(source, alloc),
            .story = StoryNodes.init(alloc),
        };
        defer self.tokenStream.deinit();
        const tokenTypes = self.tokenStream.token_types;
        const tokenData = self.tokenStream.tokens;

        var nodesCount: u32 = 0;

        std.debug.print("\n", .{});
        while(self.isParsing) {
            const newestTokenIndex = self.currentTokenWindow.endIndex - 1;
            const tokenType = tokenTypes.items[newestTokenIndex];
            _ = tokenType;
            const tokenTypeSlice = tokenTypes.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            const dataSlice = tokenData.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            // std.debug.print("current window: {s} `{s}`\n", .{self.currentTokenWindow, dataSlice});

            var shouldBreak = false;

            if(!shouldBreak and tokMatchSet(tokenTypeSlice, dataSlice)){
                nodesCount += 1;
                std.debug.print("{d}: Set var\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchGoto(tokenTypeSlice, dataSlice)){
                std.debug.print("Goto\n", .{});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchIf(tokenTypeSlice, dataSlice)){
                nodesCount += 1;
                std.debug.print("{d}: If block start\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchElif(tokenTypeSlice, dataSlice)){
                std.debug.print("If block start\n", .{});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchElse(tokenTypeSlice, dataSlice)){
                std.debug.print("else block\n", .{});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchGenericDirective(tokenTypeSlice)){
                nodesCount += 1;
                std.debug.print("{d}: Generic Directive\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchTabSpace(tokenTypeSlice, dataSlice)){
                std.debug.print("    ", .{});
                shouldBreak = true;
            }
            // inline space clause
            if(!shouldBreak and tokenTypeSlice[0] == TokenType.SPACE)
            {
                var i: usize = 0;
                var shouldPushStart: bool = false;
                while(i < tokenTypeSlice.len and i < 4) : (i += 1)
                {
                    if(tokenTypeSlice[i] != TokenType.SPACE)
                    {
                        shouldPushStart = true;
                        break;
                    }
                }
                if(shouldPushStart)
                {
                    self.currentTokenWindow.endIndex -= 1;
                    shouldBreak = true;
                }
            }
            if(!shouldBreak and tokMatchLabelDeclare(tokenTypeSlice)){
                std.debug.print("Label declare\n", .{});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchComment(tokenTypeSlice))
            {
                // std.debug.print(" comment (not a real node)\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchDialogueWithSpeaker(tokenTypeSlice))
            {
                nodesCount += 1;
                std.debug.print("{d}: story node\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchDialogueContinuation(tokenTypeSlice))
            {
                std.debug.print("Continuation of comment detected\n", .{});
                shouldBreak = true;
            }
            if(!shouldBreak and tokMatchDialogueChoice(tokenTypeSlice))
            {
                nodesCount += 1;
                std.debug.print("{d}: Choice Node\n", .{nodesCount});
                shouldBreak = true;
            }
            if(!shouldBreak and tokenTypeSlice[0] == TokenType.NEWLINE){
                // nodesCount += 1;
                // std.debug.print("{d}: New Tab Level\n", .{nodesCount});
                self.currentTokenWindow.startIndex += 1;
            }
            if(shouldBreak)
            {
                self.currentTokenWindow.startIndex = self.currentTokenWindow.endIndex;
            }
            if(self.currentTokenWindow.endIndex - self.currentTokenWindow.startIndex > 3 and self.currentTokenWindow.endIndex >= tokenTypes.items.len){ 
                std.debug.print("Unexpected end of file, parsing object from <here>, EOF seen <here>", .{});
                return self.story; 
            }
            if(self.currentTokenWindow.endIndex == tokenTypes.items.len)
            {
                break;
            }
            else {
                self.currentTokenWindow.endIndex += 1;
            }
        }
        return self.story;
    }
    
    fn deinit(self: *Self) void {
        // we dont release the storyNodes
        self.tokenStream.deinit();
    }
};

test "parse with nodes" 
{
    var story= try ParseNodes.DoParse(tokenizer.easySampleData, std.testing.allocator);
    defer story.deinit();
}