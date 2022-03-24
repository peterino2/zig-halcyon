const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

pub const easySampleData = 
    \\[hello]
    \\@if(PersonA.isPissedOff)
    \\PersonA: Can you fuck off?
    \\@else
    \\PersonA: Hello!
    \\    > I hate you:
    \\        @setVar(PersonA.isPissedOff = true)
    \\        PersonA: Well fuck you bud.
    \\    > Hello:
    \\        @goto hello
;

pub const sampleData = 
    \\[hello]
    \\@if(PersonA.isPissedOff)
    \\PersonA: Can you fuck off?
    \\@else
    \\PersonA: Hello!
    \\    > I hate you:
    \\        @setVar(PersonA.isPissedOff = true)
    \\        PersonA: Well fuck you bud.
    \\    > Hello:
    \\        @goto hello
    \\
    \\[talk_to_grace; @once(grace)]
    \\    $: She's hunched over her meal, barely making any effort to eat.
    \\    Grace: Huh?... Oh I'm sorry I didn't quite see you there.
    \\    Grace: I guess I'm a bit distracted
    \\    [talk_to_grace_eating]
    \\        > Is everything alright? You're hardly eating.
    \\            @todo
    \\        > Hear any interesting rumors?
    \\            $: She sheepishly avoids your eye contact and resumes forking through her plate.
    \\            Grace: Sorry... I don't really have any rumors. I'm just trying to eat here ok?
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

pub const TokenStream = struct{
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
    };

    const LeaveTextModeTokens: []const []const u8 = &.{
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
        ENUM_COUNT,
        // other token types
        LABEL,
        STORY_TEXT,
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
            // comments,
        };

        var isTokenizing = true;
        var finalRun = false;
        var startIndex: usize = 0;
        var length: usize = 1;

        var tokens = ArrayList([]const u8).init(allocator);
        var token_types = ArrayList(TokenType).init(allocator);

        var mode = ParserMode.default;


        var collectingIdentifier = false;

        while(isTokenizing)
        {
            const slice: []const u8 = targetData[startIndex.. startIndex + length - 1];
            const latestChar = targetData[startIndex + length - 1];
            switch(mode)
            {
                .default => {
                    var shouldBreak = false;
                    if(collectingIdentifier)
                    {
                        if(!(std.ascii.isAlNum(latestChar) or latestChar == '_') or latestChar == '.' or finalRun )
                        {
                            try tokens.append(slice);
                            try token_types.append(TokenType.LABEL);
                            startIndex = startIndex + length - 1;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                            collectingIdentifier = false;
                        }
                    }

                    if(latestChar == ':')
                    {
                        try tokens.append(":");
                        try token_types.append(TokenType.COLON);
                        startIndex = startIndex + length;
                        length = 0;
                        mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    if( latestChar == '>')
                    {
                        try tokens.append(">");
                        try token_types.append(TokenType.R_ANGLE);
                        startIndex = startIndex + length;
                        length = 0;
                        mode = ParserMode.text;
                        shouldBreak = true;
                    }

                    inline for( TokenDefinitions) |tok, i| {
                        if(!shouldBreak and std.mem.eql(u8, slice, tok) )
                        {
                            try tokens.append(slice);
                            try token_types.append(@intToEnum(TokenType, i));
                            startIndex = startIndex + length - 1;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                    if(!shouldBreak and !collectingIdentifier)
                    {
                        if(std.ascii.isAlNum(latestChar) or latestChar == '_')
                        {
                            collectingIdentifier = true;
                            length = 0;
                            shouldBreak = true;
                        }
                    }

                    if(!shouldBreak) {
                        //.std.debug.print("Unexpected token `{c}`\nlmao>>>\n`{s}`\n========\n", .{slice, targetData[0..startIndex]});
                    }
                },
                .text => {
                    var shouldBreak = false;
                    inline for(LeaveTextModeTokens) |tok| {
                        if(!shouldBreak and (std.mem.endsWith(u8, slice, tok) or finalRun ))
                        {
                            if(finalRun)
                            {

                                try tokens.append(targetData[startIndex..]);
                            }
                            else {
                                try tokens.append(slice[0..slice.len - 1]);
                            }
                            try token_types.append(TokenType.STORY_TEXT);
                            startIndex = startIndex + length;
                            length = 0;
                            mode = ParserMode.default;
                            shouldBreak = true;
                        }
                    }

                }
            }

            if(finalRun)
            {
                isTokenizing = false;
            }
            else if(startIndex + length == targetData.len)
            {
                finalRun = true;
                continue;
            }
            length += 1;
        }

        std.debug.assert(tokens.items.len == token_types.items.len);
        return TokenStream{.tokens = tokens, .token_types = token_types,};
    }

    pub fn test_display(self: Self) void {
        std.debug.print("tokens added: {d}\n", .{self.tokens.items.len});
        for(self.tokens.items) |value, i| {
            std.debug.print("{d}: `{s}` {s}\n", .{i, value, @tagName(self.token_types.items[i])});
        }
    }
};


test "Tokenizing test" {
    var stream = try TokenStream.MakeTokens(sampleData, std.testing.allocator);
    defer stream.deinit();

    // skipping the ast stage will make things easier but could possibly make things more difficult later..
    // ehh fuck it.
}
