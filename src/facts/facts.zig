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

pub const IExec = struct {
    directiveLabel: Label,
    args: ?[]?*FactRef,
    returnValue: ?[]?*FactRef,
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

    pub fn exec(self: FactFunction, allocator: std.mem.Allocator) FactValue {
        _ = self;
        return FactValue.makeDefault(BuiltinFactTypes.integer, allocator);
    }
};

pub const VMError = struct {
    executionError: []u8,
    errorTag: enum {
        OutOfMemory,
        BadInstruction,
        MathError,
    },
};

// a context is created when execution of a function starts.

// it recieves some contextual information from the top level FactsVM,
// and it can do stuff like
pub const FactsVMBranchContext = struct {
    selected_branch: ?usize,
    errors: ArrayList(VMError),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) FactsVMBranchContext {
        return FactsVMBranchContext{
            .selected_branch = null,
            .errors = ArrayList(VMError).init(),
            .allocator = allocator,
        };
    }

    pub fn execTopLevelBranchingFunction(self: *FactsVMBranchContext, func: FactFunction) !void {
        // a top level branching function accepts zero arguments, and returns a value
        // that can be coerced into a usize.
        var value = func.exec(self.allocator);
        defer value.deinit();

        //if (value.asInteger() == null) {}
    }
};

//
pub const FactsVMDirectiveContext = struct {};

// global state container and executor spawner.
pub const FactsVM = struct {};
