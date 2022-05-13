// top level api for interacting with C
// used as the baseline for mono or ue

const std = @import("std");
const s = @import("storyNode.zig");
const c = @cImport({
    @cInclude("Halcyon.h");
});

const StoryNodes = s.StoryNodes;
const halc_nodes_t = c.halc_nodes_t;
const HalcStory = c.HalcStory;
const HalcInteractor = c.HalcInteractor;
const HalcChoicesList = c.HalcChoicesList;

const allocator = std.heap.c_allocator;

const Cstr = ?[*:0]const u8;
const Cstr_checked = ?[*:0]const u8;

export fn HalcStory_Parse(cstr: Cstr, ret: ?*HalcStory) c_int {
    if (cstr and ret) return HalcStory_Parse_impl(cstr.?, ret.?);
    return -1;
}

fn HalcStory_Parse_impl(cstr: Cstr_checked, ret: *HalcStory) !c_int {
    var storyNodes = try allocator.create(StoryNodes);
    errdefer allocator.destroy(storyNodes);

    std.debug.print("\n{s}\n", .{cstr});

    storyNodes.* = try s.NodeParser.DoParse(std.mem.span(cstr), allocator);

    ret.*.story = storyNodes;

    ret.*.num_nodes = storyNodes.*.instances.items.len;

    return 0;
}

// export fn halc_do_parse(cstr: ?[*:0]const u8) usize {
//     return if (cstr) |str| halc_do_parse_impl(str) catch null else null;
// }
//
// export fn halc_destroy(story: ?*halc_system_handle_t) void {
//     story.destroy(story.?);
// }
//
// fn halc_do_parse_impl(cstr: [*:0]const u8) !*halc_system_handle_t {
//     var rv = try allocator.create(StoryNodes);
//     errdefer allocator.destroy(rv);
//
//     std.debug.print("\n{s}\n", .{cstr});
//
//     rv.* = try s.NodeParser.DoParse(std.mem.span(cstr), allocator);
//
//     return @ptrCast(*halc_system_handle_t, rv);
// }
//
// export fn halc_test_struct(rv: ?*c.thick_c_handle_t) c_int {
//     rv.?.* = c.thick_c_handle_t{ .handle_id = 2, .buf = undefined };
//
//     std.mem.copy(u8, &rv.?.buf, &.{ 'w', 'a', 'n', 'k', 0 });
//     return 1;
// }
