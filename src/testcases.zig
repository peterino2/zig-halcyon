const std = @import("std");
const dut = @import("storyNode.zig");

pub const simple = struct {
    pub const simple_1 =
        \\$: Hello! #second comment
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const simple_2 =
        \\[label1]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const multiLabel =
        \\[label1]
        \\[label3]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const duplicateLabel =
        \\[label1]
        \\[label1]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const duplicateLabel_differentPlace =
        \\[label1]
        \\$: Hello! #second comment
        \\[label1]
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const set_1: []const []const u8 = &.{
        simple_1,
        simple_2,
        multiLabel,
        duplicateLabel,
        duplicateLabel_differentPlace,
    };
};

    pub const testString =
        \\$: Hello! #second comment
        \\$: Hello back to you.
        \\: do you like cats or dogs?
        \\@set(tesvar, 42)
        \\@testCustomFunc(Extendo my nintendo)
        \\@end
    ;

    pub const biggerStory = 
        \\[start]
        \\@setSpeaker(0 denver_neutral)
        \\Denver: damn... what the hell happened here
        \\Denver: I feel really trapped in this room.
        \\@end
        \\
        \\[salina_talk]
        \\@setSpeaker(1 salina_annoyed)
        \\Salina: Well.. someone's up early
        \\@setSpeaker(0)
        \\Denver: Yeah.. I guess I am.. How are you doing?
        \\@setSpeaker(1)
        \\Salina: Fine.. and No thanks to you,
        \\Salina: Listen. Whatever the hell you do to yourself in the sanctity of your own room. 
        \\: That's up to you.
        \\Salina: But can you PLEASE be quiet about it?
        \\@setSpeaker(0)
        \\Denver: (but.. i didn't even do anything)
        \\@end
    ;


test "directives"
{

    const allocator = std.testing.allocator;
    const DirectiveWrapper = struct {
        name: []const u8 = "wrapper",
        
        pub fn lol(self: *@This(), directiveParams: []const u8) void
        {
            std.debug.print("\n inst:{s} Delegate called! with params: `{s}`", .{self.name, directiveParams});
        }
    };

    var dw = DirectiveWrapper{};

    var parser = try dut.NodeParser.MakeParser(biggerStory, allocator);
    defer parser.deinit();

    try parser.installDirective("setSpeaker", &dw, "lol");

    var story = try parser.parseAll();
    defer story.deinit();

    try dut.explainStory(story);
}

test "simple_1" {
    const alloc = std.testing.allocator;
    var i: usize = 0;
    while (i < simple.set_1.len) : (i += 1) {
        var hasError: bool = false;
        var story = dut.NodeParser.DoParse(simple.set_1[i], alloc) catch |err| switch (err) {
            error.DuplicateLabelWarning => {
                if (i == 4) {
                    hasError = true;
                    return undefined;
                } else return error.DuplicateLabelError;
            },
            else => |narrow| return narrow,
        };

        if (!hasError) {
            try dut.explainStory(story);
        }
        story.deinit();
    }
}
