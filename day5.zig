const std = @import("std");
const testing = std.testing;

const data = @embedFile("day5.txt");
const ArrayList = std.array_list.Aligned;

pub fn main() !void {
    const split = std.mem.indexOf(u8, data, "\n\n");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var sum: u64 = 0;

    if (split != null) {
        const ranges: []const u8 = data[0..split.?];
        var valid_ingredients: ArrayList(*Range, null) = try build_ingredient_array_sorted(allocator, ranges);
        const ranges_cleaned = try clean_ranges(&valid_ingredients, allocator);

        for (ranges_cleaned.items) |range| {
            sum += (range.max - range.min + 1);
        }
    } else unreachable;

    std.debug.print("Sum: {d}\n", .{sum});
}

const Range = struct { min: u64, max: u64 };

// create an array of the max size, make index indicate if the ingredient is valid.
// then searching if an ingredient is valid is constant time (just index the array)
fn build_ingredient_array_sorted(gpa: std.mem.Allocator, ranges: []const u8) !ArrayList(*Range, null) {
    var array = ArrayList(*Range, null).empty;

    var it = std.mem.tokenizeAny(u8, ranges, "\n");

    while (it.next()) |range_str| {
        const bpt = std.mem.indexOf(u8, range_str, "-");
        if (bpt == null) {
            std.debug.print("reached unreachble in build_ingredient_array: {s}\n", .{range_str});
        }

        const min = try std.fmt.parseInt(u64, range_str[0..bpt.?], 10);
        const max = try std.fmt.parseInt(u64, range_str[bpt.? + 1 ..], 10);
        const range_ptr = try gpa.create(Range);
        range_ptr.min = min;
        range_ptr.max = max;
        var idx: usize = 0;

        while (idx < array.items.len) {
            const curr = array.items[idx];
            if (min <= curr.min) {
                break;
            }
            idx += 1;
        }

        try array.insert(gpa, idx, range_ptr);
    }

    return array;
}

fn clean_ranges(ranges: *ArrayList(*Range, null), gpa: std.mem.Allocator) !ArrayList(*Range, null) {
    var new_ranges = ArrayList(*Range, null).empty;

    for (ranges.items) |range| {
        try add_range(&new_ranges, range, gpa);
    }

    return new_ranges;
}

fn add_range(ranges: *ArrayList(*Range, null), new_range: *Range, gpa: std.mem.Allocator) !void {
    var idx: usize = 0;
    if (ranges.items.len > 0) {
        for (ranges.items) |existing| {
            idx += 1;
            if (new_range.min >= existing.min and new_range.min <= existing.max) {
                if (new_range.max <= existing.max) {
                    break; // do nothing, the new range is entirely in the existing one
                } else {
                    existing.max = new_range.max;
                    break;
                }
            } else if (new_range.max >= existing.min and new_range.max <= existing.max) {
                existing.min = new_range.min;
                break;
            } else if (new_range.min < existing.min and new_range.max > existing.max) {
                existing.min = new_range.min;
                existing.max = new_range.max;
                break;
            } else if (idx == ranges.items.len) {
                try ranges.append(gpa, new_range);
            }
        }
    } else {
        try ranges.append(gpa, new_range);
    }
}
