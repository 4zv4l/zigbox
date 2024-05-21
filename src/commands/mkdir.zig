const std = @import("std");
const print = std.debug.print;

pub fn entry(args: [][]const u8) u8 {
    if (args.len == 1) {
        print("Usage: mkdir [-p] DIRECTORY...\n", .{});
        return 0;
    }

    for (args[1..]) |path| {
        std.fs.cwd().makePath(path) catch |err| {
            print("mkdir: {s}\n", .{@errorName(err)});
            return 1;
        };
    }
    return 0;
}
