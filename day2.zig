// DISCLAIMER: THIS NEEDS OPTIMIZED, BADLY
// TODO: EXAMINE ALGORITHM BEING USED AND FIND O(n)

const std = @import("std");
const testing = std.testing;
const data = @embedFile("day2.txt");

const Range = struct {
    upper: u64 = undefined,
    lower: u64 = undefined,
};

pub fn main() !void {
    var sum: u64 = 0;

    // initialize the allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var buf: [21]u8 = undefined;
    var cache = std.AutoArrayHashMap(u64, bool).init(allocator);

    var it = std.mem.tokenizeSequence(u8, data, ",");

    while (it.next()) |range_str| {
        const range: Range = try get_ranges(range_str);
        for (range.lower..range.upper + 1) |num| {
            if (cache.contains(num)) {
                const invalid = cache.get(num).?;
                if (invalid) {
                    sum += num;
                    std.debug.print("Found invalid number from cache: {d}\n", .{num});
                } else {
                    std.debug.print("Found cached number that is valid: {d}\n", .{num});
                }
            } else {
                const str = try std.fmt.bufPrint(&buf, "{d}", .{num});
                const valid = validate_part_2(str);
                if (!valid) {
                    std.debug.print("Found invalid number: {d}\n", .{num});
                    sum += num;
                }
                _ = try cache.put(num, valid);
            }
        }
    }

    std.debug.print("Sum: {d}\n", .{sum});
}

fn get_ranges(range_str: []const u8) !Range {
    var split = std.mem.tokenizeAny(u8, range_str, "-\n");
    const lower_str = split.next().?;
    const upper_str = split.next().?;
    const lower: u64 = try std.fmt.parseInt(u64, lower_str, 10);
    const upper: u64 = try std.fmt.parseInt(u64, upper_str, 10);

    return Range{
        .lower = lower,
        .upper = upper,
    };
}

fn validate_part_2(id: []const u8) bool {
    if (id.len < 2) return true;
    // 222

    for (2..id.len + 1) |num_slices| {
        // for 2..4
        // 2 -> true because 3 % 2 != 0
        // 3 -> false because 2 2 2
        const is_valid = is_id_valid_mp(id, num_slices);
        if (!is_valid) return false;
    }
    return true;
}

fn is_id_valid(id: []const u8) bool {
    // check if id is made of ONLY two sequences of digits, repeated twice.
    // use length, get the first n / 2 and then the second n / 2

    // odd-lengthed id's will always be valid.
    if (@mod(id.len, 2) != 0) return true;

    const midpoint = id.len / 2;
    const first_sequence = id[0..midpoint];
    const second_sequence = id[midpoint..];

    return !std.mem.eql(u8, first_sequence, second_sequence);
}

// Checks if the id is valid with the given number of slices, mp
fn is_id_valid_mp(id: []const u8, num_slices: usize) bool {
    // if len isn't divisible by the number of slices, it is valid.
    if (@mod(id.len, num_slices) != 0 or num_slices < 2) return true;

    // we want to progress through the string, with slices of id.len / num_slices length.
    // verify that each string is the same. If it is not, return true.
    const slice_len: usize = id.len / num_slices;
    var index: usize = 0;
    var sequence: []const u8 = "";

    std.debug.print("slice_len: {d}\n", .{slice_len});

    while (index < id.len) : (index += slice_len) {
        // go from index to index+slice_len and check if that sequence
        // of chars is the same. If undefined, that means the sequence hasn't been set yet.
        const next = id[index .. index + slice_len];
        std.debug.print("sequence: {s}\tnext: {s}\t index: {d}\n", .{ sequence, next, index });
        if (!std.mem.eql(u8, "", sequence)) {
            if (!std.mem.eql(u8, sequence, next)) {
                std.debug.print("Found sequence that doesn't match, returning true.\n", .{});
                return true;
            }
        } else {
            sequence = next;
        }
    }
    return false;
}

test "get_ranges" {
    var expectedRange = Range{ .upper = 10, .lower = 1 };
    try testing.expectEqualDeep(expectedRange, get_ranges("1-10"));

    expectedRange.lower = 123;
    expectedRange.upper = 5932;
    try testing.expectEqualDeep(expectedRange, get_ranges("123-5932"));

    expectedRange.lower = 95;
    expectedRange.upper = 112;
    try testing.expectEqualDeep(expectedRange, get_ranges("95-112"));
}

test "is_id_valid" {
    try testing.expectEqual(
        true,
        is_id_valid("1"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("11"),
    );
    try testing.expectEqual(
        true,
        is_id_valid("101"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("99"),
    );
    try testing.expectEqual(
        true,
        is_id_valid("4001"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("6464"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("123123"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("1010"),
    );
    try testing.expectEqual(
        true,
        is_id_valid("39593856"),
    );
    try testing.expectEqual(
        false,
        is_id_valid("446446"),
    );
}

test "is_id_valid_mp" {
    try testing.expectEqual(true, is_id_valid_mp("15", 2));
    try testing.expectEqual(false, is_id_valid_mp("11", 2));
    try testing.expectEqual(false, is_id_valid_mp("22", 2));
    try testing.expectEqual(false, is_id_valid_mp("5656", 2));
    try testing.expectEqual(false, is_id_valid_mp("565656", 3));
    try testing.expectEqual(false, is_id_valid_mp("56565656", 2));
    try testing.expectEqual(false, is_id_valid_mp("56565656", 4));
    try testing.expectEqual(false, is_id_valid_mp("1111111", 7));
    try testing.expectEqual(false, is_id_valid_mp("333", 3));
}
