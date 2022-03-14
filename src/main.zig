//
const std = @import("std");

const nodes = @import("nodes/node_ecs.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

const Node = nodes.Node;
const NodeType = nodes.NodeType;
const HalcNodesECS = nodes.HalcNodesECS;

pub const HalcINteractorState = enum(u8)
{
    InDialogue,
    FinishedDialogue,
};

const Interactor = u32;
const HalcInteractor = struct {
    ecs: *HalcNodesECS,
    currentNode: Node,
    isInteracting: bool,

    const Self = @This();

    pub fn isEndOfDialogue(self: Self)  bool {
        if(self.ecs.nextNodeComponents.instances.get(self.currentNode)) {
            return false;
        } else {
            return true;
        }
    }

    // If there is no nextNode in the ecs. Then this will end the interaction
    pub fn nextNode(self: *Self) void {
        if (self.ecs.nextNodeComponents.instances.get(self.currentNode)) |n| {
            self.currentNode = n;
        } else {
            self.isInteracting = false;
            self.finishedInteraction = true;
        }
    }

    pub fn choose(self: *Self, choice: u32) void {
        if (self.ecs.choicesComponents.instances.get(self.currentNode)) |currentChoices| {
            if (choice < currentChoices.len) {
                const choiceNode = currentChoices[choice];
                if (self.ecs.nextNodeComponents.instances.get(currentChoices[choice])) |n| {
                    self.currentNode = n;
                } else {
                    std.debug.print(
                        "\nchoice {d} node {d} refers to node {d} which does not exist",
                        .{ choice, self.currentNode, choiceNode },
                    );
                }
            } else {
                std.debug.print(
                    "choice slot {d} not implemented for node {d}, this node has{d} choices available\n",
                    .{
                        choice,
                        self.currentNode,
                        currentChoices.len,
                    },
                );
            }
        } else {
            std.debug.print("node {d} has no choices available\n", .{self.currentNode});
        }
    }
};

const HalcInteractorsECS = struct {
    interactors: ArrayList(HalcInteractor),
    names: StringHashMap(u32), 
};

fn make_simple_branching_story(allocator: std.mem.Allocator) !HalcNodesECS {
    var ecs = HalcNodesECS.init(allocator);

    // create the base content for the
    var n = try ecs.entities.newEntityFromPlainText(allocator, "Hello I am the narrator."); // 0
    _ = try ecs.entities.newEntityFromPlainText(allocator, "Do you like cats or dogs."); // 1
    _ = try ecs.entities.newEntityFromPlainText(allocator, "Guess we can't be friends."); // 2
    _ = try ecs.entities.newEntityFromPlainText(allocator, "You leave in disgust."); // 3
    _ = try ecs.entities.newEntityFromPlainText(allocator, "They taste delicious."); // 4
    _ = try ecs.entities.newEntityFromPlainText(allocator, "You can't choose both, that's stupid"); // 5

    const chongs_line = try ecs.entities.newEntityFromPlainText(allocator, "YOU TAKE THAT BACK."); // 6

    n = try ecs.entities.newEntityFromPlainText(allocator, "cats"); // 7
    ecs.entities.setNodeType(n, NodeType.Response);

    n = try ecs.entities.newEntityFromPlainText(allocator, "dogs"); // 8
    ecs.entities.setNodeType(n, NodeType.Response);

    n = try ecs.entities.newEntityFromPlainText(allocator, "both"); // 9
    ecs.entities.setNodeType(n, NodeType.Response);

    try ecs.nextNodeComponents.setNextNode(0, 1);
    try ecs.nextNodeComponents.setNextNode(2, 3);
    try ecs.nextNodeComponents.setNextNode(4, 6);
    try ecs.nextNodeComponents.setNextNode(6, 3);
    try ecs.nextNodeComponents.setNextNode(5, 1);

    try ecs.nextNodeComponents.setNextNode(7, 2);
    try ecs.nextNodeComponents.setNextNode(8, 4);
    try ecs.nextNodeComponents.setNextNode(9, 5);

    try ecs.choicesComponents.instances.put(1, &.{ 7, 8, 9 });

    _ = try ecs.speakerNameComponents.setSpeakerName(allocator, chongs_line, "chong");

    return ecs;
}

test "simple branching story" {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var allocator = std.testing.allocator;

    var ecs = try make_simple_branching_story(allocator);
    defer ecs.deinit();

    // test allocation and cleanup of entities
    for (ecs.entities.instances.items) |entityText, i| {
        const speaker = ecs.speakerNameComponents.instances.get(@intCast(u32, i));
        var speakerName = if (speaker) |s| s.items else "default";
        try stdout.print("\n{s} id {d} : {s}", .{ speakerName, i, entityText.items });
    }

    // test an interactor

    {
        var i = HalcInteractor{ .ecs = &ecs, .currentNode = 0, .isInteracting = true };

        i.nextNode();
        try std.testing.expect(i.currentNode == 1);

        var i_path1 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        var i_path2 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        var i_path3 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        i_path1.choose(0);
        try std.testing.expect(i_path1.currentNode == 2);

        i_path2.choose(1);
        try std.testing.expect(i_path2.currentNode == 4);

        i_path3.choose(2);
        try std.testing.expect(i_path3.currentNode == 5);
    }

    try stdout.print("\n", .{});

    _ = stdout;
    _ = stdin;
    _ = allocator;
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var allocator = std.heap.page_allocator;

    var dialogueTexts = ArrayList([]const u8).init(allocator);
    var speakerNames = AutoHashMap(u32, []const u8).init(allocator);
    var choices = AutoHashMap(u32, []const u32).init(allocator);
    var next = AutoHashMap(u32, u32).init(allocator);

    try dialogueTexts.appendSlice(&.{
        "Hello I am the narrator.", // 0
        "Do you like cats or dogs.", // 1
        "Guess we can't be friends.", // 2
        "You leave in disgust.", //3
        "They taste delicious.", //4
        "You can't choose both, that's stupid", // 5
        "YOU TAKE THAT BACK.", // 6
        "cats", // 7
        "dogs", // 8
        "both", // 9
    });

    try speakerNames.put(6, "chong");
    try choices.put(1, &.{ 7, 8, 9 });

    try next.put(0, 1);
    try next.put(2, 3);
    try next.put(4, 6);
    try next.put(6, 3);
    try next.put(5, 1);

    try next.put(7, 2);
    try next.put(8, 4);
    try next.put(9, 5);

    // -- interactor --

    var currentNode: u32 = 0;
    var shouldBreak: bool = false;
    var buffer: [4096]u8 = undefined;

    while (!shouldBreak) {
        // print out speaker: content
        const name = speakerNames.get(currentNode) orelse "narrator";
        try stdout.print("{s}: {s}\n", .{ name, dialogueTexts.items[currentNode] });

        // if there's choices print out choices
        if (choices.get(currentNode)) |currentChoices| {
            for (currentChoices) |printChoice, i| {
                const choiceContent = if (printChoice < dialogueTexts.items.len)
                    dialogueTexts.items[printChoice]
                else
                    "Unknown choice.";
                try stdout.print("{}: {s}\n", .{ i + 1, choiceContent });
            }
            const chosenValue = while (true) {
                const selection = (try stdin.readUntilDelimiterOrEof(&buffer, '\r')) orelse unreachable;
                try stdin.skipBytes(1, .{});
                const value = std.fmt.parseInt(u32, selection, 10) catch {
                    try stdout.print("Couldn't parse that\r\n", .{});
                    continue;
                };
                if (value < 1 or value > currentChoices.len) {
                    try stdout.print("Invalid selection\r\n", .{});
                    continue;
                }
                break value;
            } else unreachable;
            currentNode = next.get(currentChoices[chosenValue - 1]) orelse unreachable;
        } else {
            _ = try stdin.readUntilDelimiterOrEof(&buffer, '\n');
            currentNode = next.get(currentNode) orelse endLoop: {
                shouldBreak = true;
                break :endLoop 0;
            };
        }
    }

    try stdout.print("bye.\n", .{});
    _ = stdout;
    _ = stdin;
}
