const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const node_entities = @import("node.zig");

const Node = node_entities.Node;
const NodeString = node_entities.NodeString;
const NodeStringView = node_entities.NodeStringView;

pub const CharacterNames = struct {
    instances: AutoHashMap(Node, NodeString),
    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(Node, NodeString).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.instances.iterator();
        while (iter.next()) |instance| {
            instance.value_ptr.deinit();
        }

        self.instances.deinit();
    }

    pub fn setSpeakerName(self: *Self, allocator: std.mem.Allocator, node: Node, newString: NodeStringView) !void {
        var result = (try self.instances.getOrPut(node));

        if (!result.found_existing) {
            result.value_ptr.* = NodeString.init(allocator);
        }

        var instance = result.value_ptr;
        instance.resize(newString.len) catch unreachable;
        const range = instance.items[0..instance.items.len];
        try instance.replaceRange(0, instance.items.len, newString);
        _ = range;
    }
};