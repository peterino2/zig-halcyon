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

pub const InstructionContext = struct {
    arguments: []const FactValue,
    iptr: usize = 0,
    cycleCount: u64 = 0,
    instructions: []const Instruction,
    database: *FactDatabase,
    allocator: std.mem.Allocator,
    stack: ArrayList(FactValue),

    pub fn init(
        arguments: []const FactValue,
        database: *FactDatabase,
        instructions: []const Instruction,
        allocator: std.mem.Allocator,
    ) @This() {
        return .{
            .arguments = arguments,
            .database = database,
            .allocator = allocator,
            .stack = ArrayList(FactValue).init(allocator),
            .instructions = instructions,
        };
    }

    pub fn execute(self: *@This()) void {
        while (self.iptr < self.instructions.len) : (self.cycleCount += 1) {
            self.instructions[self.iptr].exec(self);
        }
    }

    pub fn deinit(self: *@This()) void {
        for (self.stack.items) |_, i| {
            self.stack.items[i].deinit(self.allocator);
        }
        self.stack.deinit();
    }

    pub fn resetStack(self: *@This()) void {
        for (self.stack.items) |_, i| {
            self.stack.items[i].deinit(self.allocator);
        }
        self.stack.resize(0) catch unreachable;
    }
};

pub const ICompare = struct {
    left: FactValue, // maybe these should be pointers to ?*FactValue?
    right: FactValue,
    operation: enum {
        compareEq,
        compareNe,
        compareLt,
        compareGt,
        compareLe,
        compareGe,
    },

    pub fn exec(self: @This(), context: *InstructionContext) void {
        var lhs: ?*FactValue = null;

        if (self.left == .ref)
            lhs = context.database.getFactFromRef(self.left.ref);

        var rhs: ?*FactValue = null;
        if (self.right == .ref)
            rhs = context.database.getFactFromRef(self.right.ref);

        if (rhs == null or lhs == null)
            return;

        var result: bool = false;

        _ = context;

        switch (self.operation) {
            .compareEq => {
                result = lhs.?.compareEq(rhs.?.*, context.allocator);
            },
            .compareNe => {
                result = lhs.?.compareNe(rhs.?.*, context.allocator);
            },
            .compareLt => {
                result = lhs.?.compareLt(rhs.?.*, context.allocator);
            },
            .compareGt => {
                result = lhs.?.compareGt(rhs.?.*, context.allocator);
            },
            .compareLe => {
                result = lhs.?.compareLe(rhs.?.*, context.allocator);
            },
            .compareGe => {
                result = lhs.?.compareGe(rhs.?.*, context.allocator);
            },
        }

        context.stack.append(FactValue{ .boolean = .{ .value = result } }) catch unreachable; // push result to stack
        context.iptr += 1;
    }
};

pub const ISetValue = struct {
    left: FactRef,
    right: FactValue,
    operation: enum { lessThan, greaterThan, lessEqual, greaterEqual, equal },

    pub fn exec(instruction: @This(), context: *InstructionContext) void {
        _ = instruction;
        _ = context;
    }
};

pub const IExec = struct {
    directiveLabel: Label,
    args: ?[]?*FactRef,
    returnValue: ?[]?*FactRef,

    // raw executions, not used with the builtin zig error system
    pub fn exec(instruction: IExec, context: *InstructionContext) void {
        _ = instruction;
        _ = context;
    }
};

pub const InstructionTag = enum {
    compare,
    setValue,
    exec,
};

pub const Instruction = struct {
    instr: union(InstructionTag) {
        compare: ICompare,
        setValue: ISetValue,
        exec: IExec,
    },

    pub fn exec(self: Instruction, context: *InstructionContext) void {
        // I don't think this is the smartest dispatcher, but it's surprisingly decent
        utils.implement_func_for_tagged_union_nonull(self.instr, "exec", void, context);
    }
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

    pub fn exec(self: FactFunction, allocator: std.mem.Allocator, context: anytype) FactValue {
        _ = self;
        _ = context;
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

test "VM hello world" {
    const allocator = std.testing.allocator;
    var database = try FactDatabase.init(allocator);
    defer database.deinit();

    var variable = try database.newFact(MakeLabel("hello"), BuiltinFactTypes.boolean);
    var variable2 = try database.newFact(MakeLabel("hello2"), BuiltinFactTypes.boolean);
    variable.*.boolean.value = true;
    variable2.*.boolean.value = false;

    var instructions = try allocator.alloc(Instruction, 2);

    instructions[0] = .{ .instr = .{ .compare = .{
        .left = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello"))).? },
        .right = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello2"))).? },
        .operation = .compareEq,
    } } };

    instructions[1] = .{ .instr = .{ .compare = .{
        .left = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello"))).? },
        .right = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello2"))).? },
        .operation = .compareNe,
    } } };

    defer allocator.free(instructions);

    var arguments: []const FactValue = try allocator.alloc(FactValue, 1);
    defer allocator.free(arguments);

    var context = InstructionContext.init(arguments, &database, instructions, allocator);
    defer context.deinit();

    // quick 2 million instructions measurement
    var i: usize = 0;
    while (i < 1000000) : (i += 1) {
        context.iptr = 0;
        context.execute();
        if (i + 1 < 1000) {
            context.resetStack();
        }
    }

    std.debug.print("stack[0] = {any}\n", .{context.stack.items[0]});
    std.debug.print("stack[1] = {any}\n", .{context.stack.items[1]});
    std.debug.print("instructions executed = {d}\n", .{context.cycleCount});

    _ = instructions;
    _ = context;
}

test "perf-hello-world" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var database = try FactDatabase.init(allocator);
    defer database.deinit();
    std.debug.print("{d}\n", .{database.types.types.items.len});

    var variable = try database.newFact(MakeLabel("hello"), BuiltinFactTypes.boolean);
    var variable2 = try database.newFact(MakeLabel("hello2"), BuiltinFactTypes.boolean);
    variable.*.boolean.value = true;
    variable2.*.boolean.value = false;

    var instructions = try allocator.alloc(Instruction, 2);
    defer allocator.free(instructions);

    instructions[0] = .{ .instr = .{ .compare = .{
        .left = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello"))).? },
        .right = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello2"))).? },
        .operation = .compareEq,
    } } };

    instructions[1] = .{ .instr = .{ .compare = .{
        .left = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello"))).? },
        .right = FactValue{ .ref = (database.getFactAsRefByLabel(MakeLabel("hello2"))).? },
        .operation = .compareNe,
    } } };

    var arguments: []const FactValue = try allocator.alloc(FactValue, 1);
    defer allocator.free(arguments);

    var context = InstructionContext.init(arguments, &database, instructions, allocator);
    defer context.deinit();
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    std.debug.print("warming up\n", .{});

    // warmup
    while (i < 10000000) : (i += 1) {
        context.iptr = 0;
        context.execute();
        context.resetStack();
    }

    std.debug.print("testing 20M instructions\n", .{});
    i = 0;
    context.cycleCount = 0;
    const startTime = timer.read();
    while (i < 10000000) : (i += 1) {
        context.iptr = 0;
        context.execute();
        if (i + 1 < 1000) {
            context.resetStack();
        }
    }

    const endTime = timer.read();

    std.debug.print("stack[0] = {any}\n", .{context.stack.items[0]});
    std.debug.print("stack[1] = {any}\n", .{context.stack.items[1]});
    std.debug.print("instructions executed = {d} instructions per second = {d}\n", .{ context.cycleCount, @intToFloat(f64, context.cycleCount) / (@intToFloat(f64, endTime - startTime) / 1000000000) });

    _ = instructions;
    _ = context;
    // create the vm.
    // add a hello_world fact to the database
    // create a branch execution context and check that it compares hello_world to false, (context.selected_branch == false)
    // call a function that sets hello_world to true
    // do another branch execution context to test hello_world
    //
}
