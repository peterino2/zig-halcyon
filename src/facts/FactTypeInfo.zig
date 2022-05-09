const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");

const ArrayList = std.ArrayList;
const Initializer = values.Initializer;
const FactValue = values.FactValue;
const BuiltinFactTypes = utils.BuiltinFactTypes;
const MakeLabel = utils.MakeLabel;
const Self = @This();

value: struct {
    name: ArrayList(u8), // string value
    defaultValues: ArrayList(Initializer),
    typeTag: BuiltinFactTypes,
},

// required functions
pub fn prettyPrint(self: Self, _: anytype) void {
    std.debug.print("type {s} {{\n", .{self.value.name.items});
    var i: usize = 0;
    while (i < self.value.defaultValues.items.len) {
        const initializer = self.value.defaultValues.items[i];
        std.debug.print("  {s}: default = ", .{initializer.label.utf8});
        initializer.value.prettyPrint();
        std.debug.print(",\n", .{});
        i += 1;
    }
    std.debug.print("}}", .{});
}

pub fn init(alloc: std.mem.Allocator) Self {
    var rv = Self{
        .value = .{
            .name = ArrayList(u8).init(alloc),
            .defaultValues = ArrayList(Initializer).init(alloc),
            .typeTag = BuiltinFactTypes._BADTYPE,
        },
    };
    return rv;
}

pub fn deinit(self: *Self, _: anytype) void {
    self.value.name.deinit();
    var i: usize = 0;
    while (i < self.value.defaultValues.items.len) {
        self.value.defaultValues.items[i].value.deinit();
        i += 1;
    }
    self.value.defaultValues.deinit();
}

pub fn makeFromTag(tag: BuiltinFactTypes, alloc: std.mem.Allocator) !Self {
    var self = Self{
        .value = .{
            .name = ArrayList(u8).init(alloc),
            .defaultValues = ArrayList(Initializer).init(alloc),
            .typeTag = BuiltinFactTypes._BADTYPE,
        },
    };
    try self.value.name.appendSlice(@tagName(tag));
    return self;
}

pub fn createDefaultTypeInfo(tag: BuiltinFactTypes, alloc: std.mem.Allocator) !Self {
    var typeInfo = try makeFromTag(tag, alloc);

    var i = Initializer{
        .label = MakeLabel(@tagName(tag)),
        .value = FactValue.makeDefault(tag, alloc),
    };

    try typeInfo.value.defaultValues.append(i);
    return typeInfo;
}

test "020-typeInfo-init" {
    // create list of all builtin types
    {
        std.debug.print("\n", .{});
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            var x = try createDefaultTypeInfo(@intToEnum(BuiltinFactTypes, field.value), std.testing.allocator);
            defer x.deinit(.{});
            x.prettyPrint(.{});
            std.debug.print("\n", .{});
        }
    }
}
