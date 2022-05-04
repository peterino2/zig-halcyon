const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

value: ArrayList(u8),

// required functions

pub fn prettyPrint(self: Self, _: struct {}) void {
    std.debug.print("string: {s}", .{self.value.items});
}

pub fn compareEq(self: Self, right: anytype) bool {
    return if (@hasDecl(@TypeOf(right), "asFactString"))
        std.mem.eql(u8, self.value.items, right.asFactString().value.items)
    else
        false;
}

pub fn compareNe(self: Self, right: anytype) bool {
    return if (@hasDecl(@TypeOf(right), "asFactString"))
        std.mem.eql(u8, self.value.items, right.asFactString().value.items)
    else
        false;
}

pub fn compareLt(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asFactString")) return false;
    return self.value.items.len < right.asFactString().value.len;
}

pub fn compareGt(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asFactString")) return false;
    return self.value.items.len > right.asFactString().value.len;
}

pub fn compareLe(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asFactString")) return false;
    return self.value.items.len <= right.asFactString().value.len;
}

pub fn compareGe(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asFactString")) return false;
    return self.value.items.len >= right.asFactString().value.len;
}

pub fn asFactString(self: @This(), _: anytype) @This() {
    return self;
}

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .value = ArrayList(u8).init(allocator) };
}

pub fn deinit(self: Self, _: anytype) void {
    self.value.deinit();
}

// optional functions
pub fn asInteger(self: @This(), _: anytype) i64 {
    return std.fmt.parseInt(i64, self.value, 0) catch return 0;
}

pub fn asFloat(self: @This(), _: anytype) f64 {
    return std.fmt.parseFloat(f64, self.value.items) catch return 0.0;
}
