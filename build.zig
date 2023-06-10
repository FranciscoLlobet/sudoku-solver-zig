const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("sudoku-solver-zig", "src/sudoku-solver.zig");
    lib.setBuildMode(mode);
    lib.install();

    const exe = b.addExecutable("main", "src/main.zig");
    exe.setBuildMode(mode);
    exe.install();

    const unit_tests = b.addTest("src/sudoku-solver.zig");
    unit_tests.setBuildMode(mode);

    const data_tests = b.addTest("test_data.zig");
    data_tests.setBuildMode(mode);

    const unit_test_step = b.step("test", "Run sudoku-solver library tests");
    unit_test_step.dependOn(&unit_tests.step);
    unit_test_step.dependOn(&data_tests.step);

    const run_exe = exe.run();
    run_exe.step.dependOn(b.getInstallStep());
    //if (b.args) |args| {
    //    run_exe.addArg(args);
    //}

    const run_step = b.step("run", "Run sudoku-solver");
    run_step.dependOn(&run_exe.step);
}
