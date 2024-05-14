const std = @import("std");
pub const cmds = std.StaticStringMap(*const fn (args: [][]const u8) u8).initComptime(.{
    .{ "cat", @import("commands/cat.zig").entry },
    .{ "sha256sum", @import("commands/sha256sum.zig").entry },
});
