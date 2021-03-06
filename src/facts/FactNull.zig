const std = @import("std");

value: struct {},

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn initWithValue(_: struct {}, _: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn prettyPrint(_: @This(), indentLevel: anytype) void {
    _ = indentLevel;
    return std.debug.print("null", .{});
}

pub fn deinit(_: *@This(), _: anytype) void {}
