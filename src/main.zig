const std = @import("std");
const sudoku_solver = @import("sudoku-solver.zig");

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("./data/top1465", .{});
    defer file.close();

    var reader = file.reader();

    var line = try allocator.alloc(u8, 1024);
    defer allocator.free(line);

    std.debug.print("Start Data test\r\n", .{});

    var p = sudoku_solver.init();
    var count: usize = 0;

    while (try reader.readUntilDelimiterOrEof(line, '\n')) |line_data| {
        // Do something with the line
        if (line_data.len == 81) {
            try p.import(line_data);

            p.solve() catch unreachable;
            count += 1;
        }
    }

    std.debug.print("Solved puzzles {} \r\n", .{count});
}
