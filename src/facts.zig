// - create a type database
//

const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

pub const Label = struct {
    utf8: []const u8,
    hash: u32,

    pub fn fromUtf8(source: []const u8) Label {
        const hashFunc = std.hash.CityHash32.hash;

        var self = .{
            .utf8 = source,
            .hash = hashFunc(source),
        };
        return self;
    }
};

pub fn MakeLabel(utf8: []const u8) Label {
    return Label.fromUtf8(utf8);
}

pub const TypeRef = struct {
    id: usize,
};

pub const FactsError = error{
    CompareAgainstBadRef,
    InvalidTypeComparison,
    InvalidType,
};

// Types can be inserted but not removed or updated.
pub const TypeDatabaseEntry = union(enum) {
    const Self = @This();

    const InnerType = struct {
        fieldName: Label,
        typeRef: TypeRef,
    };

    builtin: struct { label: Label },
    custom: struct {
        label: Label,
        innerTypesByLabel: StringHashMap(u32),
        fields: ArrayList(InnerType),
        defaultValues: ArrayList(FactValue),
    },

    pub fn deinit(self: *Self) void {
        switch (self.*) {
            .builtin => {},
            .custom => |_| {
                self.custom.fields.deinit();
                self.custom.innerTypesByLabel.deinit();
                var i: usize = 0;
                while (i < self.custom.defaultValues.items.len) {
                    self.custom.defaultValues.items[i].deinit();
                    i += 1;
                }
                self.custom.defaultValues.deinit();
            },
        }
    }

    pub fn prettyPrint(self: TypeDatabaseEntry, typedb: TypeDatabase) void {
        switch (self) {
            .builtin => |t| {
                std.debug.print("builtin type: {s}", .{t.label.utf8});
            },
            .custom => |t| {
                std.debug.print("custom type: {s}\n", .{t.label.utf8});
                for (t.fields.items) |innerType| {
                    const typeid = innerType.typeRef.id;
                    var typeName: []const u8 = "";
                    switch (typedb.types.items[typeid]) {
                        .builtin => |builtin| {
                            typeName = builtin.label.utf8;
                        },
                        .custom => |custom| {
                            typeName = custom.label.utf8;
                        },
                    }
                    std.debug.print("    {s} ({d}): {s}\n", .{ innerType.fieldName.utf8, innerType.typeRef.id, typeName });
                }
            },
        }

        std.debug.print("\n", .{});
    }

    pub fn newBuiltin(label: Label) !TypeDatabaseEntry {
        return TypeDatabaseEntry{
            .builtin = .{ .label = label },
        };
    }

    pub fn addChildType(self: *Self, fieldName: Label, typeRef: TypeRef) !void {
        // todo: add checks to make sure that multiple fields don't collide
        try self.custom.innerTypesByLabel.put(fieldName.utf8, @intCast(u32, self.custom.fields.items.len));
        try self.custom.fields.append(.{ .fieldName = fieldName, .typeRef = typeRef });
    }

    pub fn pushDefaultValue(self: *Self, value: FactValue) !void {
        var newValueId = self.custom.defaultValues.items.len;
        try self.custom.defaultValues.append(value);
        _ = newValueId;
    }

    pub fn newCustomType(label: Label, alloc: std.mem.Allocator) TypeDatabaseEntry {
        return TypeDatabaseEntry{
            .custom = .{
                .label = label,
                .fields = ArrayList(InnerType).init(alloc),
                .innerTypesByLabel = StringHashMap(u32).init(alloc),
                .defaultValues = ArrayList(FactValue).init(alloc),
            },
        };
    }
};

const BuiltinFactTypes = enum {
    _BADTYPE,
    boolean,
    string,
    integer,
    float,
    typeRef,
    ref,
    customType,
};

pub const TypeDatabase = struct {
    const Self = @This();
    types: ArrayList(TypeDatabaseEntry),
    typesByLabel: AutoHashMap(u32, TypeRef),

    pub fn init(alloc: std.mem.Allocator) !TypeDatabase {
        // boolean, string integer float
        var self: TypeDatabase = .{
            .types = ArrayList(TypeDatabaseEntry).init(alloc),
            .typesByLabel = AutoHashMap(u32, TypeRef).init(alloc),
        };

        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |huh| {
            if (@field(BuiltinFactTypes, huh.name) != BuiltinFactTypes.customType) {
                var entry = try TypeDatabaseEntry.newBuiltin(comptime MakeLabel(huh.name));
                entry.prettyPrint(self);
                var newTypeRef: TypeRef = .{ .id = self.types.items.len };
                try self.typesByLabel.put(entry.builtin.label.hash, newTypeRef);
                try self.types.append(entry);
            }
        }
        return self;
    }

    pub fn getTypeByLabel(self: *Self, label: Label) TypeRef {
        if (self.typesByLabel.contains(label.hash)) {
            return self.typesByLabel.get(label.hash).?;
        } else {
            return TypeRef{ .id = 0 };
        }
    }

    pub fn addNewType(self: *Self, typeInfo: TypeDatabaseEntry) !TypeRef {
        var newTypeRef: TypeRef = .{ .id = self.types.items.len };
        try self.typesByLabel.put(typeInfo.custom.label.hash, newTypeRef);
        try self.types.append(typeInfo);
        return newTypeRef;
    }

    pub fn deinit(self: *Self) void {
        {
            var i: usize = 0;
            while (i < self.types.items.len) {
                self.types.items[i].deinit();
                i += 1;
            }
            self.types.deinit();
        }
        self.typesByLabel.deinit();
    }
};

pub const FactValue = union(BuiltinFactTypes) {
    _BADTYPE: struct {},
    boolean: bool,
    string: ArrayList(u8),
    integer: i64,
    float: f64,
    typeRef: TypeRef,
    ref: usize,
    customType: struct {
        typeRef: TypeRef,
        dataStore: ArrayList(FactValue),
    },

    pub fn prettyPrintValue(self: @This()) void {
        switch (self) {
            ._BADTYPE => {
                std.debug.print("INVALID_VALUE\n", .{});
            },
            .boolean => {
                std.debug.print("boolean = {s}\n", .{self.boolean});
            },
            .string => {
                std.debug.print("string = {s}\n", .{self.string.items});
            },
            .integer => {
                std.debug.print("integer = {d}\n", .{self.integer});
            },
            .float => {
                std.debug.print("float = {d}\n", .{self.float});
            },
            .typeRef => {
                std.debug.print("typeRef.id = {d}\n", .{self.typeRef.id});
            },
            .ref => {
                std.debug.print("ref = {d}\n", .{self.ref});
            },
            .customType => |data| {
                std.debug.print("custom Type: typeRef.id = {d}\n", .{self.customType.typeRef.id});
                for (data.dataStore.items) |value| {
                    std.debug.print("  ", .{});
                    value.prettyPrintValue();
                }
            },
        }
    }

    pub fn fromBool(boolean: bool) !@This() {
        return FactValue{ .boolean = boolean };
    }

    pub fn fromInteger(integer: i64) !@This() {
        return FactValue{ .integer = integer };
    }

    pub fn fromFloat(float: f64) !@This() {
        return FactValue{ .float = float };
    }

    pub fn fromTypeRef(typeRef: TypeRef) !@This() {
        return FactValue{ .typeRef = typeRef };
    }

    pub fn fromRef(ref: usize) !@This() {
        return FactValue{ .ref = ref };
    }

    pub fn fromUtf8(value: []const u8, alloc: std.mem.Allocator) !@This() {
        var f = FactValue{ .string = ArrayList(u8).init(alloc) };

        try f.string.appendSlice(value);
        return f;
    }

    pub fn fromCustomType(
        typeDb: TypeDatabase,
        typeRef: TypeRef,
        initializerList: []FactValue,
        alloc: std.mem.Allocator,
    ) !FactValue {
        var typeInfo = typeDb.types.items[typeRef.id];
        // if(typeRef.id < BuiltinFactTypes.customType)
        // {
        //     switch(@intToEnum(BuiltinFactTypes, typeRef.id))
        //     {
        //         ._BADTYPE => {
        //         },
        //         .boolean => {
        //         },
        //         .string => {
        //         },
        //         .integer => {
        //         },
        //         .float => {
        //         },
        //         .typeRef => {
        //         },
        //         .ref => {
        //         },
        //         .customType => {
        //         }
        //     },
        //     }
        // }

        var self = FactValue{
            .customType = .{
                .typeRef = typeRef,
                .dataStore = ArrayList(FactValue).init(alloc),
            },
        };

        // fill up values based on the initializerList, fill the remaining with default values.

        try self.customType.dataStore.appendSlice(initializerList);

        // create default values from TypeDb

        var i: usize = self.customType.dataStore.items.len;

        while (i < typeInfo.custom.defaultValues.items.len) {
            try self.customType.dataStore.append(typeInfo.custom.defaultValues.items[i]);
            i += 1;
        }

        // fill out the rest with defaults
        while (i < typeInfo.custom.fields.items.len) {
            // try self.customType.dataStore.append();
            i += 1;
        }

        return self;
    }

    pub fn deinit(self: *FactValue) void {
        switch (self.*) {
            .string => |string| {
                string.deinit();
            },
            .boolean => {},
            .integer => {},
            .float => {},
            .ref => {},
            .typeRef => {},
            .customType => {},
            ._BADTYPE => {},
        }
    }
};

// This is a variable which wraps a value
pub const FactVar = struct {
    label: Label,
    data: FactValue,
};

pub const FactsDatabase = struct {
    const Self = @This();
    vars: ArrayList(FactVar),
    labelMap: AutoHashMap(u32, usize),

    pub fn deinit(self: *Self) void {
        for (self.vars.items) |x| {
            switch (x.data) {
                ._BADTYPE => {},
                .typeRef => {},
                .ref => {},
                .customType => {},
                .boolean => {},
                .integer => {},
                .float => {},
                .string => |s| {
                    s.deinit();
                },
            }
        }
        self.vars.deinit();
        self.labelMap.deinit();
    }

    pub fn newFactsDb(alloc: std.mem.Allocator) Self {
        return Self{
            .vars = ArrayList(FactVar).init(alloc),
            .labelMap = AutoHashMap(u32, usize).init(alloc),
        };
    }

    pub fn addFact_bool(self: *Self, label: Label, default: bool) !void {
        var newFactId = self.vars.items.len;
        var newFact = FactVar{ .label = label, .data = .{ .boolean = default } };
        try self.vars.append(newFact);
        try self.labelMap.put(label.hash, newFactId);
    }

    pub fn addFact_string(self: *Self, label: Label, default: []const u8, alloc: std.mem.Allocator) !void {
        var newFactId = self.vars.items.len;
        var newstring = ArrayList(u8).init(alloc);
        try newstring.appendSlice(default);
        var newFact = FactVar{ .label = label, .data = .{ .string = newstring } };
        try self.vars.append(newFact);
        try self.labelMap.put(label.hash, newFactId);
    }

    pub fn addFact_float(self: *Self, label: Label, default: f64) !void {
        var newFactId = self.vars.items.len;
        var newFact = FactVar{ .label = label, .data = .{ .float = default } };
        try self.vars.append(newFact);
        try self.labelMap.put(label.hash, newFactId);
    }

    pub fn addFact_integer(self: *Self, label: Label, default: i64) !void {
        var newFactId = self.vars.items.len;
        var newFact = FactVar{ .label = label, .data = .{ .integer = default } };
        try self.vars.append(newFact);
        try self.labelMap.put(label.hash, newFactId);
    }

    pub fn getFactIdByLabel(self: Self, label: Label) usize {
        if (self.labelMap.contains(label.hash)) {
            return self.labelMap.get(label.hash).?;
        }
        return 0;
    }

    pub fn getFactByLabel(self: Self, label: Label) !FactVar {
        var id = self.getFactIdByLabel(label);
        return self.vars.items[id];
    }

    pub fn compareFacts(self: Self, leftLabel: Label, rightLabel: Label) !bool {
        // returns true or false, raises error on type mismatch
        var leftFact = self.getFactIdByLabel(leftLabel);
        var rightFact = self.getFactIdByLabel(rightLabel);
        _ = leftFact;
        _ = rightFact;

        return false;
    }

    pub fn compareEq(self: Self, left: Label, value: FactValue) !bool {
        var leftFact = try self.getFactByLabel(left);
        var leftTypeTag: BuiltinFactTypes = leftFact.data;
        var rightTypeTag: BuiltinFactTypes = value;

        if (leftTypeTag == rightTypeTag) {
            switch (leftFact.data) {
                .boolean => |data| {
                    return data == value.boolean;
                },
                ._BADTYPE => {
                    return FactsError.CompareAgainstBadRef;
                },
                .typeRef => |data| {
                    return data.id == value.typeRef.id;
                },
                .ref => {},
                .customType => {},
                .integer => |data| {
                    return data == value.integer;
                },
                .float => |data| {
                    return data == value.float;
                },
                .string => |data| {
                    const val = std.mem.eql(u8, data.items, value.string.items);
                    // std.debug.print("'{s}' == '{s}' {s}\n", .{ data.items, value.string.items, val });
                    return val;
                },
            }
        }
        return false;
    }
};

test "Labels" {
    std.debug.print("\n", .{});
    var x1 = comptime MakeLabel("Wutangclan");
    var x2 = comptime MakeLabel("Wutangclan");
    std.debug.print("{s}: 0x{x}\n", .{ x1.utf8, x1.hash });
    std.debug.assert(x1.hash == x2.hash);
}

test "001-making-vars" {
    std.debug.print("\n", .{});
    var typedb = try TypeDatabase.init(std.testing.allocator);
    defer typedb.deinit();

    var dummyType = TypeDatabaseEntry.newCustomType(MakeLabel("myStruct2"), std.testing.allocator);
    _ = try typedb.addNewType(dummyType);

    var newType = TypeDatabaseEntry.newCustomType(MakeLabel("myStruct"), std.testing.allocator);
    try newType.addChildType(MakeLabel("field_1"), typedb.getTypeByLabel(MakeLabel("boolean")));
    try newType.addChildType(MakeLabel("another_field"), typedb.getTypeByLabel(MakeLabel("boolean")));
    try newType.addChildType(MakeLabel("bad_field"), typedb.getTypeByLabel(MakeLabel("some non existent type")));
    try newType.addChildType(MakeLabel("field_2"), typedb.getTypeByLabel(MakeLabel("string")));
    try newType.addChildType(MakeLabel("field_3"), typedb.getTypeByLabel(MakeLabel("integer")));
    var ref = try typedb.addNewType(newType);

    newType = TypeDatabaseEntry.newCustomType(MakeLabel("mySecondStruct"), std.testing.allocator);
    try newType.addChildType(MakeLabel("field_1"), typedb.getTypeByLabel(MakeLabel("myStruct")));
    _ = try typedb.addNewType(newType);

    try std.testing.expect(typedb.getTypeByLabel(MakeLabel("myStruct")).id == ref.id);
    // print out all types from the typeDatabase

    for (typedb.types.items) |typeEntry, i| {
        std.debug.print("{d}: ", .{i});
        typeEntry.prettyPrint(typedb);
    }

    var facts = FactsDatabase.newFactsDb(std.testing.allocator);
    defer facts.deinit();

    try facts.addFact_bool(comptime MakeLabel("testBoolean"), true);
    try facts.addFact_string(comptime MakeLabel("testString"), "wanker", std.testing.allocator);
    try facts.addFact_float(comptime MakeLabel("testFloat"), 420.69);
    try facts.addFact_integer(comptime MakeLabel("testInteger"), 420);

    try std.testing.expect((try facts.compareEq(
        comptime MakeLabel("testBoolean"),
        comptime try FactValue.fromBool(true),
    )) == true);

    var testValue = try FactValue.fromUtf8("wanker", std.testing.allocator);
    defer testValue.deinit();

    try std.testing.expect((try facts.compareEq(
        comptime MakeLabel("testString"),
        testValue,
    )) == true);
}

test "002-nested-anonymous-types" {
    var typedb = try TypeDatabase.init(std.testing.allocator);
    defer typedb.deinit();

    var dummyType = TypeDatabaseEntry.newCustomType(MakeLabel("myStruct2"), std.testing.allocator);
    _ = try typedb.addNewType(dummyType);

    var newType = TypeDatabaseEntry.newCustomType(MakeLabel("myStruct"), std.testing.allocator);
    try newType.addChildType(MakeLabel("field_1"), typedb.getTypeByLabel(MakeLabel("boolean")));
    try newType.addChildType(MakeLabel("another_field"), typedb.getTypeByLabel(MakeLabel("boolean")));
    try newType.addChildType(MakeLabel("bad_field"), typedb.getTypeByLabel(MakeLabel("some non existent type")));
    try newType.addChildType(MakeLabel("field_2"), typedb.getTypeByLabel(MakeLabel("string")));
    try newType.addChildType(MakeLabel("field_3"), typedb.getTypeByLabel(MakeLabel("integer")));
    var ref = try typedb.addNewType(newType);

    {
        var single_level_factValue = try FactValue.fromCustomType(typedb, ref, &.{}, std.testing.allocator);
        defer single_level_factValue.deinit();
        single_level_factValue.prettyPrintValue();
        _ = single_level_factValue;
    }

}

test "000-TypeDatabase-simple" {
    // this one lists out builtin types.
    std.debug.print("\n", .{});
    var typedb = try TypeDatabase.init(std.testing.allocator);
    defer typedb.deinit();

    try std.testing.expect(typedb.getTypeByLabel(comptime MakeLabel("_BADTYPE")).id == 0);
    try std.testing.expect(typedb.getTypeByLabel(comptime MakeLabel("boolean")).id == 1);
    try std.testing.expect(typedb.getTypeByLabel(comptime MakeLabel("float")).id == 4);
}

test "learning inline-for" {
    std.debug.print("\n", .{});
    inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |huh| {
        if (@field(BuiltinFactTypes, huh.name) != BuiltinFactTypes.customType) {
            std.debug.print("{s}\n", .{huh.name});
        }
    }
}
