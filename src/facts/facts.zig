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

// an incredibly simple VM specifically designed for querying and setting data in the database.
// I don't expect that the specific indivudal instructions are hyper optimized for speed
// But closer to python i'd want individual instructions to be quite rich and capable
// of doing a lot.

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

    pub fn pushValue(self: *@This(), value: FactValue) !void {
        try self.stack.append(value);
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

    pub fn popValue(self: *@This()) ?FactValue {
        return self.stack.popOrNull();
    }
};

// Instruction: Compare
// operands: lhs, rhs,
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

        context.pushValue(FactValue{ .boolean = .{ .value = result } }) catch unreachable;
        context.iptr += 1;
    }
};

// instruction: SetValue
pub const ISetValue = struct {
    left: FactRef,
    right: FactValue,
    operation: enum { lessThan, greaterThan, lessEqual, greaterEqual, equal },

    pub fn exec(instruction: @This(), context: *InstructionContext) void {
        _ = instruction;
        _ = context;
    }
};

// instruction: Exec
pub const IExec = struct {
    directiveLabel: Label,

    // raw executions, not used with the builtin zig error system
    pub fn exec(instruction: IExec, context: *InstructionContext) void {
        _ = instruction;
        _ = context;
    }
};

pub const IJump = struct {
    value: isize,
    mode: enum {
        absolute,
        relative, // good for switch cases and shit like that
        stackAbsolute,
        stackRelative,
    },

    pub fn exec(instr: IJump, context: *InstructionContext) void {
        switch (instr.mode) {
            .absolute => {
                context.iptr = @intCast(usize, instr.value);
            },
            .relative => {
                context.iptr = @intCast(usize, @intCast(isize, context.iptr) + instr.value);
            },
            .stackAbsolute => {
                var val = context.popValue().?;
                defer val.deinit(context.allocator);
                context.iptr = @intCast(usize, val.asInteger().?);
            },
            .stackRelative => {
                var val = context.popValue().?;
                defer val.deinit(context.allocator);
                context.iptr = @intCast(usize, @intCast(isize, context.iptr) + val.asInteger().?);
            },
        }
    }
};

pub const InstructionTag = enum {
    compare,
    setValue,
    jump,
    exec,
};

pub const Instruction = struct {
    instr: union(InstructionTag) {
        compare: ICompare,
        setValue: ISetValue,
        jump: IJump,
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

// creates a database with test data from each type of data
fn create_test_database(allocator: std.mem.Allocator) !FactDatabase {
    var database = try FactDatabase.init(allocator);

    // load with integers
    (try database.newFact(MakeLabel("int0"), BuiltinFactTypes.integer)).*.integer.value = 0;
    (try database.newFact(MakeLabel("int1"), BuiltinFactTypes.integer)).*.integer.value = 1;
    (try database.newFact(MakeLabel("int1"), BuiltinFactTypes.integer)).*.integer.value = -1;

    // load with booleans
    (try database.newFact(MakeLabel("bool0"), BuiltinFactTypes.boolean)).*.boolean.value = false;
    (try database.newFact(MakeLabel("bool1"), BuiltinFactTypes.boolean)).*.boolean.value = true;

    // load with floats
    (try database.newFact(MakeLabel("f0"), BuiltinFactTypes.float)).*.float.value = 0.0;
    (try database.newFact(MakeLabel("f1"), BuiltinFactTypes.float)).*.float.value = 1.0;
    (try database.newFact(MakeLabel("f2"), BuiltinFactTypes.float)).*.float.value = -1.0;
    (try database.newFact(MakeLabel("f3"), BuiltinFactTypes.float)).*.float.value = 1e9;

    // load with nulls
    _ = (try database.newFact(MakeLabel("null0"), BuiltinFactTypes.nullType));
    _ = (try database.newFact(MakeLabel("null1"), BuiltinFactTypes.nullType));

    // load with refs to each type
    (try database.newFact(MakeLabel("ref0"), BuiltinFactTypes.ref)).*.ref = database.getFactAsRefByLabel(MakeLabel("int0")).?;
    (try database.newFact(MakeLabel("ref1"), BuiltinFactTypes.ref)).*.ref = database.getFactAsRefByLabel(MakeLabel("f3")).?;
    (try database.newFact(MakeLabel("ref1"), BuiltinFactTypes.ref)).*.ref = database.getFactAsRefByLabel(MakeLabel("bool0")).?;
    (try database.newFact(MakeLabel("ref1"), BuiltinFactTypes.ref)).*.ref = database.getFactAsRefByLabel(MakeLabel("null0")).?;

    // load with strings

    {
        var s = (try database.newFact(MakeLabel("string0"), BuiltinFactTypes.string)).*.string.value;
        s.clearRetainingCapacity();
        try s.appendSlice("This is a totally sick string");
    }

    {
        var s = (try database.newFact(MakeLabel("string1"), BuiltinFactTypes.string)).*.string.value;
        s.clearRetainingCapacity();
        try s.appendSlice("What the fuck did you just say about me");
    }

    {
        var s = (try database.newFact(MakeLabel("string2"), BuiltinFactTypes.string)).*.string.value;
        s.clearRetainingCapacity();
        try s.appendSlice("");
    }

    // load with arrays, not available yet..

    return database;
}

test "i000-compare" {
    var x = try create_test_database(std.testing.allocator);
    defer x.deinit();

    var s = try x.prettyDumpStringAlloc(std.testing.allocator);
    defer std.testing.allocator.free(s);

    std.debug.print("\n", .{});
    std.debug.print("{s}\n", .{s});
}

test "perf-hello-world" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    std.debug.print("Instruction size={d} align={d}\n", .{ @sizeOf(Instruction), @alignOf(Instruction) });
    std.debug.print("ICompare size={d} align={d}\n", .{ @sizeOf(ICompare), @alignOf(ICompare) });
    std.debug.print("ISetValue size={d} align={d}\n", .{ @sizeOf(ISetValue), @alignOf(ISetValue) });
    std.debug.print("IJump size={d} align={d}\n", .{ @sizeOf(IJump), @alignOf(IJump) });
    std.debug.print("IExec size={d} align={d}\n", .{ @sizeOf(IExec), @alignOf(IExec) });

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

    std.debug.print(
        "instructions executed = {d} instructions per second = {d}\n",
        .{
            context.cycleCount,
            @intToFloat(f64, context.cycleCount) / (@intToFloat(f64, endTime - startTime) / 1000000000),
        },
    );

    _ = instructions;
    _ = context;
    // create the vm.
    // add a hello_world fact to the database
    // create a branch execution context and check that it compares hello_world to false, (context.selected_branch == false)
    // call a function that sets hello_world to true
    // do another branch execution context to test hello_world
    //
    // Wow.. i Am actually really fucking bad at writing assembly
}
