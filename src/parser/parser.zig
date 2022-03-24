const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const sample_data = 
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
\\ [talk_to_grace; @once(grace)]
\\     $: She's hunched over her meal, barely making any effort to eat.
\\     Grace: Huh?... Oh I'm sorry I didn't quite see you there.
\\     Grace: I guess I'm a bit distracted
\\     [talk_to_grace_eating]
\\         > Is everything alright? You're hardly eating.
\\             @todo
\\         > Hear any interesting rumors?
\\             $: She sheepishly avoids your eye contact and resumes forking through her plate.
\\             Grace: Sorry... I don't really have any rumors. I'm just trying to eat here ok?
\\             @goto talk_to_grace_eating
\\         @if( p.canParticiate(Dean) and p.party.contains(Dean) )
\\         Dean > I can tell whenever a beautiful woman is in distress! Tell me fair lady, what distresses your beautiful heart so?
\\             @sendEvent(dean leans into grace)
\\             @goto dean_talk_to_grace
\\         @if( q.redRoomQuest.undiscoveredPhase.barkeeper_says_grace_knows_something )
\\         > Word is you know what happened in the red room last thursday.
\\             $: Her droop sadly.
\\             Grace: I- I- don't know what I saw. I can tell you but... it's complicated.
\\ [talk_to_grace; @once(grace)]
\\     $: She's hunched over her meal, barely making any effort to eat.
\\     Grace: Huh?... Oh I'm sorry I didn't quite see you there.
\\     Grace: I guess I'm a bit distracted
\\     [talk_to_grace_eating]
\\         > Is everything alright? You're hardly eating.
\\             @todo
\\         > Hear any interesting rumors?
\\             $: She sheepishly avoids your eye contact and resumes forking through her plate.
\\             Grace: Sorry... I don't really have any rumors. I'm just trying to eat here ok?
\\             @goto talk_to_grace_eating
\\         @if( p.canParticiate(Dean) and p.party.contains(Dean) )
\\         Dean > I can tell whenever a beautiful woman is in distress! Tell me fair lady, what distresses your beautiful heart so?
\\             @sendEvent(dean leans into grace)
\\             @goto dean_talk_to_grace
\\         @if( q.redRoomQuest.undiscoveredPhase.barkeeper_says_grace_knows_something )
\\         > Word is you know what happened in the red room last thursday.
\\             $: Her droop sadly.
\\             Grace: I- I- don't know what I saw. I can tell you but... it's complicated.
;

fn sliceEquals(left:anytype, right:anytype) bool {
    if(left.len != right.len)
    {
        return false;
    }
    for(left) |left_val, i| {
        if(left_val !=  right[i]) return false;
    }

    return true;
}

const ParserMode = enum {
    default, // parses labels and one-offs
    text,
    // comments,
};

test "Tokenizing test" {
    var isTokenizing: bool = true;
    var startIndex: usize = 0;
    var length: usize = 1;
    var tokens  = ArrayList([]const u8).init(std.testing.allocator) ;
    defer tokens.deinit();

    var mode : ParserMode = ParserMode.default;
    var target_data: []const u8 = sample_data[0..sample_data.len];
    
    // const tokenList: []const []const u8 = &.{
    //     "[", // 0 = l_square_brack
    //     "]", // 1 = r_square_brack
    //     "@",
    //     ">",
    //     ";",
    //     "(",
    //     ")"
    // };
//
//    const TokenTypes = enum {
//        @"[", // 0 = l_square_brack
//        @"]", // 1 = r_square_brack
//        @"@",
//        @">",
//        @";",
//        @"(",
//        @")",
//        @".",
//        @"$",
//        @"    ",
//        @"\n",
//        @"\r",
//        @"\t",
//        @" ",
//    };

    const TokenDefinitions: []const []const u8 = &.{
        "[", // 0 = l_square_brack
        "]", // 1 = r_square_brack
        "@",
        ">",
        ";",
        "(",
        ")",
        ".",
        "$",
        "    ",
        "\n",
        "\r",
        "\t",
        " ",
    };

    const LeaveTextModeTokens: []const []const u8 = &.{
        "\n",
        "\n\r", // 1 = r_square_brack
    };

    var collectingIdentifier = false;

    while(isTokenizing)
    {
        const slice: []const u8 = target_data[startIndex.. startIndex + length - 1];
        const latestChar = target_data[startIndex + length - 1];
        switch(mode)
        {
            .default => {
                var shouldBreak = false;
                if(collectingIdentifier)
                {
                    if(!(std.ascii.isAlNum(latestChar) or latestChar == '_'))
                    {
                        try tokens.append(slice);
                        startIndex = startIndex + length - 1;
                        length = 1;
                        mode = ParserMode.default;
                        shouldBreak = true;
                        collectingIdentifier = false;
                    }
                }

                if(latestChar == ':')
                {
                    try tokens.append(":");
                    startIndex = startIndex + length;
                    length = 1;
                    mode = ParserMode.text;
                    shouldBreak = true;
                }

                if( latestChar == '>')
                {
                    try tokens.append(">");
                    startIndex = startIndex + length;
                    length = 1;
                    mode = ParserMode.text;
                    shouldBreak = true;
                }

                inline for( TokenDefinitions) |tok| {
                    if(!shouldBreak and std.mem.eql(u8, slice, tok) )
                    {
                        try tokens.append(slice);
                        startIndex = startIndex + length - 1;
                        length = 1;
                        mode = ParserMode.default;
                        shouldBreak = true;
                    }
                }

                if(!shouldBreak)
                {
                    if(std.ascii.isAlNum(latestChar) or latestChar == '_')
                    {
                        collectingIdentifier = true;
                        shouldBreak = true;
                    }
                }

                if(!shouldBreak) {
                    std.debug.print("Unexpected token `{c}`\n", .{latestChar});
                }
            },
            .text => {
                var shouldBreak = false;
                inline for(  LeaveTextModeTokens) |tok| {
                    if(!shouldBreak and std.mem.endsWith(u8, slice, tok) )
                    {
                        try tokens.append(slice);
                        startIndex = startIndex + length;
                        length = 1;
                        mode = ParserMode.default;
                        shouldBreak = true;
                    }
                }

            }
        }

        if(startIndex + length == target_data.len)
        {
            try tokens.append(target_data[startIndex..target_data.len]);
            isTokenizing = false;
        }
        length += 1;
    }

    std.debug.print("tokens added: {d}\n", .{tokens.items.len});
    for(tokens.items) |value, i| {
        std.debug.print("{d}: `{s}`\n", .{i, value});
    }

    std.debug.assert(target_data[0] == '[');
}