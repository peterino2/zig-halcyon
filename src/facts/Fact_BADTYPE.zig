const std = @import("std");

value: struct {},

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn initWithValue(_: struct {}, _: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn prettyPrint(_: @This(), _: anytype) void {
    return std.debug.print("BAD_TYPE", .{});
}

pub fn deinit(_: *@This(), _: anytype) void {}
