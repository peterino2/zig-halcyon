const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const node_entities = @import("node.zig");

pub const Node = node_entities.Node;
pub const NodeString = node_entities.NodeString;
pub const NodeStringView = node_entities.NodeStringView;

pub const Choices = struct {
    instances: AutoHashMap(u32, []const u32),
    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(u32, []const u32).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
    }
};

pub const NextNode = struct {
    instances: AutoHashMap(Node, Node),
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(Node, Node).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
    }

    pub fn setNextNode(self: *Self, from: Node, to: Node) !void {
        try self.instances.put(from, to);
    }
};
