const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("sudoku-solver-zig", "src/sudoku-solver.zig");
    lib.setBuildMode(mode);
    lib.install();

    const unit_tests = b.addTest("src/sudoku-solver.zig");
    unit_tests.setBuildMode(mode);

    const data_tests = b.addTest("test_data.zig");
    data_tests.setBuildMode(mode);

    const unit_test_step = b.step("test", "Run sudoku-solver library tests");
    unit_test_step.dependOn(&unit_tests.step);
    unit_test_step.dependOn(&data_tests.step);
}
