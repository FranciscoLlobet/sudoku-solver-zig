# sudoku-solver-zig

## Sudoku Solver in Zig

Simple Sudoku Solver Library based on the algorithm in [FranciscoLlobet/sudoku-solver](https://github.com/FranciscoLlobet/sudoku-solver)


This library has been written as a `kata` to test the basic features of the [Zig Programming Language](https://www.ziglang.org).

> This project, the repository and author(s) are **not** affiliated with the [Zig Software Foundation](https://ziglang.org/zsf/).


## API usage

> Work-in progress

```zig
var p = puzzle.init();

p.import(puzzle_as_string);
if(puzzle_state.solver == p.solve())
{
    // puzzle is solved
    var exported_string : []u8 = p.export();
}
else
{
    // puzzle has no solution
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

```shell
zig build test
```

Tested algorithm using:

- Invalid sudokus
- Valid and solved sudokus
- Najed singles
- Hidden singles


Testing data sets:

> The data sets are currently not included in the repository. 

I consider the `top4665` data set to be the most complete data set to test for valid sudokus which need advanced sudoku solving algorithms.

- <http://magictour.free.fr/sudoku.htm> 
  - <http://magictour.free.fr/top1465>. 1465 hardest sudokus sorted by rating



## License

Copyright (c) 2023 Francisco Llobet

[LICENSE](LICENSE) for more information.