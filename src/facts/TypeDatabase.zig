const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const Initializer = values.Initializer;
const FactValue = values.FactValue;
const FactTypeInfo = values.FactTypeInfo;

const BuiltinFactTypes = utils.BuiltinFactTypes;
const MakeLabel = utils.MakeLabel;
const TypeRef = utils.TypeRef;

// next thing to work on:
// type db and type info
//
// what kind of stuff do i want to be able to do with
// type info?
// - instantiate defaults - for pod types
//
// type database operations:
// - create a reference to type
// - deep copy
// - inspect and view all subtypes
// - rich name information
// - is same as another type
// - add fields
// - is builtin or not
// - compare types ( is equal that's about it )
//
// stuff I want from factValues
// - get typeOf from a FactValue

const Self = @This();

types: ArrayList(FactTypeInfo),
typesByLabel: AutoHashMap(u32, TypeRef),

pub fn init(alloc: std.mem.Allocator) !Self {
    var rv = Self{
        .types = ArrayList(FactTypeInfo).init(alloc),
        .typesByLabel = AutoHashMap(u32, TypeRef).init(alloc),
    };

    std.debug.print("\n", .{});
    inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
        if (@intToEnum(BuiltinFactTypes, field.value) == BuiltinFactTypes.userStruct or
            @intToEnum(BuiltinFactTypes, field.value) == BuiltinFactTypes.userEnum)
        {
            continue;
        }

        var typeInfo = try FactTypeInfo.createDefaultTypeInfo(
            @intToEnum(BuiltinFactTypes, field.value),
            std.testing.allocator,
        );

        try rv.types.append(typeInfo);
        typeInfo.prettyPrint(.{});
        std.debug.print("\n", .{});
    }

    return rv;
}

pub fn deinit(self: *Self) void {
    var i: usize = 0;
    while (i < self.types.items.len) {
        self.types.items[i].deinit(.{});
        i += 1;
    }
    self.types.deinit();
    self.typesByLabel.deinit();
}

test "030-TypeDatabase" {
    var db = try Self.init(std.testing.allocator);
    defer db.deinit();
}
