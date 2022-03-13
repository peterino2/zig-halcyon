const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

pub const Node = u32;
pub const NodeString = ArrayList(u8);
pub const NodeStringView = []const u8;

pub const NodeType = enum(u8) {
    Dead, // set to this to effectively mark this node as dead
    Text,
    Response,
};

// master entities
// the position of each entity in the NodeEntities
pub const NodeEntities = struct {
    instances: ArrayList(NodeString),
    nodeTypes: ArrayList(NodeType),

    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = ArrayList(NodeString).init(allocator),
            .nodeTypes = ArrayList(NodeType).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.instances.items) |instance| {
            instance.deinit();
        }
        self.instances.deinit();
        self.nodeTypes.deinit();
    }

    // management interface
    pub fn newEntity(self: *Self, allocator: std.mem.Allocator) !Node {
        try self.instances.append(ArrayList(u8).init(allocator));
        try self.nodeTypes.append(NodeType.Text);

        std.debug.assert(self.instances.items.len > 0);
        return @intCast(u32, self.instances.items.len - 1);
    }

    pub fn newEntityFromPlainText(self: *Self, allocator: std.mem.Allocator, string: NodeStringView) !Node {
        const id = @intCast(u32, try self.newEntity(allocator));
        try self.instances.items[id].appendSlice(string);
        return id;
    }

    // direct access to node type
    pub fn setNodeType(self: *Self, node: Node, newType: NodeType) void {
        if (node < self.instances.items.len) {
            self.nodeTypes.items[node] = newType;
        }
    }
};