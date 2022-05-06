const std = @import("std");
const utils = @import("factUtils.zig");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const BuiltinFactTypes = utils.BuiltinFactTypes;
const TypeRef = utils.TypeRef;
const Label = utils.TypeRef;
const MakeLabel = utils.MakeLabel;

pub const Fact_BADTYPE = @import("Fact_BADTYPE.zig");

pub const FactBoolean = @import("FactBoolean.zig");
pub const FactInteger = @import("FactInteger.zig");
pub const FactFloat = @import("FactFloat.zig");
pub const FactTypeRef = TypeRef;
pub const FactRef = @import("FactRef.zig");

pub const FactArray = @import("FactArray.zig");
pub const FactString = @import("FactString.zig");

pub const FactTypeInfo = @import("FactTypeInfo.zig");
pub const FactUserEnum = @import("FactUserEnum.zig");
pub const FactUserStruct = @import("FactUserStruct.zig");

pub const FactValue = union(BuiltinFactTypes) {
    // bad type
    _BADTYPE: Fact_BADTYPE,

    // pod types
    boolean: FactBoolean,
    integer: FactInteger,
    float: FactFloat,
    typeRef: FactTypeRef,
    ref: FactRef,

    // array types
    array: FactArray,
    string: FactString,

    // user type system
    typeInfo: FactTypeInfo,
    userEnum: FactUserEnum,
    userStruct: FactUserStruct,

    // helper functions.
    pub fn fromUtf8(value: []const u8, alloc: std.mem.Allocator) !@This() {
        var f = FactValue{ .string = .{ .value = ArrayList(u8).init(alloc) } };
        try f.string.value.appendSlice(value);
        return f;
    }

    // Required functions
    pub fn prettyPrint(self: @This()) void {
        utils.implement_func_for_tagged_union(self, "prettyPrint", void, .{});
    }
    pub fn compareEq(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareEq", bool, .{ other, alloc });
    }
    pub fn compareNe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareNe", bool, .{ other, alloc });
    }
    pub fn compareLt(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareLt", bool, .{ other, alloc });
    }
    pub fn compareGt(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareGt", bool, .{ other, alloc });
    }
    pub fn compareLe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareLe", bool, .{ other, alloc });
    }
    pub fn compareGe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareGe", bool, .{ other, alloc });
    }

    pub fn makeDefault(tag: BuiltinFactTypes, alloc: std.mem.Allocator) @This() {
        switch (tag) {
            ._BADTYPE => {
                return .{ ._BADTYPE = Fact_BADTYPE.init(alloc) };
            },
            .boolean => {
                return .{ .boolean = FactBoolean.init(alloc) };
            },
            .integer => {
                return .{ .integer = FactInteger.init(alloc) };
            },
            .float => {
                return .{ .float = FactFloat.init(alloc) };
            },
            .typeRef => {
                return .{ .typeRef = TypeRef.init(alloc) };
            },
            .ref => {
                return .{ .ref = FactRef.init(alloc) };
            },
            .array => {
                return .{ .array = FactArray.init(alloc) };
            },
            .string => {
                return .{ .string = FactString.init(alloc) };
            },
            .typeInfo => {
                return .{ .typeInfo = FactTypeInfo.init(alloc) };
            },
            .userEnum => {
                return .{ .userEnum = FactUserEnum.init(alloc) };
            },
            .userStruct => {
                return .{ .userStruct = FactUserStruct.init(alloc) };
            },
        }

        // inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
        //     if (@intToEnum(BuiltinFactTypes, field.value) == tag) {
        //         var f: FactValue = undefined;
        //         @field(f, field.name) = @field(@TypeOf(@field(f, field.name)), "init")(alloc);
        //         return f;
        //     }
        // }

        std.debug.print("ERROR: missing init implementation for {}\n", .{tag});

        unreachable;
    }

    // optional interface functions
    pub fn asFactString(self: @This(), alloc: std.mem.Allocator) ArrayList(u8) {
        return utils.implement_func_for_tagged_union(self, "asFactString", ArrayList(u8), alloc);
    }

    pub fn asFactString_static(self: @This()) ArrayList(u8) {
        return utils.implement_func_for_tagged_union(self, "asFactString_static", ArrayList(u8), .{});
    }

    pub fn doesUnionHave_asFactString_static(self: @This()) bool {
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            if (@intToEnum(BuiltinFactTypes, field.value) == self) {
                if (@hasDecl(@TypeOf(@field(self, field.name)), "asFactString_static")) {
                    return true;
                }
            }
        }
        return false;
    }

    pub fn deinit(self: *@This()) void {
        // _ = self;
        return utils.implement_nonconst_func_for_tagged_union(self, "deinit", void, .{});
    }
};

test "011-validate-all-interfaces" {
    inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
        var testFact = FactValue.makeDefault(@intToEnum(BuiltinFactTypes, field.value), std.testing.allocator);
        defer testFact.deinit();
        std.debug.print("\n", .{});
        testFact.prettyPrint();
        _ = testFact;
    }
    std.debug.print("\n", .{});
}

test "010-testing-new-facts" {
    std.debug.print("\n", .{});
    var x = FactValue{ .boolean = .{ .value = true } };

    var y = try FactValue.fromUtf8("testing", std.testing.allocator);
    defer y.deinit();
    var y2 = try FactValue.fromUtf8("testing", std.testing.allocator);
    defer y2.deinit();

    x.prettyPrint();
    std.debug.print("\n", .{});
    y.prettyPrint();
    std.debug.print("\n", .{});
    std.debug.print("testing: {}\n", .{y.compareEq(y2, std.testing.allocator)});
}
