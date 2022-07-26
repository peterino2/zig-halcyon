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

pub const FactDatabase = fact_db.FactDatabase;

pub const Opcode = enum(u8) { load, store, compare, jump };

// FactRefs are 16 bytes each
// at most these instructions would have 2 operands?
// so 16 * 2 + 1 :align8 = 40 bytes each?
// that's kind of shit... I feel like there ought to be a better way?
// but on the other hand... I am trying to be able to deal with rich data.

const LoadOps = enum(u8) {
    from_db,
    explicit_value,
};

const TestUnion = extern union {
    u: u64,
    i: i64,
};

const ILoad = struct {
    operation: u8,
    operand: u64,
};

pub const Instruction = struct {
    instr: union(Opcode) // tag = 1 byte
    {
        load: ILoad,
        store: struct {},
        compare: struct {},
        jump: struct {},
    },
};

pub const InstructionContext = struct {
    arguments: []const FactValue,
    pc: usize = 0,
    cycleCount: u64 = 0,
    instructions: []const Instruction,
    database: *FactDatabase,
    allocator: std.mem.Allocator,
    stack: []FactValue,
};

test "perf-instruction-size" {
    std.debug.print("instruction size = {d} align = {d}\n", .{ @sizeOf(Instruction), @alignOf(Instruction) });
    std.debug.print("ILoad size = {d} align = {d}\n", .{ @sizeOf(ILoad), @alignOf(ILoad) });
    std.debug.print("TestUnion size = {d} align = {d}\n", .{ @sizeOf(TestUnion), @alignOf(TestUnion) });
}
