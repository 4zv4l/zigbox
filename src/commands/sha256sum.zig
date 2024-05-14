const std = @import("std");
const fs = std.fs;
const sha256 = std.crypto.hash.sha2.Sha256;
const print = std.debug.print;
const exit = std.process.exit;

// return the sha256sum of a given file
pub fn sha256sum(file: fs.File) ![sha256.digest_length]u8 {
    var sum = sha256.init(.{});
    var buff: [4096]u8 = undefined;

    while (true) {
        const len = try file.read(&buff);
        if (len == 0) break;
        sum.update(buff[0..len]);
    }

    return sum.finalResult();
}

pub fn entry(args: [][]const u8) u8 {
    // default is return success
    var rc: u8 = 0;

    // if no arguments, read from stdin
    if (args.len == 1) {
        const digest = sha256sum(std.io.getStdIn()) catch |err| {
            print("-: {s}\n", .{@errorName(err)});
            exit(2);
        };
        print("{x}  -\n", .{std.fmt.fmtSliceHexLower(&digest)});
    }

    // else sha256sum the given paths
    else {
        const paths = args[1..];
        for (paths) |path| {
            const file = fs.cwd().openFile(path, .{}) catch |err| {
                print("{s}: {s}\n", .{ path, @errorName(err) });
                rc = 3;
                continue;
            };
            defer file.close();

            const digest = sha256sum(file) catch |err| {
                print("{s}: {s}\n", .{ path, @errorName(err) });
                rc = 4;
                continue;
            };

            print("{x}  {s}\n", .{ std.fmt.fmtSliceHexLower(&digest), path });
        }
    }

    return rc;
}
