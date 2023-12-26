pub const valid_test_puzzles: []const []const u8 = &[_][]const u8{
    "974236158638591742125487936316754289742918563589362417867125394253649871491873625", // Already solved puzzle
    "2564891733746159829817234565932748617128.6549468591327635147298127958634849362715", // Almost solved puzzle. One Element left
    "3.542.81.4879.15.6.29.5637485.793.416132.8957.74.6528.2413.9.655.867.192.965124.8", // Almost solved puzzle. Naked Singles
    "..2.3...8.....8....31.2.....6..5.27..1.....5.2.4.6..31....8.6.5.......13..531.4..", // Solvable puzzle. Hidden Singles
};

pub const invalid_test_puzzles: []const []const u8 = &[_][]const u8{
    "11...............................................................................", // Invalid puzzle. Same Row
    "1........1.......................................................................", // Invalid puzzle. Same Column
    "1.........1.........1............................................................", // Invalid puzzle. Same Subgrid
    "534678912672195348198342567859761423426853791713924856961537284287119635345286179", // Invalid puzzle
};

pub const puzzle_files: []const []const u8 = &[_][]const u8{
    "./data/HardestDatabase110626.txt",
    "./data/top1465.txt",
};