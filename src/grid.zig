const std = @import("std");
const cell = @import("cell.zig");
const testing = std.testing;

pub const cellValues = cell.cellValues;
pub const cellError = cell.cellError;

values: [9][9]cell,
row_cand: [9]cell,
col_cand: [9]cell,
sub_cand: [3][3]cell,

const candidateType = enum(usize) {
    GRID_CELL,
    ROW_CELL,
    COL_CELL,
    SUB_GRID_CELL,
};

/// Returns an initialized grid
pub fn init() @This() {
    var self: @This() = undefined;

    for (0..9) |i| {
        for (0..9) |j| {
            self.values[i][j] = cell.init();
        }
    }
    for (0..9) |i| {
        self.row_cand[i] = cell.init();
        self.col_cand[i] = cell.init();
    }
    for (0..3) |i| {
        for (0..3) |j| {
            self.sub_cand[i][j] = cell.init();
        }
    }
    return self;
}

/// Get the value of a cell
pub fn getValue(self: *@This(), row: usize, col: usize) !?cellValues {
    return self.values[row][col].getValue();
}

/// Get the value of a cell as an integer
pub fn getValueAsInt(self: *@This(), row: usize, col: usize) !u8 {
    return self.values[row][col].getValueAsInt();
}

/// Set the value of a cell
pub fn setValue(self: *@This(), row: usize, col: usize, value: cellValues) !void {
    return self.values[row][col].setValue(value);
}

/// Set the value of a cell from an integer
pub fn setValueFromInt(self: *@This(), row: usize, col: usize, value: u8) !void {
    return self.values[row][col].setValueFromInt(value);
}

/// Count candidates in the corresponding mask
pub fn countCandidates(self: *@This(), selector: candidateType, row: ?usize, col: ?usize) usize {
    return switch (selector) {
        .GRID_CELL => self.values[row.?][col.?].countCandidates(),
        .ROW_CELL => self.row_cand[row.?].countCandidates(),
        .COL_CELL => self.col_cand[col.?].countCandidates(),
        .SUB_GRID_CELL => self.sub_cand[row.?][col.?].countCandidates(),
    };
}

/// Remove candidates on the bitmask
/// To be used to remove candidates from the bitmask
pub fn removeCandidate(self: *@This(), selector: candidateType, row: ?usize, col: ?usize, cand: cellValues) void {
    return switch (selector) {
        .GRID_CELL => self.values[row.?][col.?].removeCandidate(cand),
        .ROW_CELL => unreachable, //.row_cand[row.?].removeCandidate(cand),
        .COL_CELL => unreachable, //self.col_cand[col.?].removeCandidate(cand),
        .SUB_GRID_CELL => unreachable, //self.sub_cand[row.?][col.?].removeCandidate(cand),
    };
}

/// Generate new value mask for the desired cell
fn valueMask(self: *@This(), row: usize, col: usize) !usize {
    const prevMask = self.values[row][col].getValueMask();

    if (null == try self.values[row][col].getValue()) {
        self.values[row][col].value &= (self.row_cand[row].getValueMask() & self.col_cand[col].getValueMask() & self.sub_cand[row / 3][col / 3].getValueMask());
    }
    return @intFromBool(prevMask != self.values[row][col].getValueMask());
}

/// Generate value masks for the whole grid
fn valueMaskInGrid(self: *@This()) !usize {
    var changeCount: usize = 0;

    for (0..9) |i| {
        for (0..9) |j| {
            changeCount += try self.valueMask(i, j);
        }
    }

    return changeCount;
}

/// Generate row mask
///
/// Returns true if row mask changed
fn rowMask(self: *@This(), row: usize) !usize {
    const prevMask = self.row_cand[row].getValueMask(); // previous mask

    self.row_cand[row] = cell.init(); // Reset the row mask

    for (0..9) |i| {
        if (try self.values[row][i].getValue()) |val| {
            self.row_cand[row].removeCandidate(val);
        }
    }

    return @as(usize, @intFromBool((prevMask != self.row_cand[row].getValueMask())));
}

/// Generate col mask
///
/// Returns true if col mask changed
fn colMask(self: *@This(), col: usize) !usize {
    const prevMask = self.col_cand[col].getValueMask(); // previous mask

    self.col_cand[col] = cell.init(); // Reset the col mask

    for (0..9) |i| {
        if (try self.values[i][col].getValue()) |val| {
            self.col_cand[col].removeCandidate(val);
        }
    }

    return @as(usize, @intFromBool((prevMask != self.col_cand[col].getValueMask())));
}

/// Generate subgrid mask
/// Returns true if subgrid mask changed
fn subMask(self: *@This(), subRow: usize, subCol: usize) !usize {
    const prevMask = self.sub_cand[subRow][subCol].getValueMask();

    self.sub_cand[subRow][subCol] = cell.init();

    for (0..3) |i| {
        for (0..3) |j| {
            if (try self.values[i + (3 * subRow)][j + (3 * subCol)].getValue()) |val| {
                self.sub_cand[subRow][subCol].removeCandidate(val);
            }
        }
    }

    return @as(usize, @intFromBool((prevMask != self.sub_cand[subRow][subCol].getValueMask())));
}

/// Generate subgrid masks for the whole grid
fn subMaskInGrid(self: *@This()) !usize {
    var changeCount: usize = 0;

    for (0..3) |i| {
        for (0..3) |j| {
            changeCount += try self.subMask(i, j);
        }
    }
    return changeCount;
}

/// Generate row masks for the whole grid
fn rowMaskInGrid(self: *@This()) !usize {
    var changeCount: usize = 0;

    for (0..9) |i| {
        changeCount += try self.rowMask(i);
    }

    return changeCount;
}

/// Generate col masks for the whole grid
fn colMaskInGrid(self: *@This()) !usize {
    var changeCount: usize = 0;

    for (0..9) |i| {
        changeCount += try self.colMask(i);
    }

    return changeCount;
}

/// Generate all masks for the whole grid
pub fn generateMasks(self: *@This()) !void {
    var changeCount: usize = 1;

    while (changeCount != 0) {
        // Update Auxiliary Masks
        changeCount = try self.colMaskInGrid() + try self.rowMaskInGrid() + try self.subMaskInGrid();

        // Update value masks
        changeCount += try self.valueMaskInGrid();
    }
}

/// Check if a value is a candidate in the corresponding mask
fn checkRow(self: *@This(), row: usize) !void {
    var checkMask = cell{ .value = 0 };

    for (0..9) |i| {
        if (try self.values[row][i].getValue()) |val| {
            try checkMask.checkAndAddCandidate(val);
        }
    }
}

/// Check if a value is a candidate in the corresponding mask
fn checkCol(self: *@This(), col: usize) !void {
    var checkMask = cell{ .value = 0 };

    for (0..9) |i| {
        if (try self.values[i][col].getValue()) |val| {
            try checkMask.checkAndAddCandidate(val);
        }
    }
}

/// Check if a value is a candidate in the corresponding mask
/// subRow and subCol are the coordinates of the subgrid
fn checkSub(self: *@This(), subRow: usize, subCol: usize) !void {
    var checkMask = cell{ .value = 0 };

    for (0..3) |i| {
        for (0..3) |j| {
            if (try self.values[3 * subRow + i][3 * subCol + j].getValue()) |val| {
                try checkMask.checkAndAddCandidate(val);
            }
        }
    }
}

/// Check all rows in the grid
fn checkRowsInGrid(self: *@This()) !void {
    for (0..9) |i| {
        try self.checkRow(i);
    }
}

/// Check all columns in the grid
fn checkColsInGrid(self: *@This()) !void {
    for (0..9) |i| {
        try self.checkCol(i);
    }
}

/// Check all subgrids in the grid
fn checkSubInGrid(self: *@This()) !void {
    for (0..3) |i| {
        for (0..3) |j| {
            try self.checkSub(i, j);
        }
    }
}

/// Check if the puzzle is valid and solved
pub fn checkPuzzle(self: *@This()) !bool {
    try self.checkRowsInGrid();
    try self.checkColsInGrid();
    try self.checkSubInGrid();

    return try self.isSolved();
}

/// Count for solved cells in the grid
pub fn countSolvedCells(self: *@This()) !usize {
    var valueCount: usize = 0;

    for (0..9) |i| {
        for (0..9) |j| {
            if (try self.values[i][j].getValue()) |_| {
                valueCount += 1;
            }
        }
    }

    return valueCount;
}

/// Check if the puzzle is solved
pub fn isSolved(self: *@This()) !bool {
    return (81 == try self.countSolvedCells());
}

/// Get the first and last candidates in a cell
pub fn getFirstAndLastCandidates(self: *@This(), row: usize, col: usize) !struct { a: cellValues, b: cellValues } {
    const ret = try self.values[row][col].getFirstAndLastCandidates();
    return .{ .a = ret.a, .b = ret.b };
}

test "init" {
    var grid = @This().init();

    try testing.expect(null == try grid.getValue(0, 0));

    try grid.setValue(0, 1, .VALUE_5);

    try testing.expect(cellValues.VALUE_5 == try grid.getValue(0, 1));
}

test "Count Candidates" {
    var grid = @This().init();

    try testing.expect(9 == grid.countCandidates(.GRID_CELL, 0, 0));
    for (0..(grid.row_cand.len)) |i| {
        try testing.expect(9 == grid.countCandidates(.ROW_CELL, i, null));
    }
    for (0..(grid.col_cand.len)) |i| {
        try testing.expect(9 == grid.countCandidates(.COL_CELL, null, i));
    }

    grid.removeCandidate(.GRID_CELL, 0, 0, .VALUE_1);
    try testing.expect(8 == grid.countCandidates(.GRID_CELL, 0, 0));
}

test "Test the row mask" {
    var grid = @This().init();

    try testing.expect(0 == try grid.rowMask(0));

    try testing.expect(null == try grid.getValue(0, 1));

    try grid.setValue(0, 1, .VALUE_1);

    try testing.expect(.VALUE_1 == try grid.getValue(0, 1));
    try testing.expect(1 == try grid.rowMask(0));
    try testing.expect(1 == grid.countCandidates(.GRID_CELL, 0, 1));
    try testing.expect(8 == grid.countCandidates(.ROW_CELL, 0, null));

    try grid.setValue(0, 2, .VALUE_2);
    try testing.expect(1 == try grid.rowMask(0));
    try testing.expect(7 == grid.countCandidates(.ROW_CELL, 0, null));
}

test "Test the first subgrid mask" {
    var grid = @This().init();

    try grid.setValue(0, 0, .VALUE_1);
    try grid.setValue(0, 1, .VALUE_2);
    try grid.setValue(0, 2, .VALUE_3);

    try grid.setValue(1, 0, .VALUE_4);
    try grid.setValue(1, 1, .VALUE_5);
    try grid.setValue(1, 2, .VALUE_6);

    try grid.setValue(2, 0, .VALUE_7);
    try grid.setValue(2, 1, .VALUE_8);
    try grid.setValue(2, 2, .VALUE_9);

    try grid.checkSubInGrid();
    try grid.generateMasks();

    // No elements left in mask
    try testing.expectEqual(@as(usize, 0), grid.sub_cand[0][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][2].getValueMask());

    try grid.setValue(0, 0, .VALUE_2);
    try grid.generateMasks();

    // One value is candidate, even with repeated values (!)
    try testing.expectEqual(@as(usize, 1), grid.sub_cand[0][0].getValueMask());

    try testing.expectError(cellError.invalid_value, grid.checkSubInGrid());
}

test "Test the second subgrid mask" {
    var grid = @This().init();

    try grid.setValue(0, 3, .VALUE_1);
    try grid.setValue(0, 4, .VALUE_2);
    try grid.setValue(0, 5, .VALUE_3);

    try grid.setValue(1, 3, .VALUE_4);
    try grid.setValue(1, 4, .VALUE_5);
    try grid.setValue(1, 5, .VALUE_6);

    try grid.setValue(2, 3, .VALUE_7);
    try grid.setValue(2, 4, .VALUE_8);
    try grid.setValue(2, 5, .VALUE_9);

    try grid.checkSubInGrid();
    try grid.generateMasks();

    // No elements left in mask
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][0].getValueMask());
    try testing.expectEqual(@as(usize, 0), grid.sub_cand[0][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][2].getValueMask());

    // Reset this value
    try grid.setValue(1, 4, .VALUE_INITIAL);
    try grid.checkSubInGrid();
    try grid.generateMasks();
    try grid.checkSubInGrid();
    try testing.expectEqual(@as(usize, 0), grid.sub_cand[0][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_5)), grid.values[1][4].value);
}

test "Test the third subgrid mask" {
    var grid = @This().init();

    try grid.setValue(0, 6, .VALUE_1);
    try grid.setValue(0, 7, .VALUE_2);
    try grid.setValue(0, 8, .VALUE_3);

    try grid.setValue(1, 6, .VALUE_4);
    try grid.setValue(1, 7, .VALUE_5);
    try grid.setValue(1, 8, .VALUE_6);

    try grid.setValue(2, 6, .VALUE_7);
    try grid.setValue(2, 7, .VALUE_8);
    try grid.setValue(2, 8, .VALUE_9);

    try grid.checkSubInGrid();
    try grid.generateMasks();

    // No elements left in mask
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][0].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[0][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][1].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][1].getValueMask());
    try testing.expectEqual(@as(usize, 0), grid.sub_cand[0][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[1][2].getValueMask());
    try testing.expectEqual(@as(usize, @intFromEnum(cellValues.VALUE_INITIAL)), grid.sub_cand[2][2].getValueMask());
}
test "Test simple puzzle check" {
    var grid = @This().init();

    _ = try grid.checkPuzzle();

    try grid.setValue(0, 0, .VALUE_1);
    try grid.setValue(0, 3, .VALUE_1);
    grid.checkRowsInGrid() catch |err| {
        try testing.expect(err == cell.cellError.invalid_value);
    };
    try grid.checkColsInGrid();
    try grid.checkSubInGrid();
}
