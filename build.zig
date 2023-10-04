const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_test = b.addExecutable(.{
        .name = "c_test",
        .optimize = optimize,
        .target = target,
    });

    c_test.addCSourceFile(.{
        .file = .{ .path = "src/c_api/test.cpp" },
        .flags = &.{},
    });

    c_test.addIncludePath(.{ .path = "src/c_api/inc" });
    c_test.linkLibC();
    c_test.linkLibCpp();
    const c_test_run = b.addRunArtifact(c_test);

    if (true) {
        const halcShared = b.addSharedLibrary(.{
            .name = "Halcyon",
            .root_source_file = .{ .path = "src/c_api.zig" },
            .version = (std.SemanticVersion.parse("0.0.1") catch unreachable),
            .optimize = optimize,
            .target = target,
        });
        halcShared.optimize = optimize;
        halcShared.addIncludePath(.{ .path = "src/c_api/inc" });
        halcShared.bundle_compiler_rt = true;
        b.installArtifact(halcShared);

        c_test.linkLibrary(halcShared);
    }

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/cliTest.zig" },
        .name = "test",
    });
    exe_tests.optimize = optimize;

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&c_test_run.step);
}
