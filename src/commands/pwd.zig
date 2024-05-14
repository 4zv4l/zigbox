const std = @import("std");
const eprint = std.debug.print;

pub fn entry(args: [][]const u8) u8 {
    _ = args;
    var buff: [std.fs.max_path_bytes]u8 = undefined;
    const pwd = std.process.getCwd(&buff) catch return 1;
    std.io.getStdOut().writer().print("{s}\n", .{pwd}) catch return 1;
    return 0;
}
