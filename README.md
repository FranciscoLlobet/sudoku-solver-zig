
# sudoku-solver-zig

[![zig-build](https://github.com/FranciscoLlobet/sudoku-solver-zig/actions/workflows/zig-build.yml/badge.svg)](https://github.com/FranciscoLlobet/sudoku-solver-zig/actions/workflows/zig-build.yml)
![GitHub License](https://img.shields.io/github/license/franciscollobet/sudoku-solver-zig)
![GitHub top language](https://img.shields.io/github/languages/top/franciscollobet/sudoku-solver-zig)

## Sudoku Solver in Zig

Simple Sudoku Solver Library based on the algorithm in [FranciscoLlobet/sudoku-solver](https://github.com/FranciscoLlobet/sudoku-solver).

This library has been written as a `kata` to test the basic features of the [Zig Programming Language](https://www.ziglang.org).

> This project, the repository and author(s) are **not** affiliated with the [Zig Software Foundation](https://ziglang.org/zsf/).

## Installation and Dependencies

To build and test the project, you need to have [Zig](https://ziglang.org/download/) installed. Follow the instructions on the Zig website to install the appropriate version for your system.

## API Usage

> Work-in-progress

```zig
const std = @import("std");
const puzzle = @import("puzzle.zig");

// Example puzzle string
const puzzle_as_string: []const u8 = "..2.3...8.....8....31.2.....6..5.27..1.....5.2.4.6..31....8.6.5.......13..531.4..";

// Provide your memory allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

// Import puzzle from string
var p = try puzzle.importFromString(puzzle_as_string);

// Solve the puzzle
// Returns error if Sudoku cannot be solved
try p.solve(allocator);
```

## Limitations

- Basic error handling
- Basic API
- Public Interface may change in the future

## Building

```shell
zig build
```

## Testing

The testing strategy validates the solving algorithm using:

- Invalid Sudoku puzzles
- Valid and solved Sudoku puzzles
- Naked singles
- Hidden singles

### Unit Tests

Run the unit tests:

```shell
zig build test
```

### Data Tests

Data-based tests will validate the Sudoku solving algorithm. The [`top1465`](http://magictour.free.fr/top1465) data set is considered one of the most comprehensive for testing advanced Sudoku solving algorithms.

> The data sets are currently not included in the repository.

To get the data set, download it from the link or use `curl`. The data set should be stored in the `data` directory.

```shell
curl http://magictour.free.fr/top1465 --output ./data/top1465.txt
```

Run the data tests:

```shell
zig build test
```

## Examples

### Running the Solver

Here is how you can run the solver on different types of puzzles:

1. Create a new puzzle from a string.
2. Solve the puzzle.
3. Handle any errors if the puzzle is unsolvable.

```zig
const std = @import("std");
const puzzle = @import("puzzle.zig");

pub fn main() !void {
    const puzzle_as_string: []const u8 = "..2.3...8.....8....31.2.....6..5.27..1.....5.2.4.6..31....8.6.5.......13..531.4..";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var p = try puzzle.importFromString(puzzle_as_string);

    // Attempt to solve the puzzle
    try p.solve(allocator);

    // If we reach here, the puzzle has been solved
    std.debug.print("Solved puzzle:\n{}\n", .{p});
}
```

## License

See the [LICENSE](LICENSE) file for more information.

## Contact

For any questions or suggestions, feel free to open an issue or contact the author.
