const std = @import("std");
const fs = std.fs;
const fmtIntSizeBin = std.fmt.fmtIntSizeBin;
const print = std.debug.print;

const Mode = packed struct(u3) { read: bool, write: bool, exec: bool };
const FMode = packed struct { u: Mode, g: Mode, o: Mode };
fn modeToStr(mode: fs.File.Mode, kind: fs.File.Kind) [10]u8 {
    var str = [_]u8{'-'} ** 10;
    if (kind == .directory) str[0] = 'd';

    const modes: FMode = @bitCast(@as(u9, @intCast(mode & 0b111111111)));
    const parts: [3][]u8 = .{ str[7..9], str[4..6], str[1..3] };
    inline for (@typeInfo(FMode).Struct.fields, parts) |m, part| {
        if (@field(modes, m.name).read) part[0] = 'r';
        if (@field(modes, m.name).write) part[1] = 'w';
        if (@field(modes, m.name).exec) part[2] = 'x';
    }

    return str;
}

pub fn entry(args: [][]const u8) u8 {
    const path = if (args.len > 1) args[1] else ".";
    var dir = fs.cwd().openDir(path, .{ .iterate = true }) catch return 1;
    defer dir.close();
    var dir_it = dir.iterate();

    while (dir_it.next() catch null) |entr| {
        const stat = dir.statFile(entr.name) catch continue;
        const mode = modeToStr(stat.mode, entr.kind);
        print("{s} {:8.1} {s}\n", .{ mode, fmtIntSizeBin(stat.size), entr.name });
    }

    return 0;
}
