const std = @import("std");
const facts = @import("values.zig");

// this one is very much still in development
value: struct {
    data: std.ArrayList(facts.FactValue),
},

pub fn init(alloc: std.mem.Allocator) @This() {
    return .{ .value = .{ .data = std.ArrayList(facts.FactValue).init(alloc) } };
}

pub fn initWithValue(utf8: []const u8, alloc: std.mem.Allocator) @This() {
    var rv = .{ .value = .{ .data = std.ArrayList(facts.FactValue).init(alloc) } };
    rv.value.data.appendSlice(utf8) catch return;
    return rv;
}

pub fn prettyPrint(self: @This(), _: anytype) void {
    return std.debug.print("array: {any}", .{self.value.data.items});
}

pub fn deinit(self: *@This(), _: anytype) void {
    self.value.data.deinit();
}

// functions specific to FactArray
