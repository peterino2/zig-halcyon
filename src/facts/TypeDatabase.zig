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

const TypeDatabase = struct {
    types: ArrayList(FactTypeInfo),
    typesByLabel: AutoHashMap(u32, TypeRef),
};

test "030-TypeDatabase" {}
