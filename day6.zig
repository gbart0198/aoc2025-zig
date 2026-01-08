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
    for (0..outer.len - 1) |outer_idx| {
        const arr = outer[outer_idx];
        const op = arr[arr.len - 1];
        var total: i64 = try std.fmt.parseInt(i64, arr[0], 10);
        for (1..arr.len - 1) |idx| {
            const next: i64 = try std.fmt.parseInt(i64, arr[idx], 10);
            std.debug.print("Total: {d}, next: {d}, op: {s}\n", .{ total, next, op });
            if (std.mem.eql(u8, op, "+")) {
                total += next;
            } else if (std.mem.eql(u8, op, "-")) {
                total -= next;
            } else if (std.mem.eql(u8, op, "*")) {
                println
                total *= next;
            } else if (std.mem.eql(u8, op, "/")) {
                total = @divExact(total, next);
            }
        }
        sum += total;
    }
    std.debug.print("Sum: {d}\n", .{sum});
}
