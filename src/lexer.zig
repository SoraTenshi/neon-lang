const std = @import("std");
const t = std.testing;

const parser = @import("parseInfo.zig");
const stdout = std.io.getStdOut().writer();

pub const Lexer = struct {
    source: []const u8,
    character: u8,
    index: usize,
};

pub fn tokenize(alloc: std.mem.Allocator, code: []const u8) ![]parser.TokenType {
    var tokens = std.ArrayList(parser.TokenType).init(alloc);
    var tokenized = std.mem.tokenize(u8, code, " ");
    while (tokenized.next()) |token| {
        if (parser.keywords.has(token)) {
            try stdout.writeAll("\n");
            try stdout.writeAll(token);
            try tokens.append(parser.keywords.get(token).?);
        } else {
            // implement logik for non matches
            // (look ahead, look behind, resolve)
        }
    }

    return tokens.toOwnedSlice();
}

test "Simple let mut tokenizer" {
    const str = "let mut abc = 1337;";
    const expected_tokens = &[_]parser.TokenType{
        .let_kw,
        .mut_kw,
        .identifier,
        .equal,
        .number,
        .semicolon,
    };

    const actual_tokens = try tokenize(t.allocator, str);

    for (actual_tokens) |token| {
        try stdout.writeAll(@tagName(token));
        try stdout.writeAll("\n");
    }

    try t.expectEqual(expected_tokens.len, actual_tokens.len);
    try t.expectEqualSlices(parser.TokenType, expected_tokens, actual_tokens);
}
