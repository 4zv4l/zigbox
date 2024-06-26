const std = @import("std");
const helper = @import("helper/helper.zig");
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

// truncate the file then save the new content
fn save(f: fs.File, p: []const u8, s: *Lines) void {
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
    s.clearAndFree();
    var buff: std.BoundedArray(u8, 4096) = .{};
    var stdin = std.io.getStdIn().reader();

    while (stdin.streamUntilDelimiter(buff.writer(), '\n', buff.capacity())) {
        defer buff.resize(0) catch {};
        if (buff.get(0) == '?') return;

        var line = allocator.dupe(u8, buff.slice()) catch |err| {
            print("dupe: {s}\n", .{@errorName(err)});
            return;
        };
        line[line.len - 1] = '\n';
        s.append(line) catch |err| {
            print("append: {s}\n", .{@errorName(err)});
            return;
        };
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

// read an action from stdin
fn getAction(stdin: anytype) ![1]u8 {
    print("> ", .{});
    return [1]u8{try stdin.readByte()};
}

// load the file line by line
fn load(file: fs.File, lines: *Lines, p: []const u8) !void {
    const data = try file.readToEndAlloc(allocator, 1024 * 1024 * 1024);
    defer allocator.free(data);
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        try lines.append(try allocator.dupe(u8, line));
    }
    print("loaded {d:.2} from {s}\n", .{ std.fmt.fmtIntSizeBin(data.len), p });
}

pub fn entry(args: [][]const u8) u8 {
    if (args.len == 1) {
        print("usage: zedit FILE\n", .{});
        return 0;
    }

    const path = args[1];
    var file = std.fs.cwd().createFile(path, .{ .truncate = false, .read = true }) catch |err| {
        print("zedit: {s}: {s}\n", .{ path, @errorName(err) });
        return 1;
    };
    defer file.close();

    var lines = Lines.init(allocator);
    defer lines.deinit();
    load(file, &lines, path) catch |err| {
        print("zedit: load: {s}\n", .{@errorName(err)});
        return 1;
    };

    const stdin = std.io.getStdIn().reader();
    while (true) {
        const action = getAction(stdin) catch {
            print("wrong action, press '?' for help\n", .{});
            helper.flush(stdin) catch return 1;
            continue;
        };
        helper.flush(stdin) catch return 1;
        if (actions.get(&action)) |do| do(file, path, &lines);
    }

    return 0;
}
