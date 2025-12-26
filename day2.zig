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
                const valid = is_id_valid(str);
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

fn is_id_valid_mp(id: []const u8, mp: usize) bool {
    if (@mod(id.len, mp) != 0) return true;
    var cutoff: usize = mp;

    while (cutoff <= id.len) : (cutoff += mp) {}
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
    try testing.expectEqual(true, is_id_valid_mp("15"));
    try testing.expectEqual(false, is_id_valid_mp("11"));
    try testing.expectEqual(false, is_id_valid_mp("22"));
    try testing.expectEqual(false, is_id_valid_mp("5656"));
    try testing.expectEqual(false, is_id_valid_mp("565656"));
    try testing.expectEqual(false, is_id_valid_mp("56565656"));
    try testing.expectEqual(false, is_id_valid_mp("1111111"));
}
