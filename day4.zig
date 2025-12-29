const std = @import("std");
const testing = std.testing;
const data = @embedFile("day4.txt");

const MyError = error{InvalidIndex};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var data_slice = data.*;

    var sum: u64 = 0;
    var index: usize = 0;
    var above: ?[]const u8 = null;
    var below: ?[]const u8 = null;
    const arr_step_size = 1;
    var inaccessible_rolls: []i64 = try allocator.alloc(i64, arr_step_size);
    var inaccessible_idx: usize = 0;

    var roll_removed = true;
    var line_length: usize = 0;

    while (roll_removed) {
        roll_removed = false;
        index = 0;
        above = null;
        below = null;

        if (inaccessible_idx == 0) {
            while (index < data_slice.len) {
                const next = std.mem.indexOf(u8, data_slice[index..], "\n");
                if (next != null) {
                    // assuming constant line length for simplicity.
                    line_length = next.?;
                    const row: []u8 = data_slice[index .. index + line_length];
                    if (index > 0) {
                        above = data_slice[index - 1 - line_length .. index - 1];
                    }
                    if (index + next.? + line_length < data_slice.len) {
                        below = data_slice[index + next.? + 1 .. index + next.? + 1 + line_length];
                    } else {
                        below = null;
                    }

                    for (0..row.len) |row_idx| {
                        if (row[row_idx] == '@') {
                            if (inaccessible_idx >= inaccessible_rolls.len) {
                                inaccessible_rolls = try allocator.realloc(inaccessible_rolls, inaccessible_rolls.len + arr_step_size);
                            }
                            if (try is_paper_accessible(row, row_idx, above, below)) {
                                roll_removed = true;
                                data_slice[row_idx + index] = '.';
                                sum += 1;
                            } else {
                                inaccessible_rolls[inaccessible_idx] = @intCast(row_idx + index);
                                inaccessible_idx += 1;
                            }
                        }
                    }
                    index = index + line_length + 1;
                } else {
                    break;
                }
            }
        } else {
            for (inaccessible_rolls, 0..) |roll, roll_idx| {
                if (roll == -1 or roll == 0) continue;
                const row_bounds = extract_row_bounds(&data_slice, @intCast(roll), line_length);
                const idx_in_row = @as(usize, @intCast(roll)) - row_bounds.row_start;
                above = if (row_bounds.above_start != null) data_slice[row_bounds.above_start.?..row_bounds.above_end.?] else null;
                below = if (row_bounds.below_start != null) data_slice[row_bounds.below_start.?..row_bounds.below_end.?] else null;
                const row = data_slice[row_bounds.row_start..row_bounds.row_end];
                if (try is_paper_accessible(row, idx_in_row, above, below)) {
                    roll_removed = true;
                    data_slice[@intCast(roll)] = '.';
                    sum += 1;
                    inaccessible_rolls[roll_idx] = -1;
                }
            }
        }
    }

    std.debug.print("Final sum: {d}\n", .{sum});
}

// row: the row that the roll in question exists on.
// idx: the index of the roll.
fn is_paper_accessible(row: []const u8, roll_idx: usize, above: ?[]const u8, below: ?[]const u8) MyError!bool {
    if (roll_idx > row.len - 1) {
        return MyError.InvalidIndex;
    }
    if (above == null and below == null) {
        // if there are no rows above or below, the roll is always accessible.
        return true;
    }

    var adjacent_rolls: u4 = 0;
    const l_idx = if (roll_idx > 0) roll_idx - 1 else roll_idx;
    const r_idx = if (roll_idx < row.len - 1) roll_idx + 1 else roll_idx;

    for (l_idx..r_idx + 1) |idx| {
        if (above) |above_row| {
            if (above_row[idx] == '@') adjacent_rolls += 1;
        }
        if (below) |below_row| {
            if (below_row[idx] == '@') adjacent_rolls += 1;
        }
        if (idx != roll_idx and row[idx] == '@') adjacent_rolls += 1;
    }

    return adjacent_rolls < 4;
}

const RowBounds = struct {
    above_start: ?usize,
    above_end: ?usize,
    row_start: usize,
    row_end: usize,
    below_start: ?usize,
    below_end: ?usize,
};

fn extract_row_bounds(roll_data: []const u8, index: usize, line_length: usize) RowBounds {
    // form of:
    // ***<\n>
    // ***<\n>
    // ***<\n>
    // line_length is the number of characters on the line NOT INCLUDING THE \n
    const char_location: usize = @mod(index, line_length + 1); // relative to it's local line
    const row_start: usize = @intCast(index - char_location); // 4
    const row_end = row_start + line_length; // 4 + 3 = 7 (NON-INCLUSIVE)
    //

    // check for above.
    // we need to check if row_start (4) - (row_length (3) + 1, to account for \n) is >= 0
    const prospective_start: i64 = @as(i64, @intCast(row_start)) - @as(i64, @intCast(line_length + 1));
    const above_start: ?usize = if (prospective_start >= 0) row_start - (line_length + 1) else null;
    const above_end: ?usize = if (above_start != null) above_start.? + line_length else null;

    // check for below.
    // we need to check if row_end (7, which is the \n) + line_length is <= roll_data.len
    const below_start: ?usize = if (row_end + line_length <= roll_data.len) row_end + 1 else null;
    const below_end: ?usize = if (below_start != null) below_start.? + line_length else null;

    return RowBounds{
        .above_start = above_start,
        .above_end = above_end,
        .row_start = row_start,
        .row_end = row_end,
        .below_start = below_start,
        .below_end = below_end,
    };
}

// Helper function to extract a specific line from embedded data
fn getLine(comptime data_file: []const u8, line_num: usize) []const u8 {
    var lines = std.mem.splitScalar(u8, data_file, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        if (i == line_num) return line;
    }
    return "";
}

test "is_paper_accessible" {
    const easy_data = @embedFile("day4_easy.txt");
    const full_data = @embedFile("day4.txt");

    {
        const row = "..@@.@@@@.";
        const below = "@@@.@.@.@@";
        try testing.expectError(MyError.InvalidIndex, is_paper_accessible(row, 100, null, below));
    }

    {
        const row = "..@@.@@@@.";
        const result = try is_paper_accessible(row, 2, null, null);
        try testing.expectEqual(true, result);
    }

    {
        const row1 = getLine(easy_data, 0);
        const row2 = getLine(easy_data, 1);
        const result = try is_paper_accessible(row1, 2, null, row2);
        try testing.expect(result == true);
    }

    {
        const row9 = getLine(easy_data, 8);
        const row10 = getLine(easy_data, 9);
        const result = try is_paper_accessible(row10, 2, row9, null);
        try testing.expect(result == true);
    }

    {
        const row1 = getLine(easy_data, 0);
        const row2 = getLine(easy_data, 1);
        const row3 = getLine(easy_data, 2);
        const result = try is_paper_accessible(row2, 0, row1, row3);
        try testing.expect(result == true);
    }

    {
        const row1 = getLine(easy_data, 0);
        const row2 = getLine(easy_data, 1);
        const row3 = getLine(easy_data, 2);
        const result = try is_paper_accessible(row2, 9, row1, row3);
        try testing.expect(result == false);
    }

    {
        const row1 = getLine(easy_data, 0);
        const row2 = getLine(easy_data, 1);
        const result = try is_paper_accessible(row1, 5, null, row2);
        try testing.expect(result == true);
    }

    {
        const row2 = getLine(easy_data, 1);
        const row3 = getLine(easy_data, 2);
        const row4 = getLine(easy_data, 3);
        const result = try is_paper_accessible(row3, 1, row2, row4);
        try testing.expect(result == false);
    }

    {
        const row2 = getLine(easy_data, 1);
        const row3 = getLine(easy_data, 2);
        const row4 = getLine(easy_data, 3);
        const result = try is_paper_accessible(row3, 2, row2, row4);
        try testing.expect(result == false);
    }

    {
        const row4 = getLine(easy_data, 3);
        const row5 = getLine(easy_data, 4);
        const row6 = getLine(easy_data, 5);
        const result = try is_paper_accessible(row5, 9, row4, row6);
        try testing.expect(result == true);
    }

    {
        const row1 = getLine(full_data, 0);
        const row2 = getLine(full_data, 1);
        const result = try is_paper_accessible(row1, 0, null, row2);
        try testing.expect(result == true);
    }

    {
        const row1 = getLine(full_data, 0);
        const row2 = getLine(full_data, 1);
        const row3 = getLine(full_data, 2);
        const result = try is_paper_accessible(row2, 7, row1, row3);
        try testing.expect(result == false);
    }

    {
        const row3 = getLine(full_data, 2);
        const row4 = getLine(full_data, 3);
        const row5 = getLine(full_data, 4);
        const result = try is_paper_accessible(row4, 0, row3, row5);
        try testing.expect(result == false);
    }

    {
        const row0 = getLine(full_data, 0);
        const row1 = getLine(full_data, 1);
        const row2 = getLine(full_data, 2);
        const row1_len = row1.len;
        const result = try is_paper_accessible(row1, row1_len - 1, row0, row2);
        try testing.expect(result == true);
    }

    {
        const row9 = getLine(full_data, 8);
        const row10 = getLine(full_data, 9);
        const row11 = getLine(full_data, 10);
        const result = try is_paper_accessible(row10, 50, row9, row11);
        try testing.expect(result == false);
    }
}
