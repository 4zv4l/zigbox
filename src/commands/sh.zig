const std = @import("std");
const sh_builtin = @import("sh/builtin.zig");
const helper = @import("helper/helper.zig");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const _exit = std.process.exit;

/// Read a line from input (stdin, file).
/// Return null if only a newline is read.
/// Exit with error code 1 on alloc error.
fn sh_readline(allocator: Allocator, reader: anytype) ?[]const u8 {
    const max_length = std.math.maxInt(usize);
    const line = reader.readUntilDelimiterOrEofAlloc(allocator, '\n', max_length) catch |err| switch (err) {
        error.StreamTooLong => {
            print("sh_readline: alloc error, input is too long\n", .{});
            helper.flush(reader) catch {}; // skip error since _exit(1) anyway
            _exit(1);
        },
        else => {
            print("sh_readline: {s}\n", .{@errorName(err)});
            _exit(1);
        },
    } orelse _exit(0); // eof/(ctrl-d)
    return if (line.len == 0) null else line;
}

/// Split the input line per space.
/// Exit with error code 1 on alloc error.
fn sh_split_line(allocator: Allocator, line: []const u8) [][]const u8 {
    var words = std.ArrayList([]const u8).init(allocator);

    var it = std.mem.splitAny(u8, line, " ");
    while (it.next()) |arg| {
        words.append(arg) catch _exit(1);
    }

    return words.toOwnedSlice() catch _exit(1);
}

/// Execute a builtin command or an external program.
/// Returns the exit code.
fn sh_exec(allocator: Allocator, args: [][]const u8) u8 {
    // if reserved words
    if (sh_builtin.reserved.get(args[0])) |reserved_cmd| {
        reserved_cmd(args[1..]);
        return 0;
    }

    // else exec external program
    var child = std.process.Child.init(args, allocator);
    const status = child.spawnAndWait() catch |err| {
        print("sh: {s}: {s}\n", .{ args[0], @errorName(err) });
        return 1;
    };
    return status.Exited;
}

/// Main shell loop (read, parse, execute)
fn sh_loop(allocator: Allocator, stdin: anytype) !void {
    var status: ?u8 = null;
    while (true) {
        if (status) |s| print("({d})$ ", .{s}) else print("$ ", .{});
        const line = sh_readline(allocator, stdin) orelse continue;
        const args = sh_split_line(allocator, line);
        status = sh_exec(allocator, args);

        allocator.free(line);
        allocator.free(args);
    }
}

pub fn entry(_: [][]const u8) u8 {
    // IO setup
    var bstdin = std.io.bufferedReader(std.io.getStdIn().reader());
    const stdin = bstdin.reader();

    // allocator setup
    const allocator = std.heap.page_allocator;

    // TODO: load config file

    // run command loop
    sh_loop(allocator, stdin) catch return 1;

    return 0;
}
