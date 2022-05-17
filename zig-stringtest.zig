const std = @import("std");

const Cstr = ?[*:0]const u8;

test "slice creation" {
    var x: Cstr = "What the flip did you just say about me";
    var slice: []const u8 = undefined;
    slice.len = 4;
    slice.ptr = x.?;
    std.debug.print("\n{s}\n", .{slice});
    //std.debug.print("{s}", .{x[0..4]});
}
