const std = @import("std");
const testing = std.testing;

const data = @embedFile("day3.txt");
const VoltageParseError = error{InvalidVoltageString};

pub fn main() !void {
    var it = std.mem.tokenizeAny(u8, data, "\n");
    var sum: u64 = 0;

    while (it.next()) |battery| {
        sum += try get_max_voltage_extended(battery);
    }

    std.debug.print("Final sum: {d}\n", .{sum});
}

// given a string, battery, e.g 123456729
// return the maximum number possible from the battery.
// In the above example, the maximum would be 79.
fn get_max_voltage(battery: []const u8) !u8 {
    var buf: [2]u8 = undefined;
    var max_tens_voltage: u8 = 0;
    var max_ones_voltage: u8 = 0;

    if (battery.len == 0) return VoltageParseError.InvalidVoltageString;
    if (battery.len == 1) {
        const voltage = try std.fmt.parseInt(u8, battery, 10);
        return voltage;
    }

    // have to account for the order...
    for (battery, 0..) |volt_string, index| {
        const volts: u8 = volt_string - '0';
        const remaining = battery.len - index;
        // check if there are enough remaining digits to set this to
        // the ten's place.
        if (volts > max_tens_voltage and remaining >= 2) {
            // if there are 2 or more remaining digits, check if the 10's
            // place digit is greater than current.
            // We don't care about this check if there are less than 2 digits remaining, because
            // it cannot possibly be higher than the existing.
            max_tens_voltage = volts;
            max_ones_voltage = 0;
        } else if (volts > max_ones_voltage) {
            max_ones_voltage = volts;
        }
    }

    const voltage_string = try std.fmt.bufPrint(&buf, "{d}{d}", .{ max_tens_voltage, max_ones_voltage });
    return try std.fmt.parseInt(u8, voltage_string, 10);
}

fn get_max_voltage_extended(battery: []const u8) !u64 {
    var max_voltage = [_]u8{'0'} ** 12;

    if (battery.len == 0) return VoltageParseError.InvalidVoltageString;
    if (battery.len == 12) {
        const voltage = try std.fmt.parseInt(u8, battery, 10);
        return voltage;
    }

    // have to account for the order...
    for (battery, 0..) |volt_string, index| {
        const volts: u8 = volt_string - '0';
        const remaining: i8 = @intCast(battery.len - index);

        // get the furthest to the left remaining place that we should check.
        //
        const greatest_remaining_power: i8 = remaining - 12;
        // if grp < 0, we only want to check / change the remaining - (grp) digits.
        //
        const start_index: usize = @intCast(if (greatest_remaining_power >= 0) 0 else -1 * greatest_remaining_power);

        for (start_index..max_voltage.len) |idx| {
            var curr_voltage_u8: u8 = undefined;
            if (max_voltage[idx] != '0') {
                curr_voltage_u8 = max_voltage[idx] - '0';
            } else {
                curr_voltage_u8 = 0;
            }
            if (volts > curr_voltage_u8) {
                max_voltage[idx] = volts + '0';
                // we need to replace everything to the right of the current idx with 0s
                for (idx + 1..max_voltage.len) |remaining_idx| {
                    max_voltage[remaining_idx] = '0';
                }
                break;
            }
        }
    }

    std.debug.print("Voltage string: {s}\n", .{max_voltage});
    return try std.fmt.parseInt(u64, &max_voltage, 10);
}

test "get_max_voltage" {
    try testing.expectEqual(1, get_max_voltage("1"));
    try testing.expectEqual(12, get_max_voltage("12"));
    try testing.expectEqual(22, get_max_voltage("22"));
    try testing.expectEqual(98, get_max_voltage("987654321111111"));
    try testing.expectEqual(89, get_max_voltage("811111111111119"));
    try testing.expectEqual(78, get_max_voltage("234234234234278"));
    try testing.expectEqual(92, get_max_voltage("818181911112111"));
}

test "get_max_voltage_extended" {
    //try testing.expectEqual(987654321111, get_max_voltage_extended("987654321111111"));
    //try testing.expectEqual(811111111119, get_max_voltage_extended("811111111111119"));
    //try testing.expectEqual(434234234278, get_max_voltage_extended("234234234234278"));
    //try testing.expectEqual(888911112111, get_max_voltage_extended("818181911112111"));
    try testing.expectEqual(986423, get_max_voltage_extended("3733444444337244341463452463644234493354144584433344425444453534454444343444324335454446423343444472"));
}
