// Cell API
const std = @import("std");

pub const cellError = error{
    invalid_value,
};

const cellBitmaskType = if (@bitSizeOf(usize) >= 64) u64 else u32;

/// Invalid Value
const VALUE_INVALID: u32 = 0;

/// Cell Values Mask
pub const cellValues = enum(u32) {
    VALUE_1 = (1 << 0),
    VALUE_2 = (1 << 1),
    VALUE_3 = (1 << 2),
    VALUE_4 = (1 << 3),
    VALUE_5 = (1 << 4),
    VALUE_6 = (1 << 5),
    VALUE_7 = (1 << 6),
    VALUE_8 = (1 << 7),
    VALUE_9 = (1 << 8),
    VALUE_INITIAL = (0x1FF),

    // Is the current bitmask a valid value?
    pub fn isValue(val: u32) !?@This() {
        if (@popCount(val) == 1) {
            return @enumFromInt(val);
        } else if (val == VALUE_INVALID) {
            return cellError.invalid_value;
        } else {
            return null;
        }
        unreachable;
    }

    // Converts the enum into an int
    pub fn intFromValue(val: ?@This()) u8 {
        if (val) |v| {
            if (v != .VALUE_INITIAL) {
                return @ctz(@intFromEnum(v)) + 1;
            }
        }
        return 0;
    }

    /// Converts an integer into a value
    pub fn getValueFromInt(val: u8) !@This() {
        if (val == 0) {
            return .VALUE_INITIAL;
        } else if ((val >= 1) and (val <= 9)) {
            return @enumFromInt(std.math.shl(usize, 1, @as(u5, @intCast(val)) - 1));
        } else {
            return cellError.invalid_value;
        }
    }
};

value: u32,

/// Check if the cellValue is a candidate in the cell
pub fn isCandidate(self: *const @This(), value: cellValues) bool {
    return ((self.value & @intFromEnum(value)) == @intFromEnum(value));
}

/// Removes a candidate from the cell bitmask
pub fn removeCandidate(self: *@This(), value: cellValues) void {
    self.value = self.value & ~@intFromEnum(value);
}

/// Add a candidate to the cell bitmask
pub fn addCandidate(self: *@This(), value: cellValues) void {
    self.value = self.value | @intFromEnum(value);
}

/// Check if the value is a candidate and add it to the cell
pub fn checkAndAddCandidate(self: *@This(), value: cellValues) cellError!void {
    if (self.isCandidate(value)) {
        return cellError.invalid_value;
    } else {
        self.addCandidate(value);
    }
}

/// Set value of a cell to the given cell value
pub fn setValue(self: *@This(), value: cellValues) void {
    self.value = @intFromEnum(value);
}

/// Get the current cell value
///
/// - Returns `null` if the cell is not a value
/// - Returns the value if the cell is a value
/// - Returns an error if the cell is invalid
pub fn getValue(self: *const @This()) !?cellValues {
    return cellValues.isValue(self.value);
}

/// Set value from integer
pub fn setValueFromInt(self: *@This(), val: u8) !void {
    self.setValue(try cellValues.getValueFromInt(val));
}

/// Get a cell value as integer
pub fn getValueAsInt(self: *const @This()) !u8 {
    return cellValues.intFromValue(try cellValues.isValue(self.value));
}

/// Count the candidates in the cell mask
pub fn countCandidates(self: *const @This()) usize {
    return @popCount(self.value);
}

/// Get the value mask of a cell
pub fn getValueMask(self: *const @This()) u32 {
    return self.value;
}

/// Get the first and last candidates in a cell
pub fn getFirstAndLastCandidates(self: *const @This()) !struct { a: cellValues, b: cellValues } {
    const first = try cellValues.getValueFromInt(@clz(@as(u32, 0)) - @clz(self.value));
    const last = try cellValues.getValueFromInt((@ctz(self.value) + 1));

    return .{ .a = first, .b = last };
}

/// Initializes the cell to its default state.
pub fn init() @This() {
    return @This(){ .value = @intFromEnum(cellValues.VALUE_INITIAL) };
}

const testing = @import("std").testing;

test "Test values" {
    try testing.expect(cellValues.VALUE_1 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_1)));
    try testing.expect(cellValues.VALUE_2 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_2)));
    try testing.expect(cellValues.VALUE_3 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_3)));
    try testing.expect(cellValues.VALUE_4 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_4)));
    try testing.expect(cellValues.VALUE_5 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_5)));
    try testing.expect(cellValues.VALUE_6 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_6)));
    try testing.expect(cellValues.VALUE_7 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_7)));
    try testing.expect(cellValues.VALUE_8 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_8)));
    try testing.expect(cellValues.VALUE_9 == try cellValues.isValue(@intFromEnum(cellValues.VALUE_9)));

    try testing.expect(null == try cellValues.isValue(0x3));

    _ = cellValues.isValue(0) catch |err| {
        try testing.expect(cellError.invalid_value == err);
    };
}

test "convert values to integer" {
    try testing.expect(1 == cellValues.intFromValue(.VALUE_1));
    try testing.expect(2 == cellValues.intFromValue(.VALUE_2));
}

test "convert int into value" {
    try testing.expect(.VALUE_1 == try cellValues.getValueFromInt(1));
    try testing.expect(.VALUE_9 == try cellValues.getValueFromInt(9));
    try testing.expect(.VALUE_INITIAL == try cellValues.getValueFromInt(0));

    for (0..255) |val| {
        if (cellValues.getValueFromInt(@intCast(val))) |v| {
            try testing.expect(@as(u8, @intCast(val)) == cellValues.intFromValue(v));
        } else |err| {
            try testing.expect(cellError.invalid_value == err);
        }
    }
    for (0..9) |val| {
        if (cellValues.getValueFromInt(@intCast(val))) |v| {
            try testing.expect(@as(u8, @intCast(val)) == cellValues.intFromValue(v));
        } else |_| {
            unreachable;
        }
    }
    for (10..255) |val| {
        if (cellValues.getValueFromInt(@intCast(val))) |_| {
            unreachable;
        } else |err| {
            try testing.expect(cellError.invalid_value == err);
        }
    }
}

test "Check Bitmap" {
    var cell = @This(){ .value = 0 };

    cell.value = @intFromEnum(cellValues.VALUE_INITIAL);
    try testing.expect(true == cell.isCandidate(.VALUE_1));
    try testing.expect(true == cell.isCandidate(.VALUE_2));
    try testing.expect(true == cell.isCandidate(.VALUE_3));
    try testing.expect(true == cell.isCandidate(.VALUE_4));
    try testing.expect(true == cell.isCandidate(.VALUE_5));
    try testing.expect(true == cell.isCandidate(.VALUE_6));
    try testing.expect(true == cell.isCandidate(.VALUE_7));
    try testing.expect(true == cell.isCandidate(.VALUE_8));
    try testing.expect(true == cell.isCandidate(.VALUE_9));

    // Remove candidate
    cell.value = cell.value & ~@intFromEnum(cellValues.VALUE_5);
    try testing.expect(false == cell.isCandidate(.VALUE_5));
}

test "Count Candidates" {
    var value = @This(){ .value = @intFromEnum(cellValues.VALUE_INITIAL) };

    try testing.expect(value.countCandidates() == 9);

    value.removeCandidate(cellValues.VALUE_1);

    try testing.expect(value.countCandidates() == 8);

    value.setValue(cellValues.VALUE_INITIAL);
    for (1..9) |idx| {
        value.removeCandidate(try cellValues.getValueFromInt(@intCast(idx)));
        try testing.expect((9 - idx) == value.countCandidates());
    }

    value.setValue(.VALUE_1);
    try testing.expect(1 == value.countCandidates());
}

test "First and last elements" {
    var value = @This().init();

    var cand = try value.getFirstAndLastCandidates();

    try testing.expectEqual(cellValues.VALUE_9, cand.a);
    try testing.expectEqual(cellValues.VALUE_1, cand.b);

    value.removeCandidate(.VALUE_9);
    value.removeCandidate(.VALUE_1);

    cand = try value.getFirstAndLastCandidates();

    try testing.expectEqual(cellValues.VALUE_8, cand.a);
    try testing.expectEqual(cellValues.VALUE_2, cand.b);

    value.removeCandidate(.VALUE_8);
    value.removeCandidate(.VALUE_2);
    cand = try value.getFirstAndLastCandidates();

    try testing.expectEqual(cellValues.VALUE_7, cand.a);
    try testing.expectEqual(cellValues.VALUE_3, cand.b);

    value.removeCandidate(.VALUE_7);
    value.removeCandidate(.VALUE_3);
    cand = try value.getFirstAndLastCandidates();

    try testing.expectEqual(cellValues.VALUE_6, cand.a);
    try testing.expectEqual(cellValues.VALUE_4, cand.b);

    value.removeCandidate(.VALUE_6);
    value.removeCandidate(.VALUE_4);
    cand = try value.getFirstAndLastCandidates();

    try testing.expectEqual(cellValues.VALUE_5, cand.a);
    try testing.expectEqual(cellValues.VALUE_5, cand.b);
}
