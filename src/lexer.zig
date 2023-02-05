const std = @import("std");
const t = std.testing;

const parser = @import("parseInfo.zig");

pub const Lexer = struct {
    source: []const u8,
    character: u8,
    index: usize,
};

pub fn tokenize(alloc: std.mem.Allocator, code: []const u8) ![]parser.Token {
    var tokens = std.ArrayList(parser.Token).init(alloc);
    var tokenized = std.mem.tokenize(u8, code, " ");
    while (tokenized.next()) |token| {}
}

test "Simple let mut tokenizer" {
    const str = "let mut abc = 1337;";
    const expected_tokens = &[_]parser.Token{
        .let_kw,
        .mut_kw,
        .identifier,
        .equal,
        .number,
        .semicolon,
    };

    const actual_tokens = try tokenize(str);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);
    try t.expectEqualSlices(parser.Token, expected_tokens, actual_tokens);
}
