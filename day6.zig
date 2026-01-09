const std = @import("std");
const testing = std.testing;

const data = @embedFile("day6_easy.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();
    var i_idx: usize = 0;
    var j_idx: usize = 0;
    var outer = try allocator.alloc([][]const u8, 0);

    var it = std.mem.tokenizeAny(u8, data, "\n");

    while (it.next()) |line| {
        var inner = try allocator.alloc([]const u8, 0);
        j_idx = 0;
        var jt = std.mem.tokenizeAny(u8, line, " ");
        while (jt.next()) |token| {
            inner = try allocator.realloc(inner, j_idx + 1);
            inner[j_idx] = token;
            j_idx += 1;
        }
        outer = try allocator.realloc(outer, i_idx + 1);
        outer[i_idx] = inner;
        i_idx += 1;
    }

    var sum: i64 = 0;

    for (0..j_idx) |j| {
        //const op = outer[i_idx - 1][j];
        var total: i64 = try std.fmt.parseInt(i64, outer[0][j], 10);
        var len: usize = outer[0][j].len;
        // go through and get max length;
        for (1..i_idx - 1) |i| {
            const part = outer[i][j];
            if (part.len > len) len = part.len;
            total = 0;
        }

        const num_lengths = len;

        while (len > 0) : (len -= 1) {
            //for each len, build the number the corresponds to the digit in that place
            //for each number in the vertical list. if a number isn't as long as len, that means
            //that the number doesn't have anything in that place, so skip it for this length.
            var num = try allocator.alloc(u8, num_lengths);

            var i = i_idx - 2;
            while (i >= 0) {
                //get the part
                const part = outer[i][j];
                // check its length
                if ((part.len) < len) {
                    if (i == 0) {
                        break;
                    } else {
                        i -= 1;
                    }
                    continue;
                }
                // get its digit at len
                const digit = part[len - 1];
                num[i] = digit;
                if (i == 0) {
                    break;
                } else {
                    i -= 1;
                }
            }

            std.debug.print("num: {s}\n", .{num});
        }
        sum += total;
        std.debug.print("\n\n", .{});
    }

    std.debug.print("sum: {d}\n", .{sum});
}
