const std = @import("std");
const tokenizer = @import("tokenizer.zig");

test "compiler-hello-world" {
    const testSource = "g.hello == true";
    _ = testSource;
    var tokstream = try tokenizer.TokenStream.MakeTokens(testSource, std.testing.allocator);
    defer tokstream.deinit();
    tokstream.test_display();
}
