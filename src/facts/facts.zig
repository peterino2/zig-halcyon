const std = @import("std");
pub const values = @import("values.zig");
pub const utils = @import("factUtils.zig");
pub const TypeDatabase = @import("TypeDatabase.zig");
pub const FactDatabase = @import("fact_db.zig")

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

pub const Initializer = values.Initializer;
pub const FactValue = values.FactValue;
pub const FactTypeInfo = values.FactTypeInfo;
pub const FactRef = values.FactRef;

pub const BuiltinFactTypes = utils.BuiltinFactTypes;
pub const MakeLabel = utils.MakeLabel;
pub const Label = utils.Label;
pub const TypeRef = utils.TypeRef;


pub const Facts
