const std = @import("std");
const basename = std.fs.path.basename;

pub fn build(b: *std.Build) !void {
    // compile and install
    const exe = b.addExecutable(.{
        .name = "zigbox",
        .root_source_file = b.path("src/zigbox.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // generate zig code that imports src/commands/*.zig
    var cmd_dir = try std.fs.cwd().openDir("src/commands", .{ .iterate = true });
    defer cmd_dir.close();
    var walker = try cmd_dir.walk(b.allocator);
    defer walker.deinit();
    var code = std.ArrayList(u8).init(b.allocator); // will contain the zig code
    defer code.deinit();

    // loop through the zig files
    try code.writer().print("const std = @import(\"std\");\n", .{});
    try code.writer().print("pub const cmds = std.StaticStringMap(*const fn (args: [][]const u8) u8).initComptime(.{{\n", .{});
    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".zig")) {
            try code.writer().print("    .{{ \"{s}\", @import(\"commands/{s}\").entry }},\n", .{ entry.path[0 .. entry.path.len - 4], entry.path });
        }
    }
    try code.writer().print("}});\n", .{});

    // save zig code
    var file = try std.fs.cwd().createFile("src/commands.zig", .{ .truncate = true });
    defer file.close();
    _ = try file.writeAll(code.items);

    // allow zigbox to @import("commands").cmds;
    exe.root_module.addAnonymousImport("commands", .{ .root_source_file = .{ .path = "src/commands.zig" } });
    b.installArtifact(exe);

    // run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}