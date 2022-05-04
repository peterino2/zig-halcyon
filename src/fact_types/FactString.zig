const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

value: ArrayList(u8),

pub fn prettyPrint(self: Self, _: struct {}) void {
    std.debug.print("string: {s}", .{self.value.items});
}

pub fn compareEq(self: Self, right: anytype) bool {
    // return std.mem.eql(u8, self.value.items, right.string.value.items);
    return if (@hasDecl(@TypeOf(right), "asFactString"))
        std.mem.eql(u8, self.value.items, right.asFactString().value.items)
    else
        false;
}

pub fn asFactString(self: @This(), _: anytype) @This() {
    return self;
}

pub fn asInteger() i64 {
    return 0;
}

pub fn asFloat() f64 {
    return 0;
}
