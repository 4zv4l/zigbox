pub inline fn flush(reader: anytype) !void {
    while (try reader.readByte() != '\n') {}
}
