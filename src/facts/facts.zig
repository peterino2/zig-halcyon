const std = @import("std");
pub const values = @import("values.zig");
pub const utils = @import("factUtils.zig");
pub const TypeDatabase = @import("TypeDatabase.zig");
pub const fact_db = @import("fact_db.zig");

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

pub const FactsDataBase = fact_db.TypeDatabase;

pub const ICompare = struct {
    left: FactRef,
    right: FactRef,
    operation: enum { lessThan, greaterThan, lessEqual, greaterEqual, equal },
};

pub const IExecDirective = struct {
    directiveLabel: Label,
    args: ?[]?*FactRef,
};

pub const Instruction = struct {
    instr: union {
        compare: ICompare,
    },
};

// There are native functions called directives, then there are
// compiled sequences of instructions called FactsFunctions
pub const FactFunction = struct {
    instructions: ArrayList(Instruction),
    arguments: ArrayList(FactRef),

    pub fn init(allocator: std.mem.Allocator) !FactFunction {
        var self = FactFunction{
            .instructions = ArrayList(Instruction).init(allocator),
        };

        return self;
    }
};

// Lets thing for a minute on how specifically how this is
// supposed to work with interactors and story nodes.
// a context is created when execution of a function starts.
pub const FactsVMBranchContext = struct {};

// Lets thing for a minute on how specifically how this is
// supposed to work with interactors and story nodes.
// a context is created when execution of a function starts.
pub const FactsVMDirectiveContext = struct {};

// global state container and director.
pub const FactsVM = struct {};
