const std = @import("std");

value: i64,

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = 0.0 };
}

pub fn deinit(_: *@This(), _: anytype) void {}
