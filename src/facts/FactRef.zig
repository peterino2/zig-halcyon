const std = @import("std");
const utils = @import("factUtils.zig");

value: usize,
typeTag: utils.BuiltinFactTypes,

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = 0.0, .typeTag = utils.BuiltinFactTypes._BADTYPE };
}

pub fn deinit(_: *@This(), _: anytype) void {}
