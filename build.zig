const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the library
    const lib = b.addStaticLibrary(.{
        .name = "taskspec",
        .root_source_file = b.path("src/taskspec.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Create the module for external use
    const taskspec_module = b.addModule("taskspec", .{
        .root_source_file = b.path("src/taskspec.zig"),
    });
    _ = taskspec_module;

    // Unit tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/taskspec.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Example executable
    const example = b.addExecutable(.{
        .name = "taskspec-example",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("taskspec", lib.root_module);
    
    const install_example = b.addInstallArtifact(example, .{});
    const example_step = b.step("example", "Build the example");
    example_step.dependOn(&install_example.step);

    const run_example = b.addRunArtifact(example);
    const run_example_step = b.step("run-example", "Run the example");
    run_example_step.dependOn(&run_example.step);

    // Advanced example executable
    const advanced_example = b.addExecutable(.{
        .name = "taskspec-advanced",
        .root_source_file = b.path("examples/advanced.zig"),
        .target = target,
        .optimize = optimize,
    });
    advanced_example.root_module.addImport("taskspec", lib.root_module);
    
    const install_advanced = b.addInstallArtifact(advanced_example, .{});
    const advanced_step = b.step("advanced", "Build the advanced example");
    advanced_step.dependOn(&install_advanced.step);

    const run_advanced = b.addRunArtifact(advanced_example);
    const run_advanced_step = b.step("run-advanced", "Run the advanced example");
    run_advanced_step.dependOn(&run_advanced.step);
}
