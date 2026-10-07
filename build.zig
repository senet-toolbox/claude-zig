const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // The direct Anthropic API.
    const mod = b.addModule("claude", .{
        .root_source_file = b.path("src/claude.zig"),
        .target = target,
        .optimize = optimize,
    });

    // The same surface over Vertex AI, which authenticates differently.
    _ = b.addModule("vertex", .{
        .root_source_file = b.path("src/vertex.zig"),
        .target = target,
        .optimize = optimize,
    });

    // `src/tests.zig` forces analysis of every declaration -- Zig only
    // checks what is reachable, and these files had never been fully
    // analysed, so a call to `std.posix.getenv` (removed in 0.16) had gone
    // unnoticed.
    const tests = b.addTest(.{
        .name = "claude",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = true;

    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    const example = b.addExecutable(.{
        .name = "claude_demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/claude_demo.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "claude", .module = mod }},
        }),
    });
    b.installArtifact(example);

    const run_example = b.addRunArtifact(example);
    if (b.args) |args| run_example.addArgs(args);
    const example_step = b.step("example", "Send a message (needs ANTHROPIC_API_KEY)");
    example_step.dependOn(&run_example.step);
}
