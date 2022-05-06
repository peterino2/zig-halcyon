const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

value: ArrayList(u8),

// required functions

pub fn prettyPrint(self: Self, _: struct {}) void {
    std.debug.print("string: {s}", .{self.value.items});
}

// arg 0 is the payload object
// arg 1 is the the allocator
pub fn compareEq(self: Self, args: anytype) bool {
    if (@hasDecl(@TypeOf(args[0]), "doesUnionHave_asFactString_static")) {
        if (args[0].doesUnionHave_asFactString_static()) {
            return std.mem.eql(u8, self.value.items, args[0].asFactString_static().items);
        }
    }
    if (@hasDecl(@TypeOf(args[0]), "asFactString")) {
        var rhs = args[0].asFactString(args[1]);
        defer rhs.deinit();
        return std.mem.eql(u8, self.value.items, rhs.items);
    }
    return false;
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

pub fn asFactString_static(self: @This(), _: anytype) ArrayList(u8) {
    return self.value;
}

pub fn asFactString(self: @This(), alloc: anytype) ArrayList(u8) {
    var rv = ArrayList(u8).init(alloc);
    rv.appendSlice(self.value.items) catch return rv;
    return rv;
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
