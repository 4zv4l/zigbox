const std = @import("std");
const fs = std.fs;
const eprint = std.debug.print;

fn cat(file: fs.File) !void {
    const stdout = std.io.getStdOut().writer();
    var bufout = std.io.bufferedWriter(stdout);
    defer bufout.flush() catch {};

    var buff: [4096]u8 = undefined;
    while (true) {
        const len = try file.read(&buff);
        if (len == 0) break;
        try bufout.writer().print("{s}", .{buff[0..len]});
    }
}

pub fn entry(args: [][]const u8) u8 {
    // if no args, read from stdin
    if (args.len == 1) {
        cat(std.io.getStdIn()) catch |err| {
            eprint("cat: {s}: {s}\n", .{ "-", @errorName(err) });
            return 1;
        };
    }

    // cat each file
    for (args[1..]) |path| {
        var file = fs.cwd().openFile(path, .{}) catch |err| {
            eprint("cat: {s}: {s}\n", .{ path, @errorName(err) });
            return 1;
        };
        defer file.close();

        cat(file) catch |err| {
            eprint("cat: {s}: {s}\n", .{ path, @errorName(err) });
            return 2;
        };
    }

    return 0;
}
