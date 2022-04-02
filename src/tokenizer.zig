const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

pub const simplest_v1 =
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
    \\    @end
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
    \\  gold = 50,
    \\  PersonA.isPissedOff = false,
    \\)
    \\
    \\[hello]
    \\# this a seperated comment
    \\@if(PersonA.isPissedOff)
    \\      PersonA: Can you fuck off?
    \\@else
    \\    PersonA: Hello!
    \\        > I hate you
    \\            @set(PersonA.isPissedOff = true)
    \\            PersonA: Well fuck you bud.
    \\        > Hello
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
    \\PersonA: Can you fuck off? # testing comment inline
    \\@else
    \\PersonA: Hello!
    \\    > I hate you:
    \\        @set(PersonA.isPissedOff = true)
    \\        PersonA: Well fuck you bud.
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
        DOUBLE_QUOTE,
        ENUM_COUNT,
        // other token types
        LABEL,
        STORY_TEXT,
        COMMENT,
    };

    tokens: ArrayList([]const u8),
    token_types: ArrayList(TokenType),

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
        self.token_types.deinit();
    }

    pub fn MakeTokens(targetData: []const u8, allocator: std.mem.Allocator) !Self {
        comptime std.debug.assert(@enumToInt(TokenType.ENUM_COUNT) == TokenDefinitions.len);

        const ParserMode = enum {
            default, // parses labels and one-offs
            text,
            comments,
        };

        var isTokenizing = true;
        var finalRun = false;
        var startIndex: usize = 0;
        var length: usize = 1;

        var tokens = ArrayList([]const u8).init(allocator);
        var token_types = ArrayList(TokenType).init(allocator);

        var mode = ParserMode.default;

        var collectingIdentifier = false;

        while (isTokenizing) {
            const slice: []const u8 = targetData[startIndex .. startIndex + length];
            const latestChar = slice[slice.len - 1];

            var shouldBreak = false;
            switch (mode) {
                .default => {
                    if (collectingIdentifier) {
                        if (!(std.ascii.isAlNum(latestChar) or latestChar == '_') or latestChar == '.' or finalRun) {
                            var finalSlice: []const u8 = undefined;
                            if (!finalRun) {
                                finalSlice = slice[0 .. slice.len - 1];
                            } else if (finalRun) {
                                finalSlice = targetData[startIndex..];
                            }
                            try tokens.append(finalSlice);
                            try token_types.append(TokenType.LABEL);
                            startIndex = startIndex + length - 1;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                            collectingIdentifier = false;
                        }
                    }

                    if (!shouldBreak and latestChar == '#') {
                        try tokens.append("#");
                        try token_types.append(TokenType.HASHTAG);
                        startIndex = startIndex + length;
                        length = 0;
                        mode = ParserMode.comments;
                        shouldBreak = true;
                    }

                    if (!shouldBreak and latestChar == ':') {
                        try tokens.append(":");
                        try token_types.append(TokenType.COLON);
                        startIndex = startIndex + length;
                        length = 0;
                        mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    if (!shouldBreak and latestChar == '>') {
                        try tokens.append(">");
                        try token_types.append(TokenType.R_ANGLE);
                        startIndex = startIndex + length;
                        length = 0;
                        mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    inline for (TokenDefinitions) |tok, i| {
                        if (!shouldBreak and std.mem.eql(u8, slice, tok)) {
                            try tokens.append(slice);
                            try token_types.append(@intToEnum(TokenType, i));
                            startIndex = startIndex + length;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                    if (!collectingIdentifier) {
                        if (std.ascii.isAlNum(latestChar) or latestChar == '_') {
                            collectingIdentifier = true;
                            length = 0;
                            shouldBreak = true;
                        }
                    }
                    if (!shouldBreak) {
                        if (!collectingIdentifier) {
                            std.debug.print("\nUnexpected token `{c}`\n>>>>>\n", .{slice});
                            startIndex += 1;
                            length = 0;
                        }
                    }
                },
                .text => {
                    inline for (LeaveTextModeTokens) |tok| {
                        if (!shouldBreak and (std.mem.endsWith(u8, slice, tok) or finalRun)) {
                            var finalSlice: []const u8 = undefined;
                            if (finalRun) {
                                finalSlice = targetData[startIndex..];
                            } else {
                                finalSlice = slice[0 .. slice.len - 1];
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

                            try tokens.append(finalSlice[finalSliceStartIndex .. finalSliceEndIndex + 1]);
                            try token_types.append(TokenType.STORY_TEXT);

                            startIndex = startIndex + length;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                    if (shouldBreak) {
                        if (std.mem.endsWith(u8, slice, "#")) {
                            mode = ParserMode.comments;
                        } else {
                            try tokens.append("\n");
                            try token_types.append(TokenType.NEWLINE);
                        }
                        if (std.mem.endsWith(u8, slice, "\r")) {
                            // std.debug.assert(false, "File is encoded with carraige return. The standard is linefeed (\n) only as the linebreak");
                        }
                    }
                },
                .comments => {
                    inline for (LeaveTextModeTokens) |tok| {
                        if (!shouldBreak and (std.mem.endsWith(u8, slice, tok) or finalRun)) {
                            if (finalRun) {
                                try tokens.append(targetData[startIndex..]);
                            } else {
                                try tokens.append(slice[0 .. slice.len - 1]);
                            }
                            try token_types.append(TokenType.COMMENT);
                            startIndex = startIndex + length - 1;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }
                },
            }

            if (finalRun) {
                isTokenizing = false;
            } else if (startIndex + length == targetData.len) {
                finalRun = true;
                continue;
            }
            length += 1;
        }

        std.debug.assert(tokens.items.len == token_types.items.len);
        return TokenStream{
            .tokens = tokens,
            .token_types = token_types,
        };
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
    defer stream.deinit();

    stream.test_display();
    // skipping the ast stage will make things easier but could possibly make things more difficult later..
    // ehh fuck it.
}
