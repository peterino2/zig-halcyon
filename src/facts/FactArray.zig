const std = @import("std");
const facts = @import("values.zig");

// this one is very much still in development
value: struct {},

pub fn init(alloc: std.mem.Allocator) @This() {
    _ = alloc;
    return .{ .value = .{} };
}

pub fn initWithValue(_: []const u8, _: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn allocPrint(self: @This(), allocator: std.mem.Allocator) ![]const u8 {
    _ = self;
    _ = allocator;
    return "";
}

pub fn prettyPrint(self: @This(), _: anytype) void {
    _ = self;
    return std.debug.print("array: {{ }}", .{});
}

pub fn deinit(self: *@This(), _: anytype) void {
    _ = self;
}

// functions specific to FactArray
