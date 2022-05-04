const std = @import("std");
const facts = @import("values.zig");

value: struct {
    data: std.ArrayList(facts.FactValue),
},

pub fn init(alloc: std.mem.Allocator) @This() {
    return .{ .value = .{ .data = std.ArrayList(facts.FactValue).init(alloc) } };
}

pub fn prettyPrint(self: @This(), _: anytype) void {
    return std.debug.print("array: {any}", .{self.value.data.items});
}

pub fn deinit(self: *@This(), _: anytype) void {
    self.value.data.deinit();
}
