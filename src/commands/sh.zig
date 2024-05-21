const std = @import("std");
const io = std.io;
const print = std.debug.print;

const reserved = std.StaticStringMap(*const fn (args: [][]const u8) void).initComptime(.{
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
    std.process.exit(rc);
}

pub fn entry(_: [][]const u8) u8 {
    var input: [4096]u8 = undefined;
    var bstdin = io.bufferedReader(io.getStdIn().reader());
    var stdin = bstdin.reader();
    const allocator = std.heap.page_allocator;
    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();

    while (true) {
        defer words.clearAndFree();

        print("$ ", .{});
        const in = stdin.readUntilDelimiterOrEof(&input, '\n') catch {
            print("Input is too long...\n", .{});
            while (stdin.readByte() catch {
                return 1;
            } != '\n') {}
            continue;
        } orelse continue;
        if (in.len == 0) continue;

        var it = std.mem.splitAny(u8, in, " ");
        while (it.next()) |arg| {
            words.append(arg) catch continue;
        }

        if (reserved.get(words.items[0])) |reserved_cmd| {
            reserved_cmd(words.items[1..]);
            continue;
        }

        var child = std.process.Child.init(words.items, allocator);
        _ = child.spawnAndWait() catch |err| {
            print("sh: {s}: {s}\n", .{ words.items[0], @errorName(err) });
            continue;
        };
    }
    return 0;
}
