const std = @import("std");

/// An enumeration to represent the state of candidates in a Sudoku cell.
const cand_state = enum(i16) {
    invalid = -1, // State is invalid
    no_candidates = 0, // Cell has no candidates
    one_candidate = 1, // Cell has one candidate
    several_candidates = 2, // Cell has multiple candidates
};

/// An enumeration to represent the state of the Sudoku puzzle.
const puzzle_state = enum(i16) {
    invalid = -1, // puzzle state is invalid
    solved = 0, // Puzzle is solved
    not_solved = 1, // Puzzle is not yet solved
};

/// An enumeration to represent the possible states of a Sudoku cell.
const cell_values = enum(i16) {
    invalid = -1, // invalid cell value
    no_value = 0,
    value_1 = (1 << 0),
    value_2 = (1 << 1),
    value_3 = (1 << 2),
    value_4 = (1 << 3),
    value_5 = (1 << 4),
    value_6 = (1 << 5),
    value_7 = (1 << 6),
    value_8 = (1 << 7),
    value_9 = (1 << 8),
    value_mask = 0x1FF,
};

/// A function to validate the bitmask.
/// - `mask`: The bitmask to validate.
/// Returns: The state of candidates based on the number of '1's in the bitmask.
fn validateBitMask(mask: i16) cand_state {
    return switch (@popCount(mask)) {
        2, 3, 4, 5, 6, 7, 8, 9 => cand_state.several_candidates,
        1 => cand_state.one_candidate,
        0 => cand_state.no_candidates,
        else => cand_state.invalid,
    };
}

/// A function to convert a bitmask to a value.
/// - `mask`: The bitmask to convert.
/// Returns: The value equivalent to the bitmask, or -1 if the mask is invalid or has several values.
fn convertBitMaskToValue(mask: i16) i16 {
    return switch (validateBitMask(mask)) {
        cand_state.no_candidates => 0,
        cand_state.one_candidate => @ctz(mask) + 1,
        else => -1,
    };
}

/// A function to convert a value to a bitmask.
/// - `val`: The value to convert.
/// Returns: The bitmask equivalent to the value.
fn convertValueToBitMask(val: i16) cell_values {
    return switch (val) {
        0 => cell_values.no_value,
        1, 2, 3, 4, 5, 6, 7, 8, 9 => @intToEnum(cell_values, std.math.shl(i16, 1, @intCast(u5, val) - 1)),
        else => cell_values.invalid,
    };
}

/// A structure to represent a cell in the Sudoku puzzle.
const cell = struct {
    value: cell_values,
    cand: i16,

    fn init() cell {
        var c: cell = .{ .value = cell_values.no_value, .cand = @enumToInt(cell_values.value_mask) };
        return c;
    }

    fn resetCandidate(self: *cell) void {
        self.cand = @enumToInt(cell_values.value_mask);
    }

    fn getValue(self: *const cell) cell_values {
        return self.value;
    }

    fn setValue(self: *cell, value: cell_values) void {
        self.value = value;
    }

    fn setCandidate(self: *cell, cand: i16) void {
        self.cand = cand;
    }

    fn getCandidate(self: *const cell) i16 {
        return self.cand;
    }
};

pub const puzzle = struct {
    cell: [9][9]cell,

    row_cand: [9]i16,
    col_cand: [9]i16,
    sub_cand: [9]i16,

    fn init() puzzle {
        var p: puzzle = .{ .cell = undefined, .row_cand = undefined, .col_cand = undefined, .sub_cand = undefined };

        var col: usize = 0;
        var row: usize = 0;
        var idx: usize = 0;

        while (row < 9) {
            while (col < 9) {
                p.cell[row][col] = cell.init();
                col += 1;
            }
            row += 1;
        }

        while (idx < 9) {
            p.row_cand[idx] = @enumToInt(cell_values.value_mask);
            p.col_cand[idx] = @enumToInt(cell_values.value_mask);
            p.sub_cand[idx] = @enumToInt(cell_values.value_mask);

            idx += 1;
        }

        return p;
    }

    fn setValue(self: *puzzle, row: usize, col: usize, value: i16) void {
        if ((row < 9) and (col < 9)) {
            self.cell[row][col].setValue(convertValueToBitMask(value));

            if (value > 0) {
                self.cell[row][col].setCandidate(@enumToInt(cell_values.no_value)); // Clears the candidate mask
            } else {
                self.cell[row][col].setCandidate(@enumToInt(cell_values.value_mask)); // Resets the candidate mask
            }
        }
    }

    fn getValue(self: *const puzzle, row: usize, col: usize) i16 {
        if ((row < 9) and (col < 9)) {
            return convertBitMaskToValue(@enumToInt(self.cell[row][col].getValue()));
        } else {
            return @enumToInt(cell_values.invalid);
        }
    }

    fn getCandidate(self: *const puzzle, row: usize, col: usize) u16 {
        if ((row < 9) and (col < 9)) {
            return self.cell[row][col].getCandidate();
        } else {
            return @enumToInt(cell_values.invalid);
        }
    }

    fn removeCandidate(self: *puzzle, row: usize, col: usize, cand: u5) void {
        self.cell[row][col].setCandidate(~std.math.shl(i16, 1, cand - 1) & self.cell[row][col].getCandidate());
    }

    fn import(self: *puzzle, input_string: []const u8) void {
        var pos: usize = 0;
        var pos_string: usize = 0;

        while ((pos_string < input_string.len) and (pos < 81)) {
            const char_val = input_string[pos_string];
            const sequence_len: u3 = std.unicode.utf8ByteSequenceLength(char_val) catch unreachable;

            const row: usize = pos / 9;
            const col: usize = pos % 9;

            if ((char_val >= '1') and (char_val <= '9')) {
                self.setValue(row, col, @intCast(i16, char_val - '0'));
            } else {
                self.setValue(row, col, 0);
            }

            pos += 1;
            pos_string += sequence_len;
        }

        var idx: usize = 0;
        while (idx < 9) {
            self.row_cand[idx] = @enumToInt(cell_values.value_mask);
            self.col_cand[idx] = @enumToInt(cell_values.value_mask);
            self.sub_cand[idx] = @enumToInt(cell_values.value_mask);

            idx += 1;
        }
    }

    fn exportAsString(self: *const puzzle) []u8 {
        var output_string: [82]u8 = undefined;
        var pos: usize = 0;

        for (self.cell) |row| {
            for (row) |element| {
                var value = @intCast(u8, convertBitMaskToValue(@enumToInt(element.getValue())));

                if (value > 0) {
                    output_string[pos] = value + '0';
                } else {
                    output_string[pos] = '.';
                }
                pos += 1;
            }
        }

        return output_string[0..81];
    }

    fn checkSequence(self: *const puzzle, sequence: []const i16) bool {
        _ = self;
        var cand_mask: i16 = 0;

        for (sequence) |val| {
            if (0 == (cand_mask & val)) {
                cand_mask |= val;
            } else {
                return false;
            }
        }
        return true;
    }

    fn checkRows(self: *const puzzle) bool {
        var match: bool = true;

        var sequence: [9]i16 = undefined;

        for (self.cell) |row| {
            var col: usize = 0;
            for (row) |element| {
                sequence[col] = @enumToInt(element.getValue());
                col += 1;
            }

            if (false == self.checkSequence(&sequence)) {
                return false;
            }
        }

        return match;
    }

    fn checkCols(self: *const puzzle) bool {
        var sequence: [9]i16 = undefined;
        var col: usize = 0;

        while (col < 9) {
            var row: usize = 0;
            while (row < 9) {
                sequence[row] = @enumToInt(self.cell[row][col].getValue());
                row += 1;
            }

            if (false == self.checkSequence(&sequence)) {
                return false;
            }

            col += 1;
        }

        return true;
    }

    fn checkSubs(self: *const puzzle) bool {
        var sub: usize = 0;

        while (sub < 9) {
            var sequence: [9]i16 = undefined;
            var seq_idx: usize = 0; // Add a new counter for sequence
            var sub_row: usize = 0;
            while (sub_row < 3) {
                var sub_col: usize = 0;
                while (sub_col < 3) {
                    sequence[seq_idx] = @enumToInt(self.cell[3 * (sub / 3) + sub_row][3 * (sub % 3) + sub_col].getValue());
                    sub_col += 1;
                    seq_idx += 1;
                }
                sub_row += 1;
            }

            if (false == self.checkSequence(&sequence)) {
                return false;
            }
            sub += 1;
        }

        return true;
    }

    fn checkEmptyVals(self: *const puzzle) puzzle_state {
        var count: usize = 0;

        for (self.cell) |row| {
            for (row) |element| {
                var value = validateBitMask(@enumToInt(element.getValue()));
                if (value == cand_state.no_candidates) {
                    count += 1;
                } else if (value == cand_state.invalid) {
                    return puzzle_state.invalid;
                }
            }
        }
        if (count == 0) {
            return puzzle_state.solved;
        }

        return puzzle_state.not_solved;
    }

    fn checkPuzzle(self: *const puzzle) puzzle_state {
        var result = self.checkEmptyVals();
        if (!(self.checkCols() and self.checkRows() and self.checkSubs())) {
            result = puzzle_state.invalid;
        }

        return result;
    }

    fn generateRowMasks(self: *puzzle) usize {
        var row: usize = 0;
        var count: usize = 0;

        while (row < 9) {
            var col: usize = 0;
            var mask: i16 = 0;

            var old_mask = self.row_cand[row];

            while (col < 9) {
                mask |= @enumToInt(self.cell[row][col].getValue());
                col += 1;
            }

            self.row_cand[row] = @enumToInt(cell_values.value_mask) & ~mask;

            if (self.row_cand[row] != old_mask) {
                count += 1;
            }
            row += 1;
        }
        return count;
    }

    fn generateColMasks(self: *puzzle) usize {
        var col: usize = 0;
        var count: usize = 0;

        while (col < 9) {
            var row: usize = 0;
            var mask: i16 = 0;

            var old_mask = self.col_cand[col];

            while (row < 9) {
                mask |= @enumToInt(self.cell[row][col].getValue());
                row += 1;
            }

            self.col_cand[col] = @enumToInt(cell_values.value_mask) & ~mask;

            if (self.col_cand[col] != old_mask) {
                count += 1;
            }
            col += 1;
        }
        return count;
    }

    fn generateSubMasks(self: *puzzle) usize {
        var count: usize = 0;
        var sub: usize = 0;
        while (sub < 9) {
            var sub_row: usize = 0;

            var mask: i16 = 0;
            var old_mask = self.sub_cand[sub];

            while (sub_row < 3) {
                var sub_col: usize = 0;

                while (sub_col < 3) {
                    mask |= @enumToInt(self.cell[3 * (sub / 3) + sub_row][3 * (sub % 3) + sub_col].getValue());
                    sub_col += 1;
                }

                sub_row += 1;
            }

            self.sub_cand[sub] = @enumToInt(cell_values.value_mask) & ~mask;

            if (self.sub_cand[sub] != old_mask) {
                count += 1;
            }

            sub += 1;
        }

        return count;
    }

    fn generateCellMask(self: *puzzle) usize {
        var count: usize = 0;
        var row: usize = 0;
        while (row < 9) {
            var col: usize = 0;
            while (col < 9) {
                var old_mask: i16 = self.cell[row][col].getCandidate();
                var mask = self.col_cand[col] & self.row_cand[row] & self.sub_cand[3 * (row / 3) + (col / 3)] & old_mask;

                self.cell[row][col].setCandidate(mask);
                if (old_mask != mask) {
                    count += 1;
                }
                col += 1;
            }
            row += 1;
        }

        return count;
    }

    fn updateCells(self: *puzzle) usize {
        var count: usize = 0;
        var row: usize = 0;

        while (row < 9) {
            var col: usize = 0;
            while (col < 9) {
                if ((self.cell[row][col].getValue() == cell_values.no_value) and (cand_state.one_candidate == validateBitMask(self.cell[row][col].getCandidate()))) {
                    self.cell[row][col].setValue(@intToEnum(cell_values, self.cell[row][col].getCandidate()));
                    self.cell[row][col].setCandidate(@enumToInt(cell_values.no_value));
                    count += 1;
                }

                col += 1;
            }
            row += 1;
        }

        return count;
    }

    fn generateMasks(self: *puzzle) usize {
        var count: usize = 0;

        count += self.generateColMasks();
        count += self.generateRowMasks();
        count += self.generateSubMasks();
        count += self.generateCellMask();

        return count;
    }

    fn prunePuzzle(self: *puzzle) puzzle_state {
        var count: usize = 1;

        while (count != 0) {
            count = self.generateMasks();
            count += self.updateCells();
        }

        return self.checkPuzzle();
    }

    fn selectCandidate(self: *puzzle, row: *usize, col: *usize, val: *i16) bool {
        val.* = -1;
        var cand: usize = 2;

        while (cand <= 9) {
            row.* = 0;
            while (row.* < 9) {
                col.* = 0;
                while (col.* < 9) {
                    if (@popCount(self.cell[row.*][col.*].getCandidate()) == cand) {
                        val.* = @ctz(self.cell[row.*][col.*].getCandidate()) + 1;
                        return true;
                    }
                    col.* += 1;
                }
                row.* += 1;
            }
            cand += 1;
        }
        return false; // No candidate found
    }

    fn solve(self: *puzzle) bool {
        var status = self.prunePuzzle();

        while (status == puzzle_state.not_solved) {
            var row: usize = undefined;
            var col: usize = undefined;
            var val: i16 = undefined;

            var p: puzzle = self.*;
            if (self.selectCandidate(&row, &col, &val)) {
                p.setValue(row, col, val);

                if (p.solve()) {
                    self.* = p; // overwrite current puzzle
                    status = puzzle_state.solved;
                } else {
                    self.removeCandidate(row, col, @intCast(u5, val));
                    status = self.prunePuzzle();
                }
            }
        }

        return switch (status) {
            puzzle_state.solved => true,
            else => false,
        };
    }
};

test "cell testing" {
    var c = cell.init();
    try std.testing.expectEqual(@intCast(i16, @enumToInt(cell_values.value_mask)), c.cand);

    try std.testing.expectEqual(@intCast(i16, @enumToInt(cell_values.value_mask)), c.getCandidate());

    try std.testing.expectEqual(cell_values.no_value, c.getValue());

    c.setValue(cell_values.value_1);
    c.setCandidate(1);
    try std.testing.expectEqual(cell_values.value_1, c.getValue());
    try std.testing.expectEqual(@intCast(i16, 1), c.getCandidate());
}

test "getter and setters" {
    var p = puzzle.init();

    p.setValue(1, 1, 1);

    try std.testing.expectEqual(p.cell[1][1].value, cell_values.value_1);
    try std.testing.expectEqual(p.getValue(1, 1), 1);

    p.setValue(1, 1, 2);

    try std.testing.expectEqual(p.cell[1][1].value, cell_values.value_2);
    try std.testing.expectEqual(p.getValue(1, 1), 2);
}

test "get candidates" {
    var p = puzzle.init();

    try std.testing.expectEqual(@intCast(i16, @enumToInt(cell_values.value_mask)), p.cell[0][0].getCandidate());
}

test "remove candidates" {
    var p = puzzle.init();

    try std.testing.expectEqual(@intCast(i16, @enumToInt(cell_values.value_mask)), p.cell[0][0].getCandidate());

    p.removeCandidate(0, 0, 1);
    try std.testing.expectEqual(@intCast(i16, 0x1FE), p.cell[0][0].getCandidate());

    p.removeCandidate(0, 0, 2);
    try std.testing.expectEqual(@intCast(i16, 0x1FC), p.cell[0][0].getCandidate());
}

test "string_import" {
    const test_string: []const u8 = "974236158638591742125487936316754289742918563589362417867125394253649871491873625";

    var p = puzzle.init();
    p.import(test_string);
    try std.testing.expectEqual(p.getValue(0, 0), 9);
    try std.testing.expectEqual(p.getValue(0, 1), 7);
    try std.testing.expectEqual(p.getValue(8, 8), 5);
}

const valid_test_puzzles: []const []const u8 = &[_][]const u8{
    "974236158638591742125487936316754289742918563589362417867125394253649871491873625", // Already solved puzzle
    "2564891733746159829817234565932748617128.6549468591327635147298127958634849362715", // Almost solved puzzle. One Element left
    "3.542.81.4879.15.6.29.5637485.793.416132.8957.74.6528.2413.9.655.867.192.965124.8", // Almost solved puzzle. Naked Singles
    "..2.3...8.....8....31.2.....6..5.27..1.....5.2.4.6..31....8.6.5.......13..531.4..", // Solvable puzzle. Hidden Singles
};

const invalid_test_puzzles: []const []const u8 = &[_][]const u8{
    "11...............................................................................", // Invalid puzzle. Same Row
    "1........1.......................................................................", // Invalid puzzle. Same Column
    "1.........1.........1............................................................", // Invalid puzzle. Same Subgrid
    "534678912672195348198342567859761423426853791713924856961537284287119635345286179", // Invalid puzzle
};

test "round trip inport/export string" {
    var p = puzzle.init();

    for (valid_test_puzzles) |test_string| {
        p.import(test_string);

        try std.testing.expect(std.mem.eql(u8, test_string, p.exportAsString()));
        try std.testing.expectEqual(test_string.len, p.exportAsString().len);
        try std.testing.expectEqual(@intCast(usize, 81), test_string.len);
    }
}

test "validate masks" {
    try std.testing.expectEqual(cand_state.no_candidates, validateBitMask(0x0));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_1)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_2)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_3)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_4)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_5)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_6)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_7)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_8)));
    try std.testing.expectEqual(cand_state.one_candidate, validateBitMask(@enumToInt(cell_values.value_9)));
    try std.testing.expectEqual(cand_state.several_candidates, validateBitMask(0x3));
}

test "convert mask to value" {
    try std.testing.expectEqual(@intCast(i16, 1), convertBitMaskToValue(@enumToInt(cell_values.value_1)));
    try std.testing.expectEqual(@intCast(i16, 2), convertBitMaskToValue(@enumToInt(cell_values.value_2)));
    try std.testing.expectEqual(@intCast(i16, 3), convertBitMaskToValue(@enumToInt(cell_values.value_3)));
    try std.testing.expectEqual(@intCast(i16, 4), convertBitMaskToValue(@enumToInt(cell_values.value_4)));
    try std.testing.expectEqual(@intCast(i16, 5), convertBitMaskToValue(@enumToInt(cell_values.value_5)));
    try std.testing.expectEqual(@intCast(i16, 6), convertBitMaskToValue(@enumToInt(cell_values.value_6)));
    try std.testing.expectEqual(@intCast(i16, 7), convertBitMaskToValue(@enumToInt(cell_values.value_7)));
    try std.testing.expectEqual(@intCast(i16, 8), convertBitMaskToValue(@enumToInt(cell_values.value_8)));
    try std.testing.expectEqual(@intCast(i16, 9), convertBitMaskToValue(@enumToInt(cell_values.value_9)));
    try std.testing.expectEqual(@intCast(i16, 0), convertBitMaskToValue(@enumToInt(cell_values.no_value)));
    try std.testing.expectEqual(@intCast(i16, -1), convertBitMaskToValue(@enumToInt(cell_values.value_mask)));
    try std.testing.expectEqual(@intCast(i16, -1), convertBitMaskToValue(0x3));
}

test "convert value to mask" {
    try std.testing.expectEqual(cell_values.value_1, convertValueToBitMask(@intCast(i16, 1)));
    try std.testing.expectEqual(cell_values.value_2, convertValueToBitMask(@intCast(i16, 2)));
    try std.testing.expectEqual(cell_values.value_3, convertValueToBitMask(@intCast(i16, 3)));
    try std.testing.expectEqual(cell_values.value_4, convertValueToBitMask(@intCast(i16, 4)));
    try std.testing.expectEqual(cell_values.value_5, convertValueToBitMask(@intCast(i16, 5)));
    try std.testing.expectEqual(cell_values.value_6, convertValueToBitMask(@intCast(i16, 6)));
    try std.testing.expectEqual(cell_values.value_7, convertValueToBitMask(@intCast(i16, 7)));
    try std.testing.expectEqual(cell_values.value_8, convertValueToBitMask(@intCast(i16, 8)));
    try std.testing.expectEqual(cell_values.value_9, convertValueToBitMask(@intCast(i16, 9)));
    try std.testing.expectEqual(cell_values.no_value, convertValueToBitMask(@intCast(i16, 0)));
    try std.testing.expectEqual(cell_values.invalid, convertValueToBitMask(@intCast(i16, -1)));
}

test "Check for repeated values in row" {
    var p = puzzle.init();

    try std.testing.expect(true == p.checkRows());

    p.setValue(1, 0, 1);
    p.setValue(1, 1, 2);
    p.setValue(1, 2, 3);
    p.setValue(1, 3, 4);
    p.setValue(1, 4, 5);
    p.setValue(1, 5, 6);
    p.setValue(1, 6, 7);
    p.setValue(1, 7, 8);
    p.setValue(1, 8, 9);

    try std.testing.expectEqual(p.getValue(1, 0), 1);
    try std.testing.expectEqual(p.getValue(1, 1), 2);
    try std.testing.expectEqual(p.getValue(1, 2), 3);
    try std.testing.expectEqual(p.getValue(1, 3), 4);
    try std.testing.expectEqual(p.getValue(1, 4), 5);
    try std.testing.expectEqual(p.getValue(1, 5), 6);
    try std.testing.expectEqual(p.getValue(1, 6), 7);
    try std.testing.expectEqual(p.getValue(1, 7), 8);
    try std.testing.expectEqual(p.getValue(1, 8), 9);
    try std.testing.expect(true == p.checkRows());

    p.setValue(1, 3, 1);

    try std.testing.expect(false == p.checkRows());
}

test "Check for repeated values in columns" {
    var p = puzzle.init();

    try std.testing.expect(true == p.checkCols());

    p.setValue(0, 1, 1);
    p.setValue(1, 1, 2);
    p.setValue(2, 1, 3);
    p.setValue(3, 1, 4);
    p.setValue(4, 1, 5);
    p.setValue(5, 1, 6);
    p.setValue(6, 1, 7);
    p.setValue(7, 1, 8);
    p.setValue(8, 1, 9);

    try std.testing.expect(true == p.checkCols());

    p.setValue(3, 1, 1);

    try std.testing.expect(false == p.checkCols());
}

test "Check for repeated values in subgrids" {
    var p = puzzle.init();

    try std.testing.expect(true == p.checkSubs());

    p.setValue(0, 0, 1);
    p.setValue(0, 1, 2);
    p.setValue(0, 2, 3);
    p.setValue(1, 0, 4);
    p.setValue(1, 1, 5);
    p.setValue(1, 2, 6);
    p.setValue(2, 0, 7);
    p.setValue(2, 1, 8);
    p.setValue(2, 2, 9);

    try std.testing.expect(true == p.checkSubs());

    p.setValue(2, 2, 1);

    try std.testing.expect(false == p.checkSubs());
}

test "check valid puzzles" {
    var p = puzzle.init();

    for (valid_test_puzzles) |test_string| {
        p.import(test_string);

        try std.testing.expect(puzzle_state.invalid != p.checkPuzzle());
    }
}

test "check invalid puzzles" {
    var p = puzzle.init();

    try std.testing.expectEqual(puzzle_state.not_solved, p.checkPuzzle());

    for (invalid_test_puzzles) |test_string| {
        p.import(test_string);

        try std.testing.expect(puzzle_state.invalid == p.checkPuzzle());
    }
}

test "check for empty cells" {
    var p = puzzle.init();
    p.import(valid_test_puzzles[0]);

    try std.testing.expectEqual(puzzle_state.solved, p.checkEmptyVals());

    p.import(valid_test_puzzles[1]);

    try std.testing.expectEqual(puzzle_state.not_solved, p.checkEmptyVals());

    p.import(valid_test_puzzles[2]);

    try std.testing.expectEqual(puzzle_state.not_solved, p.checkEmptyVals());

    p.import(valid_test_puzzles[3]);

    try std.testing.expectEqual(puzzle_state.not_solved, p.checkEmptyVals());
}

test "generate mask tests" {
    var p = puzzle.init();

    try std.testing.expectEqual(@intCast(usize, 0), p.generateRowMasks());
    try std.testing.expectEqual(@intCast(usize, 0), p.generateColMasks());

    // Modifying two columns and one row inside the two subgrid
    p.setValue(0, 0, 1);
    p.setValue(0, 3, 2);

    // First run
    try std.testing.expectEqual(@intCast(usize, 1), p.generateRowMasks());
    try std.testing.expectEqual(@intCast(usize, 2), p.generateColMasks());
    try std.testing.expectEqual(@intCast(usize, 2), p.generateSubMasks());
    try std.testing.expect(0 < p.generateCellMask());
    // second run
    try std.testing.expectEqual(@intCast(usize, 0), p.generateRowMasks());
    try std.testing.expectEqual(@intCast(usize, 0), p.generateColMasks());
    try std.testing.expectEqual(@intCast(usize, 0), p.generateSubMasks());
    try std.testing.expectEqual(@intCast(usize, 0), p.generateCellMask());
}

test "update cells" {
    var p = puzzle.init();

    p.setValue(0, 0, 1);
    p.setValue(0, 1, 2);
    p.setValue(0, 2, 3);
    p.setValue(0, 3, 4);

    //p.set_value(0, 4, 5);

    p.setValue(0, 5, 6);

    p.setValue(0, 6, 7);

    p.setValue(0, 7, 8);

    p.setValue(0, 8, 9);
    try std.testing.expectEqual(puzzle_state.not_solved, p.checkPuzzle());
    try std.testing.expectEqual(puzzle_state.not_solved, p.prunePuzzle());
    try std.testing.expect(5 == p.getValue(0, 4));
}

test "Solve simple puzzles" {
    var p = puzzle.init();

    p.import(valid_test_puzzles[0]);

    try std.testing.expectEqual(puzzle_state.solved, p.prunePuzzle());

    // pruning solves this simple puzzle
    p.import(valid_test_puzzles[1]);
    try std.testing.expectEqual(puzzle_state.solved, p.prunePuzzle());

    // pruning solves this simple puzzle (naked singles)
    p.import(valid_test_puzzles[2]);
    try std.testing.expectEqual(puzzle_state.solved, p.prunePuzzle());

    // pruning is not enough for this puzzle (hidden singles)
    p.import(valid_test_puzzles[3]);
    try std.testing.expectEqual(puzzle_state.not_solved, p.prunePuzzle());
}

test "Select Candidates" {
    var p = puzzle.init();

    var row: usize = 0;
    var col: usize = 0;
    var val: i16 = 0;
    try std.testing.expect(9 == @popCount(p.cell[0][0].getCandidate()));
    try std.testing.expect(true == p.selectCandidate(&row, &col, &val));
    try std.testing.expect((0 == row) and (0 == col) and (1 == val));

    p.setValue(0, 0, 1);
    try std.testing.expect(puzzle_state.not_solved == p.prunePuzzle());
    try std.testing.expect(true == p.selectCandidate(&row, &col, &val));
    try std.testing.expect((0 == row) and (1 == col) and (2 == val));

    p.setValue(0, 1, 2);
    try std.testing.expect(puzzle_state.not_solved == p.prunePuzzle());
    try std.testing.expect(true == p.selectCandidate(&row, &col, &val));
    try std.testing.expect((0 == row) and (2 == col) and (3 == val));

    p.import(valid_test_puzzles[2]);
    try std.testing.expect(puzzle_state.solved == p.prunePuzzle());
    try std.testing.expect(false == p.selectCandidate(&row, &col, &val));
}

test "solve valid sudoku" {
    var p = puzzle.init();

    for (invalid_test_puzzles) |test_string| {
        p.import(test_string);

        try std.testing.expect(!p.solve());
    }
}

test "solve invalid sudoku" {
    var p = puzzle.init();

    for (valid_test_puzzles) |test_string| {
        p.import(test_string);

        try std.testing.expect(p.solve());
    }
}
