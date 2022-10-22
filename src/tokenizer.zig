const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const halc = @import("storyNode.zig");
const ParserErrorContext = halc.ParserErrorContext;

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

pub const simplest_with_error =
    \\[hello]
    \\$: Hello! #second comment
    \\[question]
    \\$: I'm going to ask you a question.
    \\: do you like cats or dogs?
    \\    > Cats:
    \\        $: Hmm I guess we can't be friends
    \\    > Dogs:
    \\        $: Nice!
    \\        Lee:::: Yeah man they're delicious
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

pub const TokenStream = struct {
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

    tokens: ArrayList([]const u8),
    token_types: ArrayList(Self.TokenType),
    isTokenizing: bool = true,
    finalRun: bool = false,
    startIndex: usize = 0,
    length: usize = 1,
    slice: []const u8 = "",
    source: []const u8,
    latestChar: u8 = 0,
    mode: ParserMode = ParserMode.default,
    fileName: []const u8 = "no_file",
    errorCtx: ?*ParserErrorContext = null,
    lineNumber: usize = 1,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
        self.token_types.deinit();
    }

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        var self = Self{
            .tokens = ArrayList([]const u8).init(allocator),
            .token_types = ArrayList(TokenType).init(allocator),
            .source = undefined,
            .allocator = allocator,
        };

        return self;
    }

    pub fn setTokenizationSources(self: *@This(), fileName:[]const u8, source: []const u8 ) void
    {
        self.fileName = fileName;
        self.source = source;
    }

    pub fn MakeTokens(targetData: []const u8, allocator: std.mem.Allocator) !Self {
        comptime std.debug.assert(@enumToInt(TokenType.ENUM_COUNT) == TokenDefinitions.len);

        var self = Self{
            .tokens = ArrayList([]const u8).init(allocator),
            .token_types = ArrayList(TokenType).init(allocator),
            .source = targetData,
            .allocator = allocator,
        };
        try self.doTokenize();
        return self;
    }

    pub fn doTokenize(self: *@This()) !void {

        var collectingIdentifier = false;

        while (self.isTokenizing) {
            self.slice = self.source[self.startIndex .. self.startIndex + self.length];
            self.latestChar = self.slice[self.slice.len - 1];

            var shouldBreak = false;
            switch (self.mode) {
                .default => {
                    if (collectingIdentifier) {
                        if (!(std.ascii.isAlNum(self.latestChar) or self.latestChar == '_') or self.latestChar == '.' or self.finalRun) {
                            var finalSlice: []const u8 = undefined;
                            if (!self.finalRun) {
                                finalSlice = self.slice[0 .. self.slice.len - 1];
                            } else if (self.finalRun) {
                                finalSlice = self.source[self.startIndex..];
                            }
                            try self.tokens.append(finalSlice);
                            try self.token_types.append(TokenType.LABEL);
                            self.startIndex = self.startIndex + self.length - 1;
                            self.length = 0;
                            self.mode = ParserMode.default;
                            shouldBreak = true;
                            collectingIdentifier = false;
                        }
                    }

                    if (!shouldBreak and self.latestChar == '#') {
                        try self.tokens.append("#");
                        try self.token_types.append(TokenType.HASHTAG);
                        self.startIndex = self.startIndex + self.length;
                        self.length = 0;
                        self.mode = ParserMode.comments;
                        shouldBreak = true;
                    }

                    if (!shouldBreak and self.latestChar == ':') {
                        try self.tokens.append(":");
                        try self.token_types.append(TokenType.COLON);
                        self.startIndex = self.startIndex + self.length;
                        self.length = 0;
                        self.mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    if (!shouldBreak and self.latestChar == '>') {
                        try self.tokens.append(">");
                        try self.token_types.append(TokenType.R_ANGLE);
                        self.startIndex = self.startIndex + self.length;
                        self.length = 0;
                        self.mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    inline for (TokenDefinitions) |tok, i| {
                        var checkSlice = self.slice;
                        if (self.startIndex + tok.len < self.source.len) {
                            checkSlice = self.source[self.startIndex .. self.startIndex + tok.len];
                        }
                        if (!shouldBreak and std.mem.eql(u8, checkSlice, tok)) {
                            try self.tokens.append(checkSlice);
                            try self.token_types.append(@intToEnum(TokenType, i));
                            self.startIndex = self.startIndex + checkSlice.len;
                            self.length = 0;
                            self.mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                    if (!collectingIdentifier) {
                        if (std.ascii.isAlNum(self.latestChar) or self.latestChar == '_') {
                            collectingIdentifier = true;
                            self.length = 0;
                            shouldBreak = true;
                        }
                    }
                    if (!shouldBreak) {
                        if (!collectingIdentifier) {
                            try self.pushError("\nUnexpected token `{c}`\n>>>>>\n", .{self.slice});
                            self.startIndex += 1;
                            self.length = 0;
                        }
                    }
                },
                .text => {
                    inline for (LeaveTextModeTokens) |tok| {
                        if (!shouldBreak and (std.mem.endsWith(u8, self.slice, tok) or self.finalRun)) {
                            var finalSlice: []const u8 = undefined;
                            if (self.finalRun) {
                                finalSlice = self.source[self.startIndex..];
                            } else {
                                finalSlice = self.slice[0 .. self.slice.len - 1];
                            }

                            if(finalSlice.len == 0)
                            {
                                try self.pushError("Really messed up slice, scope was probably closed too early {any}", .{finalSlice});
                                return;
                            }

                            // strip leading and trailing whitespaces.
                            var finalSliceStartIndex: usize = 0;
                            while (finalSlice[finalSliceStartIndex] == ' ' and finalSliceStartIndex < finalSlice.len - 1) {
                                finalSliceStartIndex += 1;
                            }

                            var finalSliceEndIndex: usize = finalSlice.len - 1;
                            while (finalSlice[finalSliceEndIndex] == ' ' and finalSliceEndIndex > 0) {
                                finalSliceEndIndex -= 1;
                            }

                            try self.tokens.append(finalSlice[finalSliceStartIndex .. finalSliceEndIndex + 1]);
                            try self.token_types.append(TokenType.STORY_TEXT);

                            self.startIndex = self.startIndex + self.length;
                            self.length = 0;
                            self.mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                    if (shouldBreak) {
                        if (std.mem.endsWith(u8, self.slice, "#")) {
                            self.mode = ParserMode.comments;
                            try self.tokens.append("#");
                            try self.token_types.append(TokenType.HASHTAG);
                        } else {
                            try self.tokens.append("\n");
                            try self.token_types.append(TokenType.NEWLINE);
                            self.lineNumber += 1;
                        }
                        if (std.mem.endsWith(u8, self.slice, "\r")) {
                            try self.pushError("File is encoded with carraige return. Use the linefeed (\n) only as the linebreak.", .{});
                        }
                    }
                },
                .comments => {
                    inline for (LeaveTextModeTokens) |tok| {
                        if (!shouldBreak and (std.mem.endsWith(u8, self.slice, tok) or self.finalRun)) {
                            if (self.finalRun) {
                                try self.tokens.append(self.source[self.startIndex..]);
                            } else {
                                try self.tokens.append(self.slice[0 .. self.slice.len - 1]);
                            }
                            try self.token_types.append(TokenType.COMMENT);
                            self.startIndex = self.startIndex + self.length - 1;
                            self.length = 0;
                            self.mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }
                },
            }

            if (self.finalRun) {
                self.isTokenizing = false;
            } else if (self.startIndex + self.length == self.source.len) {
                self.finalRun = true;
                continue;
            }
            self.length += 1;
        }

        std.debug.assert(self.tokens.items.len == self.token_types.items.len);
    }

    pub fn pushError(self: *@This(),
        comptime fmt: []const u8, 
        args: anytype,
    ) !void
    {
        std.debug.print(fmt, args);
        var info = halc.ParserWarningOrErrorInfo {
            .errorType = .TokenzationError,
            .fileName = self.fileName,
            .lineNumber = self.lineNumber,
            .sourceCharWindow = .{
                .start = self.startIndex,
                .end = self.length,
            },
            .msg = null,
        };

        if(self.errorCtx) |ctx|
        {
            info.msg = try std.fmt.allocPrint(ctx.allocator, fmt, args);
            try ctx.pushError(info);
        }
        else 
        {
            std.debug.print("\n", .{});
            info.msg = try std.fmt.allocPrint(self.allocator, fmt, args);
        }

        var s = info.allocPrettyPrint(self.allocator, self.source);
        defer self.allocator.free(s);
        std.debug.print("\ninfo >>>\n{s}\n", .{s});

        if(self.errorCtx == null)
        {
            self.allocator.free(info.msg.?);
        }
    }

    pub fn test_display(self: Self) void {
        std.debug.print("tokens added: {d}\n", .{self.tokens.items.len});
        for (self.tokens.items) |value, i| {
            std.debug.print("{d}: `{s}` {s}\n", .{ i, value, @tagName(self.token_types.items[i]) });
        }
    }
};

test "Tokenizing test" {
    var stream = try TokenStream.MakeTokens(easySampleData, std.testing.allocator);
    // stream.test_display();
    defer stream.deinit();

    // skipping the ast stage will make things easier but could possibly make things more difficult later..
}

test "error-context" {
    var allocator = std.testing.allocator;
    var ctx = halc.ParserErrorContext.init(allocator);
    defer ctx.deinit();

    var stream = TokenStream.init(allocator);
    defer stream.deinit();

    stream.setTokenizationSources("testing", simplest_with_error);
    stream.errorCtx = &ctx;
    try stream.doTokenize();

    for(ctx.messages.items) |msg|
    {
        var s = msg.allocPrettyPrint(allocator, simplest_with_error);
        defer allocator.free(s);
        std.debug.print("{s}\n",.{s});
    }
}
