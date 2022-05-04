const std = @import("std");

// all types must implement a value member,
// and all the functions in this interface

value: bool,

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = false };
}

pub fn deinit(_: @This(), _: anytype) void {}

// optional functions
pub fn asInteger(self: @This(), _: anytype) i64 {
    return if (self.value) return 1 else return 0;
}
