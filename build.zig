const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary(.{ .name = "sudoku-solver-zig", .root_source_file = .{ .path = "src/sudoku-solver.zig" }, .optimize = mode, .target = target });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{ .name = "main", .root_source_file = .{ .path = "src/main.zig" }, .optimize = mode, .target = target });
    b.installArtifact(exe);

    const unit_tests = b.addTest(.{ .name = "unit_test", .root_source_file = .{ .path = "src/sudoku-solver.zig" }, .optimize = mode, .target = target });
    const data_tests = b.addTest(.{ .name = "data_test", .root_source_file = .{ .path = "test_data.zig" }, .optimize = mode, .target = target });

    const unit_test_step = b.step("test", "Run sudoku-solver library tests");
    unit_test_step.dependOn(&unit_tests.step);
    unit_test_step.dependOn(&data_tests.step);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run sudoku-solver");
    run_step.dependOn(&run_exe.step);
}
