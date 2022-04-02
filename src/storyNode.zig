const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const tokenizer = @import("tokenizer.zig");
const TokenStream = tokenizer.TokenStream;
const TokenType = tokenizer.TokenStream.TokenType;

pub const storyStartLabel = "@__STORY_START__";
pub const storyEndLabel = "@__STORY_END__";

pub const Node = struct {
    id: usize = 0,
    generation: u32 = 0,
};

pub const LocKey = struct {
    key: u32,
    keyName: ArrayList(u8),

    const Self = @This();

    // generates a new localization id with a random value (todo)
    pub fn newAutoKey(alloc: std.mem.Allocator) !LocKey {
        return LocKey{ .key = 0, .keyName = ArrayList(u8).init(alloc) };
    }

    pub fn deinit(self: *Self) void {
        self.keyName.deinit();
    }
};

pub const NodeString = struct {
    string: ArrayList(u8),
    locKey: LocKey,

    const Self = @This();

    pub fn initAuto(alloc: std.mem.Allocator) Self {
        return NodeString{
            .string = try ArrayList(u8).init(alloc),
            .locKey = LocKey.newAutoKey(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.string.deinit();
        self.locKey.deinit();
    }

    pub fn setUtf8NativeText(self: *Self, text: []const u8) *Self {
        if (self.string.items.len > 0) {
            try self.string.clearAndFree();
        }
        try self.string.appendSlice(text);
        return self;
    }

    pub fn fromUtf8(text: []const u8, alloc: std.mem.Allocator) !NodeString {
        var rv = NodeString{
            .string = try ArrayList(u8).initCapacity(alloc, text.len),
            .locKey = try LocKey.newAutoKey(alloc),
        };

        _ = try rv.string.appendSlice(text);

        return rv;
    }

    // returns the native text
    pub fn asUtf8Native(self: Self) ![]const u8 {
        return self.string.items;
    }
};

pub const NodeStringView = []const u8;

pub const NodeType = enum(u8) {
    Dead, // set to this to effectively mark this node as dead
    Text,
    Response,
};

const StoryNodesError = error{ InstancesNotExistError, GeneralError };

const FactVarTypes = enum {
    BoolType,
    IntType,
    BigIntType,
    StringType,
    GenericType,
    //RefType, todo
    MaxTypesCount,
};
// used to key into the factsDB
const FactVarHandle = struct {
    key: u32,
    // ... todo fill this guy out later theres a lot to do here.
};

const FactVar = union(enum) {
    boolType: bool,
    intType: u32,
    bigIntType: u64,
    stringType: NodeString,
    genericType: struct {
        // todo
    },
};

pub const NodeDirective = union(enum) {
    const Self = @This();
    set: struct {
        varToSet: FactVarHandle,
        newValue: FactVar,
    },
    generic: struct {},

    pub fn fromUtf8Tokens(source: []const []const u8, alloc: std.mem.Allocator) Self {
        // todo actually parse these nodes into directives
        _ = source;
        _ = alloc;
        return Self{ .generic = .{} };
    }
};

const BranchNode = struct {
    // todo
};

const StoryNodes = struct {
    instances: ArrayList(Node),
    textContent: ArrayList(NodeString),
    directives: AutoHashMap(Node, NodeDirective),
    speakerName: AutoHashMap(Node, NodeString),
    conditionalBlock: AutoHashMap(Node, BranchNode),
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
            .directives = AutoHashMap(Node, NodeDirective).init(allocator),
            .conditionalBlock = AutoHashMap(Node, BranchNode).init(allocator),
        };
        var node = rv.newNodeWithContent("@__STORY_END__", allocator) catch unreachable;
        rv.setLabel(node, "@__STORY_END__") catch unreachable;
        return rv;
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
        self.directives.deinit();
        self.conditionalBlock.deinit();
        {
            var i: usize = 0;
            while (i < self.textContent.items.len) {
                self.textContent.items[i].deinit();
                i += 1;
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
            var i: usize = 0;
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
                i += 1;
            }
            self.choices.deinit();
        }

        self.nextNode.deinit();
        self.labels.deinit();
    }

    pub fn newNodeWithContent(self: *Self, content: []const u8, alloc: std.mem.Allocator) !Node {
        var newString = try NodeString.fromUtf8(content, alloc);
        try self.textContent.append(newString);
        var node = Node{
            .id = self.textContent.items.len - 1,
            .generation = 0, // todo..
        };
        try self.instances.append(node);

        if (node.id == 1) {
            try self.setLabel(node, storyStartLabel);
        }
        return node;
    }

    fn newDirectiveNodeFromUtf8(self: *Self, source: []const []const u8, alloc: std.mem.Allocator) !Node {

        // you have access to start and end window here.
        var node = try self.newNodeWithContent("UNKNOWN DIRECTIVE", alloc);
        var directive = NodeDirective.fromUtf8Tokens(source, alloc);
        try self.directives.put(node, directive);

        return node;
    }

    pub fn setTextContentFromSlice(self: *Self, node: Node, newContent: []const u8) !void {
        if (node.id >= self.textContent.items.len) return StoryNodesError.InstancesNotExistError;
        self.textContent.items[node.id].string.clearAndFree();
        try self.textContent.items[node.id].string.appendSlice(newContent);
    }

    pub fn setLabel(self: *Self, id: Node, label: []const u8) !void {
        try self.labels.put(label, id);
    }

    pub fn findNodeByLabel(self: Self, label: []const u8) ?Node {
        if (self.labels.contains(label)) {
            return self.labels.getEntry(label).?.value_ptr.*;
        } else {
            std.debug.print("!! unable to find label {s}", .{label});
            return null;
        }
    }

    pub fn setLinkByLabel(self: *Self, id: Node, label: []const u8) !Node {
        var next = self.findNodeByLabel(label) orelse return StoryNodesError.InstancesNotExistError;
        try self.nextNode.put(id, next);
        return next;
    }

    pub fn setLink(self: *Self, from: Node, to: Node) !void {
        try self.nextNode.put(from, to);
    }

    pub fn setEnd(self: *Self, node: Node) !void {
        try self.setLink(node, try self.getNodeFromExplicitId(0));
    }

    pub fn getNodeFromExplicitId(self: Self, id: anytype) StoryNodesError!Node {
        if (id < self.instances.items.len) {
            return self.instances.items[id];
        } else {
            return StoryNodesError.InstancesNotExistError;
        }
    }

    pub fn addChoicesBySlice(self: *Self, node: Node, choices: []const Node, alloc: std.mem.Allocator) !void {
        var value = try self.choices.getOrPut(node);
        value.value_ptr.* = try ArrayList(Node).initCapacity(alloc, choices.len);
        try value.value_ptr.appendSlice(choices);
    }

    pub fn addSpeaker(self: *Self, node: Node, speaker: NodeString) !void {
        try self.speakerName.put(node, speaker);
    }
};

const ParserError = error{ GeneralParserError, UnexpectedTokenError };

pub fn parserPanic(e: ParserError, message: []const u8) !void {
    std.debug.print("Parser Error!: {s}", .{message});
    return e;
}

// 0xee0201
//     0x03
// add 2 1
// 0xee0201
//
// int main() {
//  printf("hello world");
// }
//
//
//

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
        for (self.history.items) |i| {
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

    pub fn deinit(self: *Self) void {
        self.history.deinit();
    }

    pub fn displayCurrentContent(self: Self) void {
        const str = if (self.story.speakerName.get(self.node)) |speaker| speaker.asUtf8Native() else "narrator";
        std.debug.print("{d}> {s}: {s}\n", .{ self.node.id, str, self.story.textContent.items[self.node.id].asUtf8Native() });
    }

    pub fn iterateChoicesList(self: *Self, iter: []const usize) !void {
        var currentChoiceIndex: usize = 0;
        var story = self.story;

        while (self.node.id > 0) // the zero node is when it is done
        {
            self.displayCurrentContent();
            if (self.isRecording) {
                try self.history.append(self.node);
            }
            if (story.nextNode.contains(self.node)) {
                self.node = story.nextNode.get(self.node).?;
            } else if (story.choices.contains(self.node)) {
                self.node = story.choices.get(self.node).?.items[iter[currentChoiceIndex]];
                currentChoiceIndex += 1;
            }
        }

        if (self.isRecording) {
            try self.history.append(self.node);
        }
    }
};

const ScopeType = enum {
    LinearScope,
    ChoiceScope,
    ConditionalScope,
};

pub const NodeParser = struct {
    const Self = @This();
    const TokenWindow = struct {
        startIndex: usize = 0,
        endIndex: usize = 1,
    };

    const FinishParams = struct {
        shouldLinkToLast: bool = true,
    };


    const ParseScope = struct {
        parentScope: usize,
        tabLevel: usize,
        childScopes: ArrayList(usize),
        firstNodeInScope: Node,
        lastNodeInScope: Node,
        childLeafNodes: ArrayList(Node),
        scopeType: ScopeType = ScopeType.LinearScope,

        pub fn deinit(self: *ParseScope) void {
            self.childScopes.deinit();
            self.childLeafNodes.deinit();
        }
    };

    pub fn MakeScope(
        parentScopeId: usize,
        tabLevel: usize,
        firstNode: Node,
        alloc: std.mem.Allocator,
    ) ParseScope {
        var self = ParseScope{
            .firstNodeInScope = firstNode,
            .lastNodeInScope = firstNode,
            .parentScope = parentScopeId,
            .childScopes = ArrayList(usize).init(alloc),
            .childLeafNodes = ArrayList(Node).init(alloc),
            .tabLevel = tabLevel,
            .scopeType = ScopeType.ChoiceScope,
        };

        return self;
    }

    tokenStream: TokenStream,
    isParsing: bool = true,
    tabLevel: usize = 0,
    newLining: bool = false,
    lineNumber: usize = 1,
    story: StoryNodes,
    currentTokenWindow: TokenWindow = .{},
    currentNodeForChoiceEval: Node = .{},
    lastNode: Node = .{},
    lastLabel: []const u8,
    hasLastLabel: bool = false,
    isNewLining: bool = true,
    currentChoicesTabLevel: usize = 0,
    scopes: ArrayList(ParseScope),
    currentScopeId: usize = 0,

    pub fn pushScope(
        self: *Self,
        scope: ParseScope,
    ) !void {
        // Ids are assigned as position in memory
        try self.scopes.append(scope);
        try self.scopes.items[scope.parentScope].childScopes.append(self.currentScopeId);
        self.currentScopeId = self.scopes.items.len - 1;
    }

    // probably not use this
    pub fn addParallelScope(self: *Self, node: Node, alloc: std.mem.Allocator) !void {
        var currentScope = self.scopes.items[self.currentScopeId];
        var parentScope = currentScope.parentScope;
        try self.pushScope(NodeParser.MakeScope(parentScope, self.tabLevel, node, alloc));
    }

    pub fn backupScope(self: *Self, count: usize) !void {
        _ = self;
        _ = count;
    }

    pub fn finishScope(self: *Self) !void {
        var scope = self.scopes.items[self.currentScopeId];
        // printout first and last nodes for each scope until we get back to parent.
        var parentId = scope.parentScope;
        std.debug.print("Starting new scope collapse closing to parent: {d} currentScopeId {d}\n", .{ parentId, self.currentScopeId });
        for (self.scopes.items[parentId + 1 ..]) |scopeToClose, i| {
            var len = self.scopes.items.len;
            std.debug.print(
                "closing scope parent:{d} scopeId:{d} tablevel:{d}\n",
                .{
                    parentId,
                    len - (i + 1),
                    scopeToClose.tabLevel,
                },
            );

            std.debug.print("tagname: {s}\n", .{@tagName(scopeToClose.scopeType)});
            if (scopeToClose.scopeType == ScopeType.ChoiceScope or scopeToClose.scopeType == ScopeType.ConditionalScope)
            {
                if(scopeToClose.childLeafNodes.items.len > 0)
                {
                    for(scopeToClose.childLeafNodes.items) |leafChild|
                    {
                        try self.scopes.items[parentId].childLeafNodes.append(leafChild);
                    }
                }
                else 
                {
                    try self.scopes.items[parentId].childLeafNodes.append(scopeToClose.lastNodeInScope);
                }
            }
        }
        var i: usize = self.scopes.items.len - 1;
        while (i > parentId) : (i -= 1) {
            var scopeToClose = self.scopes.pop();
            scopeToClose.deinit();
        }
        self.currentScopeId = parentId;
        std.debug.print("currentScopeId {d}\n", .{self.currentScopeId});
    }

    fn startDialogueChoice(self: *Self, alloc: std.mem.Allocator) !void {
        self.currentChoicesTabLevel = self.tabLevel;
        self.currentNodeForChoiceEval = self.lastNode;

        std.debug.print("starting evaluation for {s}\n", .{self.currentNodeForChoiceEval});
        if (!self.story.choices.contains(self.currentNodeForChoiceEval)) {
            try self.story.choices.put(self.currentNodeForChoiceEval, ArrayList(Node).init(alloc));
        }

        if (self.story.choices.getEntry(self.currentNodeForChoiceEval)) |e| {
            e.value_ptr.clearAndFree();
        }
    }

    fn addCurrentDialogueChoiceFromUtf8Content(self: *Self, choiceContent: []const u8, alloc: std.mem.Allocator) !void {
        var node = try self.story.newNodeWithContent(choiceContent, alloc);
        // try self.currentChoices.append(node);

        if (self.story.choices.getEntry(self.currentNodeForChoiceEval)) |e| {
            try e.value_ptr.append(node);
            std.debug.print("{s} ->> {d} has this number of choices: {d}\n", .{ self.currentNodeForChoiceEval, node.id, e.value_ptr.*.items.len });
            try self.finishCreatingNode(node, FinishParams{ .shouldLinkToLast = false });
        }
    }

    fn matchFunctionCallGeneric(slice: []const TokenType, data: anytype, functionName: []const u8) bool {
        if (slice.len < 4) return false;

        if (data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if (!std.mem.eql(u8, data[1], functionName)) return false;

        if (slice[0] == TokenType.AT and
            slice[1] == TokenType.LABEL and
            slice[2] == TokenType.L_PAREN and
            slice[slice.len - 1] == TokenType.R_PAREN)
        {
            return true;
        }

        return false;
    }

    // checks if a sequence of tokens matches the @set(...) directive
    fn tokMatchSet(slice: []const TokenType, data: []const []const u8) bool {
        return matchFunctionCallGeneric(slice, data, "set");
    }

    fn tokMatchEnd(slice: []const TokenType, data: anytype) bool {
        if (slice.len < 2) return false;
        if (slice[0] != TokenType.AT) return false;
        if (slice[1] != TokenType.LABEL) return false;
        if (data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if (!std.mem.eql(u8, data[1], "end")) return false;

        return true;
    }

    fn tokMatchGoto(slice: []const TokenType, data: anytype) bool {
        if (slice.len < 3) return false;
        if (slice[0] != TokenType.AT) return false;
        if (slice[slice.len - 1] != TokenType.LABEL) return false;
        if (data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if (!std.mem.eql(u8, data[1], "goto")) return false;

        return true;
    }

    fn tokMatchIf(slice: []const TokenType, data: anytype) bool {
        return matchFunctionCallGeneric(slice, data, "if");
    }

    fn tokMatchElif(slice: []const TokenType, data: anytype) bool {
        return matchFunctionCallGeneric(slice, data, "elif");
    }

    fn tokMatchVarsBlock(slice: []const TokenType, data: anytype) bool {
        return matchFunctionCallGeneric(slice, data, "vars");
    }

    fn tokMatchElse(slice: []const TokenType, data: anytype) bool {
        if (slice.len < 2) return false;

        if (data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if (!std.mem.eql(u8, data[1], "else")) return false;

        if (slice[0] == TokenType.AT and
            slice[1] == TokenType.LABEL)
        {
            return true;
        }

        return false;
    }

    fn tokMatchGenericDirective(slice: []const TokenType) bool {
        if (slice.len < 4) return false;

        if (slice[0] == TokenType.AT and
            slice[1] == TokenType.LABEL and
            slice[2] == TokenType.L_PAREN and
            slice[slice.len - 1] == TokenType.R_PAREN)
        {
            return true;
        }

        return false;
    }

    fn tokMatchTabSpace(slice: []const TokenType, data: anytype) bool {
        if (slice.len < 4) return false;
        var i: u32 = 0;
        while (i < slice.len) {
            if ((slice[i] != TokenType.SPACE) or (data[i][0] != ' ')) {
                if (i % 4 != 0)
                    std.debug.print("!! inconsistent tabbing, todo. cause some errors here\n", .{});
                return false;
            }
            i += 1;
        }
        return true;
    }

    fn tokMatchDialogueWithSpeaker(slice: []const TokenType) bool {
        if (slice.len < 3) return false;

        if ((slice[0] == TokenType.LABEL or slice[0] == TokenType.SPEAKERSIGN) and
            slice[1] == TokenType.COLON and
            slice[2] == TokenType.STORY_TEXT)
        {
            return true;
        }

        return false;
    }

    fn tokMatchDialogueContinuation(slice: []const TokenType) bool {
        if (slice.len < 2) return false;

        if (slice[0] == TokenType.COLON and
            slice[1] == TokenType.STORY_TEXT)
        {
            return true;
        }

        return false;
    }

    fn tokMatchComment(slice: []const TokenType) bool {
        if (slice.len < 2) return false;

        if (slice[0] == TokenType.HASHTAG and
            slice[1] == TokenType.COMMENT)
        {
            return true;
        }

        return false;
    }

    fn tokMatchLabelDeclare(slice: []const TokenType) bool {
        if (slice.len < 3) return false;

        if (slice[0] == TokenType.L_SQBRACK and
            slice[1] == TokenType.LABEL and
            slice[2] == TokenType.R_SQBRACK)
        {
            return true;
        }

        return false;
    }

    fn tokMatchDialogueChoice(slice: []const TokenType) bool {
        if (slice.len < 2) return false;

        var searchSlice = slice;

        if (searchSlice[0] == TokenType.LABEL) {
            searchSlice = slice[1..];
        }

        if (searchSlice[0] == TokenType.R_ANGLE and searchSlice[searchSlice.len - 1] == TokenType.STORY_TEXT) {
            return true;
        }

        return false;
    }

    fn finishCreatingNode(self: *Self, node: Node, params: FinishParams) !void {
        if (self.lastNode.id > 0 and !self.story.nextNode.contains(self.lastNode)) {
            try self.story.setLink(self.lastNode, node);
        }

        if (self.hasLastLabel and params.shouldLinkToLast) {
            self.hasLastLabel = false;
            try self.story.setLabel(node, self.lastLabel);
        }

        var currentScope = self.scopes.items[self.currentScopeId];
        // scopetabbing here
        if(self.tabLevel)
        {

        }

        self.lastNode = node;
    }

    fn deinit(self: *Self) void {
        // we dont release the storyNodes
        self.tokenStream.deinit();

        var i: usize = 0;
        while (i < self.scopes.items.len) {
            self.scopes.items[i].deinit();
            i += 1;
        }

        self.scopes.deinit();
    }

    pub fn MakeParser(source: []const u8, alloc: std.mem.Allocator) !Self {
        var rv = Self{
            .tokenStream = try TokenStream.MakeTokens(source, alloc),
            .story = StoryNodes.init(alloc),
            .lastLabel = "",
            .hasLastLabel = false,
            .scopes = ArrayList(ParseScope).init(alloc),
        };

        try rv.scopes.append(.{
            .tabLevel = 0,
            .firstNodeInScope = .{},
            .lastNodeInScope = .{},
            .parentScope = 0,
            .childScopes = ArrayList(usize).init(alloc),
            .childLeafNodes = ArrayList(Node).init(alloc),
        });
        return rv;
    }

    pub fn DoParse(source: []const u8, alloc: std.mem.Allocator) !StoryNodes {
        var self = try Self.MakeParser(source, alloc);
        defer self.deinit();

        const tokenTypes = self.tokenStream.token_types;
        const tokenData = self.tokenStream.tokens;

        var nodesCount: u32 = 0;

        std.debug.print("\n", .{});
        while (self.isParsing) {
            const newestTokenIndex = self.currentTokenWindow.endIndex - 1;
            const tokenType = tokenTypes.items[newestTokenIndex];
            _ = tokenType;
            const tokenTypeSlice = tokenTypes.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            const dataSlice = tokenData.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            // std.debug.print("current window: {s} `{s}`\n", .{self.currentTokenWindow, dataSlice});

            var shouldBreak = false;
            // oh man theres a few easy refactorings that can be done here that would midly improve performance.
            if (!shouldBreak and tokMatchSet(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;
                std.debug.print("{d}: Set var\n", .{nodesCount});
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Set var");
                try self.finishCreatingNode(node, .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchGoto(tokenTypeSlice, dataSlice)) {
                std.debug.print("Goto\n", .{});
                std.debug.print("{d} -> ", .{self.lastNode.id});
                if (self.lastNode.id > 0) {
                    var gotoNode = try self.story.setLinkByLabel(self.lastNode, dataSlice[dataSlice.len - 1]);
                    std.debug.print("{d}\n", .{gotoNode});
                } else {
                    return ParserError.GeneralParserError;
                }
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchEnd(tokenTypeSlice, dataSlice)) {
                std.debug.print("end of story\n", .{});
                if (self.lastNode.id > 0) {
                    try self.story.setLink(self.lastNode, self.story.instances.items[0]);
                }
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchIf(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;

                std.debug.print("{d}: If block start\n", .{nodesCount});
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.conditionalBlock.put(node, .{});
                try self.story.setTextContentFromSlice(node, "If block");
                try self.finishCreatingNode(node, .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchElif(tokenTypeSlice, dataSlice)) {
                std.debug.print("If block start\n", .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchElse(tokenTypeSlice, dataSlice)) {
                std.debug.print("else block\n", .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchVarsBlock(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Vars block");
                try self.finishCreatingNode(node, .{});
                std.debug.print("{d}: Vars block\n", .{nodesCount});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchGenericDirective(tokenTypeSlice)) {
                nodesCount += 1;
                std.debug.print("{d}: Generic Directive\n", .{nodesCount});
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Generic Directive");
                try self.finishCreatingNode(node, .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchTabSpace(tokenTypeSlice, dataSlice)) {
                std.debug.print("    ", .{});
                if (self.isNewLining) {
                    self.tabLevel += 1;
                }
                shouldBreak = true;
            }
            // inline space clause
            if (!shouldBreak and tokenTypeSlice[0] == TokenType.SPACE) {
                var i: usize = 0;
                var shouldPushStart: bool = false;
                while (i < tokenTypeSlice.len and i < 4) : (i += 1) {
                    if (tokenTypeSlice[i] != TokenType.SPACE) {
                        shouldPushStart = true;
                        break;
                    }
                }
                if (shouldPushStart) {
                    self.currentTokenWindow.endIndex -= 1;
                    shouldBreak = true;
                }
            }
            if (!shouldBreak and tokMatchLabelDeclare(tokenTypeSlice)) {
                std.debug.print("Label declare\n", .{});
                self.hasLastLabel = true;
                self.lastLabel = dataSlice[1];
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchComment(tokenTypeSlice)) {
                // std.debug.print(" comment (not a real node)\n", .{nodesCount});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueWithSpeaker(tokenTypeSlice)) {
                const node = try self.story.newNodeWithContent(dataSlice[2], alloc);
                nodesCount += 1;

                if (tokenTypeSlice[0] == TokenType.LABEL) {
                    try self.story.addSpeaker(node, try NodeString.fromUtf8(dataSlice[0], alloc));
                }

                try self.finishCreatingNode(node, .{});
                std.debug.print("{d}: story node\n", .{nodesCount});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueContinuation(tokenTypeSlice)) {
                std.debug.print("Continuation of dialogue detected\n", .{});
                try self.story.textContent.items[self.lastNode.id].string.appendSlice(" ");
                try self.story.textContent.items[self.lastNode.id].string.appendSlice(dataSlice[1]);
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueChoice(tokenTypeSlice)) {
                nodesCount += 1;
                std.debug.print("{d}: Choice Node\n", .{nodesCount});
                if (self.currentNodeForChoiceEval.id == 0) {
                    try self.startDialogueChoice(alloc);
                }
                try self.addCurrentDialogueChoiceFromUtf8Content(dataSlice[dataSlice.len - 1], alloc);
                shouldBreak = true;
            }
            if (!shouldBreak and tokenTypeSlice[0] == TokenType.NEWLINE) {
                // nodesCount += 1;
                // std.debug.print("{d}: New Tab Level\n", .{nodesCount});
                self.tabLevel = 0;
                self.newLining = true;
                self.currentTokenWindow.startIndex += 1;
            }
            if (shouldBreak) {
                self.currentTokenWindow.startIndex = self.currentTokenWindow.endIndex;
            }
            if (self.currentTokenWindow.endIndex - self.currentTokenWindow.startIndex > 3 and self.currentTokenWindow.endIndex >= tokenTypes.items.len) {
                std.debug.print("Unexpected end of file, parsing object from <here>, EOF seen <here>", .{});
                return self.story;
            }
            if (self.currentTokenWindow.endIndex == tokenTypes.items.len) {
                break;
            } else {
                self.currentTokenWindow.endIndex += 1;
            }
            if (tokenTypeSlice[0] != TokenType.NEWLINE) {
                self.isNewLining = false;
            }
        }
        return self.story;
    }
};

// ========================= Testing =========================
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
        _ = try story.setLinkByLabel(node, "hello");
        try story.setLink(choiceNodes[2], node);
    }
    return story;
}

test "parse with nodes" {
    var story = try NodeParser.DoParse(tokenizer.easySampleData, std.testing.allocator);
    defer story.deinit();
    // try testChoicesList(story, &.{0,0,0,0}, std.testing.allocator);

    std.debug.print("\n", .{});
    for (story.textContent.items) |content, i| {
        const node = story.instances.items[i];
        std.debug.assert(node.id == i);
        std.debug.print("{d}> {s}\n", .{ i, content.asUtf8Native() });
    }
    std.debug.print("\n", .{});
}

test "parse simplest with no-conditionals" {
    var story = try NodeParser.DoParse(tokenizer.simplest_v1, std.testing.allocator);
    defer story.deinit();
    // try testChoicesList(story, &.{0,0,0,0}, std.testing.allocator);

    std.debug.print("\n", .{});
    for (story.textContent.items) |content, i| {
        if (i == 0) continue;
        const node = story.instances.items[i];
        std.debug.assert(node.id == i);
        if (story.directives.contains(node) or story.conditionalBlock.contains(node)) {
            std.debug.print("{d}> {s}\n", .{ i, content.asUtf8Native() });
        } else {
            if (story.speakerName.get(node)) |speaker| {
                std.debug.print("{d}> STORY_TEXT> {s}: {s}", .{ i, speaker.asUtf8Native(), content.asUtf8Native() });
            } else {
                std.debug.print("{d}> STORY_TEXT> $: {s}", .{ i, content.asUtf8Native() });
            }

            if (story.nextNode.get(node)) |next| {
                std.debug.print(" -> {d}", .{next.id});
            }
        }

        if (story.choices.get(node)) |choices| {
            std.debug.print("\n", .{});
            for (choices.items) |c| {
                std.debug.print("    -> {d}\n", .{c});
            }
        }
        std.debug.print("\n", .{});
    }

    var iter = story.labels.iterator();

    std.debug.print("\nLabels\n", .{});
    while (iter.next()) |instance| {
        std.debug.print("key: {s} -> {d}\n", .{ instance.key_ptr.*, instance.value_ptr.*.id });
    }

    std.debug.print("\n", .{});
}

fn testChoicesList(story: StoryNodes, choicesList: []const usize, alloc: std.mem.Allocator) !void {
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
        try testChoicesList(story, &.{ 2, 2, 1 }, alloc);
    }
}

test "init and deinit" {
    var x = StoryNodes.init(std.testing.allocator);
    defer x.deinit();
}

test "scopetraversals" 
{
    var self = try NodeParser.MakeParser(
        tokenizer.simplest_v1,
        std.testing.allocator,
    );
    defer self.story.deinit();
    defer self.deinit();
    std.debug.print("\n", .{});
    const tabLevels: []const usize = &.{ 0, 1, 1, 1, 0};
    // xx a t=0 
    // 00   > b  t=1
    // 01     c    t=2
    // 02       > 3 t=3
    // 03     d  t=2
    // 04       > e  t=3
    // 05       > h
    // 06     f  t=2 this collapse gives me two
    // 07   > g t=1
    // 08   > h t=1
    // xx i t=0 collapsing here should give me 3 leaf nodes

    const scopeTypes: []const ScopeType = &.{
        ScopeType.LinearScope,
        ScopeType.ChoiceScope,
        ScopeType.ChoiceScope,
        ScopeType.ChoiceScope,
        ScopeType.LinearScope,
    };

    _ = scopeTypes;


    for(tabLevels) |tabLevel, i| {
        if(tabLevel > self.tabLevel)
        {
            if(tabLevel - self.tabLevel > 1)
            {
                std.debug.print("Unexpected indent level, indented too deep\n", .{});
            }
            var node = NodeParser.MakeScope(self.currentScopeId, tabLevel, Node{ .id = i }, std.testing.allocator);
            node.scopeType = scopeTypes[i];
            try self.pushScope( node );
        }
        else if(tabLevel < self.tabLevel)
        {
            var j = self.tabLevel - tabLevel;
            while(j > 0 ) {
                try self.finishScope();
                std.debug.print("number of leaf nodes ( we expect something idk): {d}\n", .{self.scopes.items[self.currentScopeId].childLeafNodes.items.len});
                j -= 1;
            }
        }
        else{
            const currentScope = self.scopes.items[self.currentScopeId];
            var node = NodeParser.MakeScope(currentScope.parentScope, tabLevel, Node{ .id = i }, std.testing.allocator);
            node.scopeType = scopeTypes[i];
            try self.pushScope( node );
        }
        
        self.tabLevel = tabLevel;
    }

    std.debug.print("number of leaf nodes ( we expect something idk): id={d} {d}\n", .{self.currentScopeId, self.scopes.items[self.currentScopeId].childLeafNodes.items.len});
}

test "scopeCrushing" {
    var parser = try NodeParser.MakeParser(
        tokenizer.simplest_v1,
        std.testing.allocator,
    );

    defer parser.story.deinit();
    defer parser.deinit();
    std.debug.print("\n", .{});

    const alloc = std.testing.allocator;
    // 1
    // 2
    //   3
    //     4
    //     5
    //     6
    // 7

    // last finish scope should close these guys
    try parser.pushScope(
        NodeParser.MakeScope(parser.currentScopeId, 1, Node{ .id = 2 }, std.testing.allocator),
    );

    // second finish scope should close these guys
    try parser.pushScope(
        NodeParser.MakeScope(parser.currentScopeId, 2, Node{ .id = 3 }, std.testing.allocator),
    );

    parser.tabLevel = 3;
    // first finish scope should close these guys
    try parser.pushScope(
        NodeParser.MakeScope(parser.currentScopeId, 3, Node{ .id = 4 }, std.testing.allocator),
    );

    try parser.addParallelScope(Node{ .id = 5 }, alloc);
    try parser.addParallelScope(Node{ .id = 6 }, alloc);

    try parser.finishScope();

    // try parser.pushScope(
    //     NodeParser.MakeScope(parser.currentScopeId, 2, Node{ .id = 7 }, std.testing.allocator),
    // );

    try parser.addParallelScope(Node{ .id = 5 }, alloc);
    try parser.addParallelScope(Node{ .id = 6 }, alloc);

    try parser.finishScope();
    try parser.finishScope();

    std.debug.print("current scope id: {d}", .{parser.currentScopeId});
    std.debug.assert(parser.currentScopeId == 0);
    std.debug.assert(parser.scopes.items.len == 1);

    // last finish scope should close these guys
    try parser.pushScope(
        NodeParser.MakeScope(parser.currentScopeId, 1, Node{ .id = 8 }, std.testing.allocator),
    );

    try parser.addParallelScope(Node{ .id = 2 }, alloc);
    try parser.addParallelScope(Node{ .id = 2 }, alloc);

    try parser.finishScope();

    if (!(parser.currentScopeId == 0)) {
        std.debug.print("current scope id: {d}", .{parser.currentScopeId});
    }
    std.debug.assert(parser.currentScopeId == 0);
    std.debug.assert(parser.scopes.items.len == 1);

    std.debug.print("WHOO\n", .{});
}
