const std = @import("std");

const node_entities = @import("node.zig");
const node_choices = @import("node_links.zig");
const node_characters = @import("node_characters.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

pub const Node = node_entities.Node;
pub const NodeType = node_entities.NodeType;
pub const NodeEntities = node_entities.NodeEntities;
pub const NodeString = node_entities.NodeString;
pub const NodeStringView = node_entities.NodeStringView;

pub const Choices = node_choices.Choices;
pub const NextNode = node_choices.NextNode;
 
pub const CharacterNames = node_characters.CharacterNames;


pub const HalcNodesECS = struct {
    entities: NodeEntities,
    speakerNameComponents: CharacterNames,
    choicesComponents: Choices,
    nextNodeComponents: NextNode,

    const Self = @This();

    // management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .entities = NodeEntities.init(allocator),
            .speakerNameComponents = CharacterNames.init(allocator),
            .choicesComponents = Choices.init(allocator),
            .nextNodeComponents = NextNode.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit();
        self.speakerNameComponents.deinit();
        self.choicesComponents.deinit();
        self.nextNodeComponents.deinit();
    }
};