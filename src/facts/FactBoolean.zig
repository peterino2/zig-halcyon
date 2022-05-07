const std = @import("std");
const Self = @This();

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

pub fn compareEq(self: Self, right: anytype) bool {
    return if (@hasDecl(@TypeOf(right), "asBoolean"))
        std.mem.eql(u8, self.value.items, right.asBoolean().value.items)
    else
        false;
}

pub fn compareNe(self: Self, right: anytype) bool {
    return if (@hasDecl(@TypeOf(right), "asBoolean"))
        std.mem.eql(u8, self.value.items, right.asBoolean().value.items)
    else
        false;
}

pub fn compareLt(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    return self.value < right.asBoolean().value;
}

pub fn compareGt(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    return self.value > right.asBoolean().value;
}

pub fn compareLe(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    return self.value <= right.asBoolean().value;
}

pub fn compareGe(self: Self, right: anytype) bool {
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    return self.value >= right.asBoolean().value;
}

// optional functions
// conversion functions
pub fn asString(self: @This(), alloc: anytype) std.ArrayList(u8) {
    var rv = std.ArrayList(u8).init(alloc);
    if (self.value) {
        rv.appendSlice("true") catch return rv;
    } else {
        rv.appendSlice("false") catch return rv;
    }
    return rv;
}

pub fn asInteger(self: @This(), _: anytype) i64 {
    return if (self.value) return 1 else return 0;
}

pub fn asBoolean(self: @This(), _: anytype) bool {
    return self.value;
}

pub fn asFloat(self: @This(), _: anytype) f64 {
    return if (self.value) return 1.0 else return 0.0;
}
