const std = @import("std");
const grid = @import("grid.zig");

const cellValues = grid.cellValues;
const cellError = grid.cellError;

grid: grid,

/// Initialize the puzzle grid
pub fn init() @This() {
    return @This(){ .grid = grid.init() };
}

/// Import Sudoku Puzzle from string
pub fn importFromString(str: []const u8) !@This() {
    var self = @This().init();

    var pos: usize = 0;
    var pos_string: usize = 0;

    while ((pos_string < str.len) and (pos < 81)) {
        const char_val = str[pos_string];
        const sequence_len: u3 = try std.unicode.utf8ByteSequenceLength(char_val);

        const row: usize = pos / 9;
        const col: usize = pos % 9;

        if ((char_val >= '1') and (char_val <= '9')) {
            try self.grid.setValueFromInt(row, col, @as(u8, @intCast(char_val - '0')));
        }
        pos += 1;
        pos_string += sequence_len;
    }
    return self;
}

/// Export puzzle as string
pub fn exportAsString(self: *@This(), buffer: []u8) ![]u8 {
    @memset(buffer, 0);
    var pos: usize = 0;
    for (0..9) |row| {
        for (0..9) |col| {
            const value = try self.grid.getValueAsInt(row, col);

            if (value > 0) {
                buffer[pos] = value + '0';
            } else {
                buffer[pos] = '.';
            }
            pos += 1;
        }
    }

    return buffer[0..81];
}

/// Select candidate in grid
fn selectCandidate(self: *@This()) !struct { value: cellValues, row: usize, col: usize } {
    for (2..9) |n_cand| {
        for (0..9) |i| {
            for (0..9) |j| {
                if (n_cand == self.grid.countCandidates(.GRID_CELL, i, j)) {
                    const lastAndFirst = try self.grid.getFirstAndLastCandidates(i, j);

                    return .{ .value = lastAndFirst.a, .row = i, .col = j };
                }
            }
        }
    }

    return cellError.invalid_value;
}

/// Set value
fn setValue(self: *@This(), row: usize, col: usize, value: cellValues) !void {
    try self.grid.setValue(row, col, value);
}

/// Check if puzzle is valid and solved
pub fn checkPuzzle(self: *@This()) !bool {
    return self.grid.checkPuzzle();
}

/// Remove candidate from grid cell
fn removeCandidate(self: *@This(), row: usize, col: usize, cand: cellValues) void {
    self.grid.removeCandidate(.GRID_CELL, row, col, cand);
}

/// Solve puzzle using a backtracking algorithm
pub fn solve(self: *@This(), allocator: std.mem.Allocator) !void {
    try self.grid.generateMasks();

    while (false == try self.checkPuzzle()) {
        var p = try allocator.create(@This());
        defer {
            allocator.destroy(p);
        }

        // Create copy of puzzle
        p.* = self.*;

        const cand = try p.selectCandidate();
        try p.setValue(cand.row, cand.col, cand.value);

        p.solve(allocator) catch {
            self.removeCandidate(cand.row, cand.col, cand.value);
            continue;
        };

        // If puzzle was solved, then backpropagate solution
        self.* = p.*;
    }
}

const data = @import("data.zig");
const testing = std.testing;

test "initialize puzzle" {
    var testy = @This().init();

    try testing.expect(false == try testy.grid.checkPuzzle());

    try testing.expect(false == try testy.grid.isSolved());
}

test "test import" {
    var buffer: [82]u8 = undefined;
    for (data.valid_test_puzzles) |val| {
        var puzzle = try @This().importFromString(val);
        try std.testing.expectEqualStrings(val, try puzzle.exportAsString(&buffer));
    }

    {
        var puzzle = try @This().importFromString(data.valid_test_puzzles[0]);
        try testing.expect(puzzle.grid.checkPuzzle() catch unreachable); // is positive
    }

    for (data.valid_test_puzzles[1..]) |val| {
        var puzzle = try @This().importFromString(val);
        try testing.expect(false == puzzle.grid.checkPuzzle() catch unreachable); // is positive
    }
}

test "test import invalid values" {
    var buffer: [82]u8 = undefined;
    for (data.invalid_test_puzzles) |val| {
        var puzzle = try @This().importFromString(val);
        try std.testing.expectEqualStrings(val, try puzzle.exportAsString(&buffer));

        try testing.expectError(grid.cellError.invalid_value, puzzle.grid.checkPuzzle());
    }
}

test "pruning" {
    var buffer: [82]u8 = undefined;
    _ = buffer;
    var puzzle = try @This().importFromString(data.valid_test_puzzles[0]);
    try puzzle.grid.generateMasks();
    try testing.expect(try puzzle.grid.checkPuzzle());

    puzzle = try @This().importFromString(data.valid_test_puzzles[1]);
    try puzzle.grid.generateMasks();
    try testing.expect(try puzzle.grid.checkPuzzle());

    puzzle = try @This().importFromString(data.valid_test_puzzles[2]);
    try testing.expectEqual(@as(usize, 62), try puzzle.grid.countSolvedCells());
    try puzzle.grid.generateMasks();
    try testing.expectEqual(@as(usize, 81), try puzzle.grid.countSolvedCells());
    try testing.expect(true == try puzzle.grid.checkPuzzle());

    puzzle = try @This().importFromString(data.valid_test_puzzles[3]);
    try puzzle.grid.generateMasks();
    try testing.expect(false == try puzzle.grid.checkPuzzle());
}

test "select candidate" {
    var puzzle = try @This().importFromString(data.valid_test_puzzles[3]);
    try puzzle.grid.generateMasks();
    _ = try puzzle.grid.checkPuzzle();

    try testing.expectEqual(@as(usize, 27), try puzzle.grid.countSolvedCells());
    var t = try puzzle.selectCandidate();

    try puzzle.grid.setValue(t.row, t.col, t.value);
    try puzzle.grid.generateMasks();

    try testing.expectEqual(@as(usize, 30), try puzzle.grid.countSolvedCells());
}

test "solver" {
    const allocator = std.heap.page_allocator;

    for (data.valid_test_puzzles) |val| {
        var puzzle = try @This().importFromString(val);
        try puzzle.solve(allocator);
        try testing.expect(try puzzle.grid.checkPuzzle());
    }
}
