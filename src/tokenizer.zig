const std = @import("std");
const ArrayList = std.ArrayList;

pub const simplest_v1 =
    \\[hello]
    \\$: Hello! #second comment
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
    \\[talk_to_grace; @once(grace)]
    \\    $: She's hunched over her meal, barely making any effort to eat.
    \\    Grace: Huh?... Oh I'm sorry I didn't quite see you there.
    \\    Grace: I guess I'm a bit distracted
    \\    [talk_to_grace_eating]
    \\        > Is everything alright? You're hardly eating.
    \\            @todo
    \\        > Hear any interesting rumors?
    \\            $: She sheepishly avoids your eye contact and resumes forking through her plate.
    \\            Grace: Sorry... I don't really have any rumors. 
    \\            : I'm just trying to eat here ok? # you can multiline text with ':' this will append it onto the previous line
    \\            # there are no multiline comments.
    \\            @goto talk_to_grace_eating
    \\        @if( p.canParticiate(Dean) and p.party.contains(Dean) )
    \\        Dean > I can tell whenever a beautiful woman is in distress! Tell me fair lady, what distresses your beautiful heart so?
    \\            @sendEvent(dean leans into grace)
    \\            @goto dean_talk_to_grace
    \\        @if( q.redRoomQuest.undiscoveredPhase.barkeeper_says_grace_knows_something )
    \\        > Word is you know what happened in the red room last thursday.
    \\            $: Her eyes droop sadly. 
    \\            Grace: I- I- don't know what I saw. I can tell you but... it's complicated.
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
    comments,
};

pub const Tokens = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayListUnmanaged([]const u8),
    token_types: std.ArrayListUnmanaged(TokenType),

    pub fn deinit(self: *@This()) void {
        self.tokens.deinit(self.allocator);
        self.token_types.deinit(self.allocator);
    }

    pub fn test_display(self: @This()) void {
        std.debug.print("tokens added: {d}\n", .{self.tokens.items.len});
        for (self.tokens.items, 0..) |value, i| {
            std.debug.print("{d}: `{s}` {s}\n", .{ i, value, @tagName(self.token_types.items[i]) });
        }
    }
};

pub const TokenizerOptions = struct {
    debug: bool = false,
};

pub const Tokenizer = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayListUnmanaged([]const u8),
    token_types: std.ArrayListUnmanaged(TokenType),

    isTokenizing: bool = true,
    finalRun: bool = false,
    startIndex: usize = 0,
    length: usize = 1,
    slice: []const u8 = "",
    source: []const u8,
    latestChar: u8 = 0,
    mode: ParserMode = ParserMode.default,
    shouldBreak: bool = false,
    collectingIdentifier: bool = false,

    opts: TokenizerOptions = .{},

    fn getStateString(self: @This()) []const u8 {
        switch (self.mode) {
            .default => return "default",
            .comment => return "comment",
            .text => return "text",
        }
    }

    pub fn MakeTokens(targetData: []const u8, allocator: std.mem.Allocator, options: TokenizerOptions) !Tokens {

        // ensure that we have properly created an enum for every single enum
        comptime std.debug.assert(@intFromEnum(TokenType.ENUM_COUNT) == TokenDefinitions.len);

        var self = @This(){
            .allocator = allocator,
            .tokens = .{},
            .token_types = .{},
            .opts = options,
            .source = targetData,
        };

        while (self.isTokenizing) {
            if (self.opts.debug) {
                std.debug.print("[{s}] ", .{self.getStateString()});
                std.debug.print("startIndex: {d}, ", .{self.startIndex});
                std.debug.print("length: {d},", .{self.length});
                std.debug.print("slice: {s},\n", .{self.slice});
            }
            self.slice = self.source[self.startIndex .. self.startIndex + self.length];
            self.latestChar = self.slice[self.slice.len - 1];
            self.shouldBreak = false;

            switch (self.mode) {
                .default => {
                    try self.parseSlice_Default();
                },
                .text => {
                    try self.parseSlice_Text();
                },
                .comments => {
                    try self.parseSlice_Comments();
                },
            }

            if (!self.shouldBreak) {
                self.length += 1;
            }
        }

        std.debug.assert(self.tokens.items.len == self.token_types.items.len);

        return .{
            .tokens = self.tokens,
            .token_types = self.token_types,
            .allocator = allocator,
        };
    }

    fn switchMode(self: *@This(), newMode: ParserMode) !void {
        // cleanup operations for exiting the current mode
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
            .comments => {},
        }

        // setup operations for entering the new mode
        switch (newMode) {
            .default => {},
            .text => {},
            .comments => {},
        }

        // speicific mode swithc operations

        self.mode = newMode;
    }

    fn advance(self: *@This()) !void {
        self.startIndex = self.startIndex + self.length;
        self.length = 1;
        self.shouldBreak = true;
        if (self.startIndex + self.length > self.source.len) {
            return error.TokenizerOutOfBoundsError;
        }
    }

    fn pushToken(self: *@This(), token: []const u8, token_type: TokenType) !void {
        try self.tokens.append(self.allocator, token);
        try self.token_types.append(self.allocator, token_type);
    }

    fn pushAndAdvance(self: *@This(), token_type: TokenType) !void {
        try self.pushToken(self.slice, token_type);
        try self.advance();
    }

    // tokenizer behaviour in the default state.
    pub fn parseSlice_Default(self: *@This()) !void {
        if (self.collectingIdentifier) {
            if (!(std.ascii.isAlphanumeric(self.latestChar) or self.latestChar == '_') or self.latestChar == '.' or self.finalRun) {
                self.pushAndAdvance(.LABEL);
                self.collectingIdentifier = false;
            }
        }

        if (!self.shouldBreak and self.latestChar == '#') {
            self.pushAndAdvance(.HASHTAG);
            self.switchMode(.comments);
        }

        if (!self.shouldBreak and self.latestChar == ':') {
            self.pushAndAdvance(.COLON);
            self.switchMode(.text);
        }

        if (!self.shouldBreak and self.latestChar == '>') {
            try self.tokens.append(self.allocator, ">");
            try self.token_types.append(self.allocator, TokenType.R_ANGLE);
            self.startIndex = self.startIndex + self.length;
            self.length = 0;
            self.shouldBreak = true;
            self.mode = ParserMode.text;
        }

        inline for (TokenDefinitions, 0..) |tok, i| {
            var checkSlice = self.slice;
            if (self.startIndex + tok.len < self.source.len) {
                checkSlice = self.source[self.startIndex .. self.startIndex + tok.len];
            }
            if (!self.shouldBreak and std.mem.eql(u8, checkSlice, tok)) {
                try self.tokens.append(self.allocator, checkSlice);
                try self.token_types.append(self.allocator, @as(TokenType, @enumFromInt(i)));
                self.startIndex = self.startIndex + checkSlice.len;
                self.length = 0;
                self.shouldBreak = true;
                self.mode = ParserMode.default;
            }
        }

        if (!self.collectingIdentifier) {
            if (std.ascii.isAlphanumeric(self.latestChar) or self.latestChar == '_') {
                self.collectingIdentifier = true;
                self.length = 0;
                self.shouldBreak = true;
            }
        }
        if (!self.shouldBreak) {
            if (!self.collectingIdentifier) {
                std.debug.print("\nUnexpected token `{c}`\n>>>>>\n", .{self.slice});
                self.startIndex += 1;
                self.length = 0;
            }
        }
    }

    // parser behaviour when we are in the 'text' state
    fn parseSlice_Text(self: *@This()) !void {
        inline for (LeaveTextModeTokens) |tok| {
            if (!self.shouldBreak and (std.mem.endsWith(u8, self.slice, tok))) {
                var finalSlice: []const u8 = undefined;
                finalSlice = self.slice[0 .. self.slice.len - 1];

                // strip leading and trailing whitespaces.
                var finalSliceStartIndex: usize = 0;
                while (finalSlice[finalSliceStartIndex] == ' ' and finalSliceStartIndex < finalSlice.len - 1) {
                    finalSliceStartIndex += 1;
                }

                var finalSliceEndIndex: usize = finalSlice.len - 1;
                while (finalSlice[finalSliceEndIndex] == ' ' and finalSliceEndIndex > 0) {
                    finalSliceEndIndex -= 1;
                }

                try self.tokens.append(self.allocator, finalSlice[finalSliceStartIndex .. finalSliceEndIndex + 1]);
                try self.token_types.append(self.allocator, TokenType.STORY_TEXT);

                self.startIndex = self.startIndex + self.length;
                self.length = 0;
                self.mode = ParserMode.default;
                self.shouldBreak = true;
            }
        }

        if (self.shouldBreak) {
            if (std.mem.endsWith(u8, self.slice, "#")) {
                self.mode = ParserMode.comments;
                try self.tokens.append(self.allocator, "#");
                try self.token_types.append(self.allocator, TokenType.HASHTAG);
            } else {
                try self.tokens.append(self.allocator, "\n");
                try self.token_types.append(self.allocator, TokenType.NEWLINE);
            }
            if (std.mem.endsWith(u8, self.slice, "\r")) {
                std.debug.print("File is encoded with carraige return. The standard is linefeed (\\n) only as the linebreak. We only support UTF-8 with \\n as the line ending. To fix this use dos2unix or you can use visual studio code and resave the file.\n", .{});
            }
        }
    }

    pub fn parseSlice_Comments(self: *@This()) !void {
        inline for (LeaveTextModeTokens) |tok| {
            if (!self.shouldBreak and (std.mem.endsWith(u8, self.slice, tok))) {
                try self.tokens.append(self.allocator, self.source[self.startIndex..]);
                try self.token_types.append(self.allocator, TokenType.COMMENT);
                self.startIndex = self.startIndex + self.length - 1;
                self.length = 0;
                self.mode = ParserMode.default;
                self.shouldBreak = true;
            }
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
    var stream = try Tokenizer.MakeTokens(easySampleData, std.testing.allocator, .{ .debug = true });
    stream.test_display();
    defer stream.deinit();
}

test "errors" {
    var allocator = std.testing.allocator;
    var erroredString = try load_file_alloc("sample_files/windows_line_endings.halc", allocator);
    defer allocator.free(erroredString);

    // Errors should be reported
    var toks = try Tokenizer.MakeTokens(erroredString, allocator, .{});
    toks.test_display();

    defer toks.deinit();
}
