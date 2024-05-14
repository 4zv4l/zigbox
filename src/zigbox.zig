const std = @import("std");
const cmds = @import("commands").cmds;
const eprint = std.debug.print;

fn showCommands() void {
    eprint("zigbox :)\n", .{});
    eprint("\nCurrently defined applets:\n", .{});
    inline for (comptime cmds.keys()) |key| {
        eprint("- {s}\n", .{key});
    }
    eprint("\n", .{});
}

pub fn main() u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = std.process.argsAlloc(allocator) catch {
        eprint("Couldnt access command line arguments..\n", .{});
        return 1;
    };
    defer std.process.argsFree(allocator, args);

    // just run zigbox without args
    var applet = std.fs.path.basename(args[0]);
    if (args.len == 1 and !cmds.has(applet)) {
        showCommands();
        return 0;
    }

    // symbolic link
    if (cmds.get(applet)) |cmd| {
        return cmd(args);
    }

    // command passed as argument
    // ex: zigbox sha256sum
    applet = std.fs.path.basename(args[1]);
    if (cmds.get(applet)) |cmd| {
        return cmd(args[1..]);
    }

    eprint("{s}: applet not found\n", .{applet});
    return 1;
}
