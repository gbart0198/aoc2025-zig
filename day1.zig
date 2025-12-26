const std = @import("std");
const data = @embedFile("day1.txt");
const testing = std.testing;

pub fn main() !void {
    var it = std.mem.tokenizeAny(u8, data, " \n");
    var dial: u32 = 50;
    var pwd: u32 = 0;
    while (it.next()) |inst| {
        const dir = inst[0..1];
        const val: i32 = @intCast(try std.fmt.parseInt(u16, inst[1..], 10));

        const factor: i4 = if (std.mem.eql(u8, "L", dir)) -1 else 1;
        const new_val: i32 = factor * val;

        const zero_clicks = get_zero_clicks(dial, new_val);

        pwd += zero_clicks;

        // update the dial
        dial = get_new_dial(dial, new_val);
    }

    std.debug.print("Final pwd: {d}\n", .{pwd});
}

fn get_new_dial(dial: u32, clicks: i32) u32 {
    const new_dial: i32 = @intCast(dial);
    const mod1 = @mod(new_dial + clicks, 100);
    const mod2 = @mod(mod1, 100);
    return @intCast(mod2);
}

fn get_zero_clicks(dial: u32, clicks: i32) u32 {
    var zeros: u32 = 0;
    if (clicks > 0) {
        var my_dial = dial;
        const clicks_u32: u32 = @intCast(clicks);
        const full_rotations = @divTrunc(clicks_u32, 100); // number of full rotations
        zeros += full_rotations;
        const new_clicks = @mod(clicks_u32, 100); // remainder, we will use this to add to dial.

        if (new_clicks != 0) {
            my_dial += new_clicks; // add remainder to the dial
            // check if my_dial is >= 100. If it is, add to zeros.
            if (my_dial >= 100) zeros += 1;
        }
    } else {
        var my_dial_i32: i32 = @intCast(dial);
        const full_rotations: u32 = @intCast(@divTrunc(clicks, -100));
        zeros += full_rotations;
        const new_clicks: i32 = @intCast(@abs(@mod(clicks, -100)));

        if (new_clicks != 0) {
            if (my_dial_i32 == 0) {
                my_dial_i32 = 100 - new_clicks;
            } else {
                my_dial_i32 -= new_clicks;
            }
            if (my_dial_i32 <= 0) zeros += 1;
        }
    }

    return zeros;
}

test "check update dial" {
    try testing.expectEqual(get_new_dial(50, 5), 55);
    try testing.expectEqual(get_new_dial(50, -10), 40);
    try testing.expectEqual(get_new_dial(50, 50), 0);
    try testing.expectEqual(get_new_dial(50, -50), 0);
    try testing.expectEqual(get_new_dial(50, 100), 50);
    try testing.expectEqual(get_new_dial(50, -100), 50);
    try testing.expectEqual(get_new_dial(50, 150), 0);
    try testing.expectEqual(get_new_dial(50, -150), 0);
    try testing.expectEqual(get_new_dial(50, 200), 50);
    try testing.expectEqual(get_new_dial(50, -200), 50);
    try testing.expectEqual(get_new_dial(50, 123), 73);
    try testing.expectEqual(get_new_dial(50, -123), 27);
    try testing.expectEqual(get_new_dial(50, 225), 75);
    try testing.expectEqual(get_new_dial(50, -225), 25);
}

test "check zero clicks" {
    try testing.expectEqual(get_zero_clicks(1, 3), 0);
    try testing.expectEqual(get_zero_clicks(50, -10), 0);
    try testing.expectEqual(get_zero_clicks(50, 100), 1);
    try testing.expectEqual(get_zero_clicks(50, 200), 2);
    try testing.expectEqual(get_zero_clicks(50, -200), 2);
    try testing.expectEqual(get_zero_clicks(50, 50), 1);
    try testing.expectEqual(get_zero_clicks(50, 150), 2);
    try testing.expectEqual(get_zero_clicks(50, 250), 3);
    try testing.expectEqual(get_zero_clicks(50, -50), 1);
    try testing.expectEqual(get_zero_clicks(50, -150), 2);
    try testing.expectEqual(get_zero_clicks(50, -250), 3);
    try testing.expectEqual(get_zero_clicks(0, 123), 1);
    try testing.expectEqual(get_zero_clicks(0, 258), 2);
    try testing.expectEqual(get_zero_clicks(0, 200), 2);
    try testing.expectEqual(get_zero_clicks(0, -123), 1);
    try testing.expectEqual(get_zero_clicks(0, -258), 2);
    try testing.expectEqual(get_zero_clicks(0, -200), 2);
}
