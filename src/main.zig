const std = @import("std");
const lexer = @import("parser.zig");

pub fn replMode(allocator: std.mem.Allocator) !void {
    const stdout_file = std.io.getStdOut().writer();
    const stdin_file = std.io.getStdIn().reader();

    var read = std.ArrayList(u8).init(allocator);
    while (true) {
        try stdout_file.writeAll("~> ");
        stdin_file.readUntilDelimiterArrayList(&read, '\n', 2048) catch |err| switch (err) {
            error.EndOfStream => {
                try stdout_file.writeAll("\nTerminated session\n");
                return;
            },
            else => return,
        };

        const read_slice = try read.toOwnedSlice();
        defer allocator.free(read_slice);

        try stdout_file.writeAll(read_slice);
        try stdout_file.writeAll("\n");
    }
}

pub fn main() !void {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = alloc.allocator();

    try replMode(allocator);
}
