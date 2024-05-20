#!/bin/sh

# copy zigbox into chroot test directory
mkdir -p test/bin
cp zig-out/bin/zigbox test/bin
cmds=$(./zig-out/bin/zigbox 2>&1 | grep -E '^-' | awk '{print $2}')

# creates all the links
cd test/bin
for cmd in $cmds; do
    ln -fs zigbox "$cmd"
done

cd ../..
chroot test /bin/sh
