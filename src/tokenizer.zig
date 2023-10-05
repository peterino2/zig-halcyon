const std = @import("std");
const ArrayList = std.ArrayList;

pub const simplest_v1 =
    \\[hello]
    \\$: Hello! #first comment
    \\[question]
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > (Chun-Li) Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\@end
;

pub const simplest_stress =
    \\[hello]
    \\$: Hello!
    \\[question]
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > this option ends the dialogue:
    \\        @end
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\$: you walk away in disgust
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee: Yeah man they're delicious
    \\    > Both:
    \\        $: Don't be stupid you have to pick one.
    \\        @goto question
    \\$: you walk away in disgust
    \\@end
;

pub const easySampleData =
    \\@vars(
    \\  def gold = 50,
    \\  def PersonA.isPissedOff = false,
    \\)
    \\
    \\[hello]
    \\# this a seperated comment
    \\@if(PersonA.isPissedOff)
    \\     PersonA: Can you flip off? #
    \\@else
    \\    PersonA: Hello!
    \\        > I hate you
    \\            @set(PersonA.isPissedOff = true)
    \\            PersonA: Well flip you bud.
    \\        > s
    \\            @debugPrint("Hello world!") # this is an execution
    \\            @goto hello
    \\        > Have some gold
    \\            $: He takes it from you
    \\            @set(gold -= 50)
    \\            @set(PersonA.isPissedOff = false)
    \\            PersonA: Ugh.. fine.. i am no longer pissed off at you.
;

pub const sampleData =
    \\# this is testing the comments at the start
    \\[hello]
    \\@if(PersonA.isPissedOff)
    \\PersonA: Can you flip off? # testing comment inline
    \\@else
    \\PersonA: Hello!
    \\    > I hate you:
    \\        @set(PersonA.isPissedOff = true)
    \\        PersonA: Well flip you bud.
    \\    > Hello:
    \\        @goto hello
    \\# you can add comments with #
    \\# [talk_to_grace; @once(grace)]
    \\
    \\[talk_to_grace]
    \\$: She's hunched over her meal, barely making any effort to eat.
    \\Grace: Huh?... Oh I'm sorry I didn't quite see you there.
    \\[talk_to_grace_eating]
    \\Grace: I guess I'm a bit distracted
    \\    > Is everything alright? You're hardly eating.
    \\        @end
    \\    > Hear any interesting rumors?
    \\        $: She sheepishly avoids your eye contact and resumes forking through her plate.
    \\        Grace: Sorry... I don't really have any rumors. 
    \\        : I'm just trying to eat here ok? # you can multiline text with ':' this will append it onto the previous line
    \\        # there are no multiline comments.
    \\        @goto talk_to_grace_eating
    \\    @if( p.canParticiate(Dean) and p.party.contains(Dean) )
    \\    > Dean: I can tell whenever a beautiful woman is in distress! Tell me fair lady, what distresses your beautiful heart so?
    \\        @sendEvent(dean leans into grace)
    \\        @goto dean_talk_to_grace
    \\    @if( q.redRoomQuest.undiscoveredPhase.barkeeper_says_grace_knows_something )
    \\    > Word is you know what happened in the red room last thursday.
    \\        $: Her eyes droop sadly. 
    \\        Grace: I- I- don't know what I saw. I can tell you but... it's complicated.
;

const TokenDefinitions: []const []const u8 = &.{
    "==",
    "!=",
    "<=",
    ">=",
    "[",
    "]",
    "@",
    ">",
    ";",
    "(",
    ")",
    ".",
    "$",
    " ",
    "\n",
    "\r",
    "\t",
    "!",
    "=",
    "<",
    "{",
    "}",
    "#",
    "+",
    "-",
    ",",
    ";",
    "&",
    "\"",
};

const LeaveTextModeTokens: []const []const u8 = &.{
    "\n",
    "\n\r", // 1 = r_square_brack
    "#",
    ":",
};

const LeaveCommentModeTokens: []const []const u8 = &.{
    "\n",
    "\n\r", // 1 = r_square_brack
};

pub const TokenType = enum {
    EQUIV,
    NOT_EQUIV,
    LESS_EQ,
    GREATER_EQ,
    L_SQBRACK,
    R_SQBRACK,
    AT,
    R_ANGLE,
    COLON,
    L_PAREN,
    R_PAREN,
    DOT,
    SPEAKERSIGN,
    SPACE,
    NEWLINE,
    CARRIAGE_RETURN,
    TAB,
    EXCLAMATION,
    EQUALS,
    L_ANGLE,
    L_BRACE,
    R_BRACE,
    HASHTAG,
    PLUS,
    MINUS,
    COMMA,
    SEMICOLON,
    AMPERSAND,
    DOUBLE_QUOTE,
    ENUM_COUNT,
    // other token types
    LABEL,
    STORY_TEXT,
    COMMENT,
};

const ParserMode = enum {
    default, // parses labels and one-offs
    text,
    comment,
};

pub const Tokens = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayListUnmanaged([]const u8),
    token_types: std.ArrayListUnmanaged(TokenType),
    meta: std.ArrayListUnmanaged(TokenMeta),

    pub fn deinit(self: *@This()) void {
        self.tokens.deinit(self.allocator);
        self.token_types.deinit(self.allocator);
        self.meta.deinit(self.allocator);
    }

    pub fn test_display(self: @This()) void {
        std.debug.print("tokens added: {d}\n", .{self.tokens.items.len});
        for (self.tokens.items, 0..) |value, i| {
            std.debug.print("{d}: `{s}` {s} {d}:{d}-{d}\n", .{
                i,
                value,
                @tagName(self.token_types.items[i]),
                self.meta.items[i].lineNumber,
                self.meta.items[i].columnStart,
                self.meta.items[i].columnEnd,
            });
        }
    }
};

pub const TokenizerOptions = struct {
    debug: bool = false,
};

const LineFeedType = enum {
    None,
    Unix,
    CRLF,
    EOF,
};

pub const TokenMeta = struct {
    lineNumber: u64 = 0,
    columnStart: u64 = 0,
    columnEnd: u64 = 0,
};

pub const Tokenizer = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayListUnmanaged([]const u8) = .{},
    token_types: std.ArrayListUnmanaged(TokenType) = .{},
    token_meta: std.ArrayListUnmanaged(TokenMeta) = .{},

    isTokenizing: bool = true,
    finalRun: bool = false,
    startIndex: usize = 0,
    length: usize = 0,
    slice: []const u8 = "",
    sliceWithLatest: []const u8 = "",
    source: []const u8,
    latestChar: u8 = 0,
    mode: ParserMode = ParserMode.default,
    shouldBreak: bool = false,
    collectingIdentifier: bool = false,
    line: u64 = 1,
    column: u64 = 1,
    crlf_error_message_emitted: bool = false,

    opts: TokenizerOptions = .{},

    fn getParserModeString(state: ParserMode) []const u8 {
        switch (state) {
            .default => return "default",
            .comment => return "comment",
            .text => return "text",
        }
    }

    fn newline(self: *@This()) void {
        self.line += 1;
        self.column = 1;
    }

    fn matchLineFeed(self: *@This()) LineFeedType {
        var rv: LineFeedType = .None;

        if (self.startIndex + self.length + 1 >= self.source.len) {
            rv = .EOF;
        }

        if (self.latestChar == '\n') {
            rv = .Unix;
        }

        if (self.latestChar == '\r') {
            if (!self.crlf_error_message_emitted) {
                std.debug.print("\nERROR! File is encoded with windows style, carraige return (CRLF '\\r\\n').\n\nWe only intend support UTF-8 with '\\n' as the line ending.\nTo fix this use dos2unix or you can use visual studio code and resave the file. At this time I do not have any support for CRLF\n", .{});
                self.crlf_error_message_emitted = true;
            }
            rv = .CRLF;
        }

        return rv;
    }

    pub fn MakeTokens(targetData: []const u8, allocator: std.mem.Allocator, options: TokenizerOptions) !Tokens {

        // ensure that we have properly created an enum for every single enum
        comptime std.debug.assert(@intFromEnum(TokenType.ENUM_COUNT) == TokenDefinitions.len);

        var self = @This(){
            .allocator = allocator,
            .opts = options,
            .source = targetData,
        };
        errdefer self.tokens.deinit(self.allocator);
        errdefer self.token_types.deinit(self.allocator);
        errdefer self.token_meta.deinit(self.allocator);

        while (self.isTokenizing) {
            if (self.matchLineFeed() == .CRLF) {
                return error.BadLineEndings;
            }

            if (self.matchLineFeed() != .EOF) {
                self.sliceWithLatest = self.source[self.startIndex .. self.startIndex + self.length + 1];
                self.slice = self.source[self.startIndex .. self.startIndex + self.length];
                self.latestChar = self.source[self.startIndex + self.length];
                self.shouldBreak = false;
            } else {
                self.sliceWithLatest = self.source[self.startIndex..];
                self.isTokenizing = false;
            }

            switch (self.mode) {
                .default => {
                    try self.parseSlice_Default();
                },
                .text => {
                    try self.parseSlice_Text();
                },
                .comment => {
                    try self.parseSlice_Comment();
                },
            }

            if (!self.shouldBreak) {
                self.length += 1;
                self.column += 1;
            }
        }

        std.debug.assert(self.tokens.items.len == self.token_types.items.len);

        return .{
            .tokens = self.tokens,
            .token_types = self.token_types,
            .meta = self.token_meta,
            .allocator = allocator,
        };
    }

    fn switchMode(self: *@This(), newMode: ParserMode) !void {
        // cleanup operations for exiting the current mode
        if (self.opts.debug) {
            std.debug.print("switching modes {s}->{s}\n", .{ getParserModeString(self.mode), getParserModeString(newMode) });
        }
        switch (self.mode) {
            .default => {
                if (newMode == .default) {
                    return error.InvalidStateChange_SameState;
                }
            },
            .text => {
                if (newMode == .text) {
                    return error.InvalidStateChange_SameState;
                }
            },
            .comment => {},
        }

        // setup operations for entering the new mode
        switch (newMode) {
            .default => {},
            .text => {},
            .comment => {},
        }

        // speicific mode swithc operations

        self.mode = newMode;
    }

    fn forward(self: *@This(), count: usize) !void {
        self.column += count;
        self.startIndex = self.startIndex + count;
        self.length = 0;
        if (self.startIndex > self.source.len) {
            return error.TokenizerOutOfBoundsError;
        }
    }

    fn advance(self: *@This()) !void {
        if (self.opts.debug and self.length > 0) {
            std.debug.print("advance> [{s}] ", .{getParserModeString(self.mode)});
            std.debug.print("startIndex: {d}, ", .{self.startIndex});
            std.debug.print("length: {d},", .{self.length});
            std.debug.print("slice: `{s}`,\n", .{self.slice});
        }
        self.shouldBreak = true;
        try self.forward(self.length);
    }

    fn pushToken(self: *@This(), token: []const u8, token_type: TokenType, meta: TokenMeta) !void {
        try self.token_types.append(self.allocator, token_type);
        try self.token_meta.append(self.allocator, meta);

        if (token_type == .NEWLINE) {
            try self.tokens.append(self.allocator, "\\n");
            self.newline();
        } else {
            try self.tokens.append(self.allocator, token);
        }
    }

    fn pushAndAdvance(self: *@This(), token_type: TokenType) !void {
        try self.pushToken(self.slice, token_type, self.getTokenMeta());
        try self.advance();
    }

    fn getTokenMetaLatest(self: @This()) TokenMeta {
        return .{
            .lineNumber = self.line,
            .columnStart = self.column + 2 - self.sliceWithLatest.len,
            .columnEnd = self.column + 1,
        };
    }

    fn getTokenMeta(self: @This()) TokenMeta {
        return .{
            .lineNumber = self.line,
            .columnStart = self.column + 1 - self.slice.len,
            .columnEnd = self.column,
        };
    }
    fn getTokenMetaSingle(self: @This()) TokenMeta {
        return .{
            .lineNumber = self.line,
            .columnStart = self.column,
            .columnEnd = self.column,
        };
    }

    fn unexpectedToken(self: *@This(), expected: []const u8) !void {
        std.debug.print("\nUnexpected token `{c}` \n>>>>>>\nWhile Parsing Slice: {s}", .{ self.latestChar, self.slice });
        std.debug.print("{s}\n", .{expected});
        return error.UnexpectedToken;
    }

    // tokenizer behaviour in the default state.
    pub fn parseSlice_Default(self: *@This()) !void {
        if (self.collectingIdentifier) {
            if (!self.shouldBreak and (!(std.ascii.isAlphanumeric(self.latestChar) or self.latestChar == '_') or self.latestChar == '.')) {
                try self.pushAndAdvance(.LABEL);
                self.collectingIdentifier = false;
            }
            if (!self.shouldBreak and (self.matchLineFeed() != .None)) {
                try self.pushToken(self.sliceWithLatest, .LABEL, self.getTokenMetaLatest());
                self.collectingIdentifier = false;
                try self.forward(1);
            }
        }

        if (!self.shouldBreak and self.latestChar == '#') {
            try self.pushToken(self.sliceWithLatest, .HASHTAG, self.getTokenMetaLatest());
            try self.advance();
            try self.forward(1);
            try self.switchMode(.comment);
        }

        if (!self.shouldBreak and self.latestChar == ':') {
            try self.pushAndAdvanceNewest(.COLON);
            try self.switchMode(.text);
        }

        if (!self.shouldBreak and self.latestChar == '>') {
            try self.pushAndAdvanceNewest(.R_ANGLE);
            try self.switchMode(.text);
        }

        inline for (TokenDefinitions, 0..) |tok, i| {
            if (!self.shouldBreak and std.mem.eql(u8, self.sliceWithLatest, tok)) {
                try self.pushToken(self.sliceWithLatest, @as(TokenType, @enumFromInt(i)), self.getTokenMetaLatest());
                try self.advance();
                try self.forward(1);
            }
        }

        if (!self.collectingIdentifier) {
            if (std.ascii.isAlphanumeric(self.latestChar) or self.latestChar == '_') {
                self.collectingIdentifier = true;
                self.shouldBreak = true;
            }
        }

        if (!self.shouldBreak) {
            if (!self.collectingIdentifier) {
                try self.unexpectedToken("Expected an identifier starting with '[A-z0-9]'. or '_'. Or start start of dialogue ':'");
                try self.advance();
            }
        }
    }

    fn pushAndAdvanceText(self: *@This()) !void {
        var textSliceStart: usize = 0;
        while (self.slice[textSliceStart] == ' ' and textSliceStart < self.slice.len - 1) {
            textSliceStart += 1;
        }

        var textSliceEnd: usize = self.slice.len - 1;
        while (self.slice[textSliceEnd] == ' ' and textSliceEnd > 0) {
            textSliceEnd -= 1;
        }

        var strippedTextSlice = self.slice[textSliceStart .. textSliceEnd + 1];

        var meta = self.getTokenMeta();
        meta.columnStart += textSliceStart;
        meta.columnEnd -= textSliceEnd;
        try self.pushToken(strippedTextSlice, .STORY_TEXT, meta);
        try self.advance();
    }

    fn pushAndAdvanceNewest(self: *@This(), token_type: TokenType) !void {
        try self.pushToken(self.sliceWithLatest, token_type, self.getTokenMetaLatest());
        try self.advance();
        try self.forward(1);
    }

    // parser behaviour when we are in the 'text' state
    fn parseSlice_Text(self: *@This()) !void {
        if (self.matchLineFeed() != .None) {
            // strip leading and trailing whitespaces.

            if (self.opts.debug) {
                std.debug.print("line feed detected, switching mode: ", .{});
            }
            try self.pushAndAdvanceText();
            try self.switchMode(.default);
        }

        if (self.latestChar == '#') {
            if (self.opts.debug) {
                std.debug.print("comment detected, switching mode: ", .{});
            }
            try self.pushAndAdvance(.STORY_TEXT);
            try self.pushToken(self.source[self.startIndex .. self.startIndex + 1], .HASHTAG, self.getTokenMetaSingle());
            try self.advance();
            try self.switchMode(.comment);
        }

        if (self.shouldBreak) {
            if (std.mem.endsWith(u8, self.slice, "#")) {
                try self.switchMode(.comment);
                try self.pushToken("#", .HASHTAG, self.getTokenMetaSingle());
            } else if (self.matchLineFeed() != .None) {
                //var tokenMeta = self.getTokenMetaSingle();
                //try self.pushToken("\\n", .NEWLINE, tokenMeta);
            }
        }
    }

    pub fn parseSlice_Comment(self: *@This()) !void {
        if (self.matchLineFeed() != .None and !self.shouldBreak) {
            try self.pushAndAdvance(.COMMENT);
            try self.switchMode(.default);
        }
    }
};

pub fn load_file_alloc(
    filename: []const u8,
    allocator: std.mem.Allocator,
) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, 1, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

test "Tokenizing test" {
    std.debug.print("lmao{any}\n", .{std.ascii.isAlphanumeric('@')});
    var stream = try Tokenizer.MakeTokens(simplest_v1, std.testing.allocator, .{ .debug = true });
    stream.test_display();
    defer stream.deinit();
}

test "errors" {
    var allocator = std.testing.allocator;
    var erroredString = try load_file_alloc("sample_files/windows_line_endings.halc", allocator);
    defer allocator.free(erroredString);

    // Errors should be reported
    std.debug.assert(Tokenizer.MakeTokens(erroredString, allocator, .{}) == error.BadLineEndings);
}

test "garbage" {
    var allocator = std.testing.allocator;
    var garbage = try load_file_alloc("sample_files/garbage.halc", allocator);
    defer allocator.free(garbage);

    // Errors should be reported
    var g = try Tokenizer.MakeTokens(garbage, allocator, .{ .debug = true });
    defer g.deinit();
    g.test_display();
}
