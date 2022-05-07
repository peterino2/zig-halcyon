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
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            if (@intToEnum(BuiltinFactTypes, field.value) == tag) {
                var x: @This() = undefined;
                _ = x;
                var f = @unionInit(@This(), field.name, @field(@TypeOf(@field(x, field.name)), "init")(alloc));
                return f;
            }
        }

        std.debug.print("ERROR: missing init implementation for {}\n", .{tag});

        unreachable;
    }

    // optional interface functions
    pub fn asString(self: @This(), alloc: std.mem.Allocator) ArrayList(u8) {
        return utils.implement_func_for_tagged_union(self, "asString", ArrayList(u8), alloc);
    }

    pub fn asString_static(self: @This()) ArrayList(u8) {
        return utils.implement_func_for_tagged_union(self, "asString_static", ArrayList(u8), .{});
    }

    pub fn asFloat(self: @This()) f64 {
        return utils.implement_func_for_tagged_union(self, "asFloat", f64, .{});
    }

    pub fn asInteger(self: @This()) i64 {
        return utils.implement_func_for_tagged_union(self, "asInteger", i64, .{});
    }

    pub fn doesUnionHave_asString_static(self: @This()) bool {
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            if (@intToEnum(BuiltinFactTypes, field.value) == self) {
                if (@hasDecl(@TypeOf(@field(self, field.name)), "asString_static")) {
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

test "012-conversions" {
    {
        var bool1 = FactValue.makeDefault(BuiltinFactTypes.boolean, std.testing.allocator);
        var bool2 = FactValue.makeDefault(BuiltinFactTypes.boolean, std.testing.allocator);

        var trueString = FactValue.makeDefault(BuiltinFactTypes.string, std.testing.allocator);
        try trueString.string.value.appendSlice("true");
        var falseString = FactValue.makeDefault(BuiltinFactTypes.string, std.testing.allocator);
        try falseString.string.value.appendSlice("false");

        defer trueString.deinit();
        defer falseString.deinit();

        bool1.boolean.value = true;
        // boolean to float
        try std.testing.expect(1.0 == bool1.asFloat());
        try std.testing.expect(0.0 == bool2.asFloat());
        // boolean to int
        try std.testing.expect(1 == bool1.asInteger());
        try std.testing.expect(0 == bool2.asInteger());
        // boolean to string
        var testString = FactValue{ .string = .{ .value = bool1.asString(std.testing.allocator) } };
        defer testString.deinit();
        try std.testing.expect(trueString.compareEq(testString, std.testing.allocator));

        var testString2 = FactValue{ .string = .{ .value = bool2.asString(std.testing.allocator) } };
        defer testString2.deinit();
        try std.testing.expect(falseString.compareEq(testString2, std.testing.allocator));
    }

    // float to boolean
    // float to int
    // float to string

    // boolean to typeInfo
    // float to typeInfo
    // int to typeInfo
    // enum to typeInfo
}

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
