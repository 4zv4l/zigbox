# zigbox

Toy project imitating busybox

## implement a command

To implement a command, simply add a `<command>.zig` in `src/commands`.

The entry point should have this signature:
```rs
fn (args: [][]const u8) u8;
```
- args being the command line arguments (containing the command name at `args[0]`)

For example:

```rs
// src/commands/hi.zig

const std = @import("std");

pub fn entry(args: [][]const u8) u8 {
    std.debug.print("Hi !\n", .{});
    return 0;
}
```

## how to build

Simply run: `zig build`.

This will compile and install the binary to `zig-out` by default (can change using `-p`).