// top level api for interacting with C
// used as the baseline for mono or ue

const std = @import("std");
const s = @import("storyNode.zig");
const c = @cImport({
    @cInclude("Halcyon.h");
});

const StoryNodes = s.StoryNodes;
const halc_system_handle_t = c.halc_system_handle_t;

const allocator = std.heap.c_allocator;

export fn halc_do_parse(cstr: ?[*:0]const u8) ?*halc_system_handle_t {
    return if (cstr) |str| halc_do_parse_impl(str) catch null else null;
}

fn halc_do_parse_impl(cstr: [*:0]const u8) !*halc_system_handle_t {
    var rv = try allocator.create(StoryNodes);
    errdefer allocator.destroy(rv);

    std.debug.print("\n{s}\n", .{cstr});

    rv.* = try s.NodeParser.DoParse(std.mem.span(cstr), allocator);

    return @ptrCast(*halc_system_handle_t, rv);
}

export fn halc_test_struct(rv: ?*c.thick_c_handle_t) c_int {
    rv.?.* = c.thick_c_handle_t{ .handle_id = 2, .buf = undefined };

    std.mem.copy(u8, &rv.?.buf, &.{ 'w', 'a', 'n', 'k', 0 });
    return 1;
}
