const std = @import("std");

pub fn entry(args: [][]const u8) u8 {
    const str = if (args.len > 1) args[1] else "yes";

    var stdout = std.io.getStdOut().writer();
    while (true) {
        stdout.print("{s}\n", .{str}) catch return 1;
    }

    return 0;
}
