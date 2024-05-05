const std = @import("std");
const testing = std.testing;
const puzzle = @import("puzzle.zig");

const data = @import("data.zig");

test "basic add functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    for (data.puzzle_files) |puzzle_files| {
        var file = try std.fs.cwd().openFile(puzzle_files, .{});
        defer file.close();

        var reader = file.reader();

        const line = try allocator.alloc(u8, 1024);
        defer allocator.free(line);

        while (try reader.readUntilDelimiterOrEof(line, '\n')) |line_data| {
            if (line_data.len >= 81) {
                const originalPuzzle = try puzzle.importFromString(line_data[0..81]);
                var p = originalPuzzle;

                try p.solve(allocator);
                try testing.expect(try p.grid.checkPuzzle());
                try testing.expect(try p.verifyPuzzles(&originalPuzzle));
            }
        }
    }
}
