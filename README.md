# sudoku-solver-zig

## Sudoku Solver in Zig

Simple Sudoku Solver Library based on the algorithm in [FranciscoLlobet/sudoku-solver](https://github.com/FranciscoLlobet/sudoku-solver)


This library has been written as a `kata` to test the basic features of the [Zig Programming Language](https://www.ziglang.org).

> This project, the repository and author(s) are **not** affiliated with the [Zig Software Foundation](https://ziglang.org/zsf/).

## API usage

> Work-in progress

```zig
const puzzle = @import("sudoku-solver.zig);

// ...
const puzzle_as_string: []const u8 = "..2.3...8.....8....31.2.....6..5.27..1.....5.2.4.6..31....8.6.5.......13..531.4..";
// ...

var p = puzzle.init();

try p.import(puzzle_as_string);

p.solve() catch |err|{
  // Solver failed to find solution
  _ = err;
}
```

## Limitation

- Basic error handling
- Basic API
- Public Interface may change in the future.

## Building

```shell
zig build
```

## Testing

The testing strategy validates the solving algorithn using:

- Invalid sudoku puzzles
- Valid and solved sudoku puzzles
- Naked singles
- Hidden singles

### Unit tests

Run the unit-tests

```shell
zig build test
```

### Data tests

Data-based tests will validate the sudoku solving algorithm.

I consider the [`top4665`](http://magictour.free.fr/top1465) data set available at <http://magictour.free.fr/sudoku.htm> to be the most complete data set to test for valid sudoku which need advanced sudoku solving algorithms.

> The data sets are currently not included in the repository.

To get the data set, download it from the link or use, for example `curl`. The data set shall be stored in the `data` directory.

```shell
curl http://magictour.free.fr/top1465 --output ./data/top1465
```

Run the data tests

```shell
zig build run
```

## License

Copyright (c) 2023 Francisco Llobet

[LICENSE](LICENSE) for more information.
