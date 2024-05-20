const std = @import("std");
const io = std.io;
const print = std.debug.print;

// flush stdin
fn flush(bstdin: anytype) void {
    var stdin = bstdin.reader();
    while (stdin.readByte() catch return != '\n') {}
}

fn cd(args: [][]const u8) void {
    const path = if (args.len > 0) args[0] else ".";
    std.process.changeCurDir(path) catch |err| {
        print("{s}: {s}\n", .{ path, @errorName(err) });
    };
}

fn exit(args: [][]const u8) void {
    const rc = if (args.len > 0) std.fmt.parseUnsigned(u8, args[0], 10) catch 0 else 0;
    std.process.exit(rc);
}

const reserved = std.StaticStringMap(*const fn (args: [][]const u8) void).initComptime(.{
    .{ "exit", exit },
    .{ "cd", cd },
});

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
            flush(&bstdin);
            continue;
        } orelse continue;

        var it = std.mem.splitAny(u8, in, " ");
        while (it.next()) |arg| {
            words.append(arg) catch continue;
        }

        if (reserved.has(words.items[0])) {
            //const args = if (words.items.len > 1) words.items[1..] else words.items[0..0];
            reserved.get(words.items[0]).?(words.items[1..]);
            continue;
        }

        var child = std.process.Child.init(words.items, allocator);
        _ = child.spawnAndWait() catch |err| {
            print("exec: {s}\n", .{@errorName(err)});
            continue;
        };
    }
    return 0;
}
