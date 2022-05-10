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
// - instantiate defaults - for pod types - done
// - is builtin or not - done
// - add fields - don
//
// type database operations:
// - add types
// - create a reference to type
// - deep copy
// - inspect and view all subtypes
// - rich name information
// - is same as another type
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
        typeInfo.prettyPrint(.{});
        try rv.addType(typeInfo);
        std.debug.print("\n", .{});
    }

    return rv;
}

pub fn addType(self: *Self, typeInfo: FactTypeInfo) !void {
    const label = typeInfo.getLabel();
    if (self.typesByLabel.contains(label.hash)) {
        std.debug.print("[Error]: trying to add type of hash {s}", .{label.utf8});
        return;
    }

    var typeRef = TypeRef{ .id = label.hash };

    try self.typesByLabel.put(label.hash, typeRef);
    try self.types.append(typeInfo);
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
