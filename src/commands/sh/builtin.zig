const std = @import("std");
const print = std.debug.print;
const _exit = std.process.exit;

pub const reserved = std.StaticStringMap(*const fn (args: [][]const u8) void).initComptime(.{
    .{ "echo", echo },
    .{ "cd", cd },
    .{ "exit", exit },
});

fn echo(args: [][]const u8) void {
    for (args) |arg| print("{s} ", .{arg});
    print("\n", .{});
}

fn cd(args: [][]const u8) void {
    const path = if (args.len > 0) args[0] else ".";
    std.process.changeCurDir(path) catch |err| {
        print("cd: {s}: {s}\n", .{ path, @errorName(err) });
    };
}

fn exit(args: [][]const u8) void {
    const rc = if (args.len > 0) std.fmt.parseUnsigned(u8, args[0], 10) catch 0 else 0;
    _exit(rc);
}
