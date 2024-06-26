# zigbox

Toy project imitating busybox

## how to build

Simply run: `zig build`.

This will compile and install the binary to `zig-out` by default (can change using `-p`).

## how to use

You can use it the same way as you would use busybox.

Either by calling `zigbox directly`, for example:
```bash
$ zigbox hi
Hi !
```

Or by using a symbolic link, for example:
```bash
$ ln -s $(where zigbox) ./hi
$ ./hi
Hi !
```

> The 'hi' applet is not (yet?) implemented.

Without arguments, it will show the available commands:
```bash
$ zigbox
zigbox :)

Currently defined applets:
- cat
- sha256sum
```

## how to try

You can try `zigbox` in a chroot environment using the `chroot_test.sh` script.

The script will create a test directory and do all the needed symlink and then will try to do a chroot (may requires more privileges).

> You need to build the project first with `zig build`

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

