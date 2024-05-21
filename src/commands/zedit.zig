const std = @import("std");
const fs = std.fs;
const Lines = std.ArrayList([]const u8);
const print = std.debug.print;
const allocator = std.heap.page_allocator;

const actions = std.StaticStringMap(*const fn (f: fs.File, p: []const u8, s: *Lines) void).initComptime(.{
    .{ "s", save },
    .{ "p", show },
    .{ "q", quit },
    .{ "e", edit },
    .{ "?", help },
});

fn save(f: fs.File, p: []const u8, s: *Lines) void {
    s.clearAndFree();
    f.setEndPos(0) catch |err| {
        print("error: {s}", .{@errorName(err)});
        return;
    };

    var bwriter = std.io.bufferedWriter(f.writer());
    var writer = bwriter.writer();
    defer bwriter.flush() catch {};

    var size: usize = 0;
    for (s.items) |line| {
        writer.writeAll(line) catch {};
        size += line.len;
    }

    print("saved {d:.2} into {s}\n", .{ std.fmt.fmtIntSizeBin(size), p });
}

fn show(_: fs.File, _: []const u8, s: *Lines) void {
    for (s.items) |line| {
        print("{s}", .{line});
    }
    print("\n", .{});
}

fn quit(_: fs.File, _: []const u8, _: *Lines) void {
    std.process.exit(0);
}

fn edit(_: fs.File, _: []const u8, s: *Lines) void {
    var buff: [1024]u8 = undefined;
    var stdin = std.io.getStdIn().reader();

    while (stdin.readUntilDelimiter(&buff, '\n')) |line| {
        if (line[0] == '?') return;

        s.append(allocator.dupe(u8, line) catch return) catch return;
    } else |_| {}
}

fn help(_: fs.File, p: []const u8, _: *Lines) void {
    print(
        \\ Currently editing {s}
        \\ Available actions:
        \\ [s]ave  the file
        \\ [q]uit  the editor
        \\ [e]dit  the file until '?' is entered
        \\ [p]rint the content of the file
        \\ [?]help show this help
        \\
    , .{p});
}

fn getAction(stdin: anytype) ![1]u8 {
    print("> ", .{});
    return [1]u8{try stdin.readByte()};
}

fn flush(stdin: anytype) void {
    while (stdin.readByte() catch return != '\n') {}
}

pub fn entry(args: [][]const u8) u8 {
    if (args.len == 1) {
        print("usage: zedit FILE\n", .{});
        return 0;
    }

    const path = args[1];
    var file = std.fs.cwd().createFile(path, .{ .truncate = false }) catch |err| {
        print("zedit: {s}: {s}\n", .{ path, @errorName(err) });
        return 1;
    };
    defer file.close();

    var lines = Lines.init(allocator);
    defer lines.deinit();

    const stdin = std.io.getStdIn().reader();
    while (true) {
        const action = getAction(stdin) catch {
            print("wrong action, press '?' for help\n", .{});
            flush(stdin);
            continue;
        };
        flush(stdin);
        if (actions.get(&action)) |do| do(file, path, &lines);
    }

    return 0;
}
