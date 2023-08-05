const std = @import("std");
const sudoku_solver = @import("src/sudoku-solver.zig");

test "Test top1465 dataset" {
    var allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("./data/magictour_top1465", .{});
    defer file.close();

    var reader = file.reader();

    var line = try allocator.alloc(u8, 1024);
    defer allocator.free(line);

    var p = sudoku_solver.puzzle.init();
    var count: usize = 0;

    while (try reader.readUntilDelimiterOrEof(line, '\n')) |line_data| {
        // Do something with the line
        if (line_data.len == 81) {
            try p.import(line_data);

            p.solve() catch unreachable;

            count += 1;
        }
    }
    try std.testing.expectEqual(count, 1465);
}
