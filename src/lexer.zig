const std = @import("std");
const mem = std.mem;

const t = std.testing;

const parser = @import("parseInfo.zig");
const stdout = std.io.getStdOut().writer();
const isWhitespace = std.ascii.isWhitespace;

pub const LexerError = error{
    InvalidToken,
};

pub const Lexer = struct {
    alloc: std.mem.Allocator,

    tokens: std.ArrayList(parser.Token),
    source: []const u8,
    position: usize,
    look_ahead: usize,

    const Self = @This();

    pub fn init(alloc: mem.Allocator, src: []const u8) Self {
        return Self{
            .alloc = alloc,
            .tokens = std.ArrayList(parser.Token).init(alloc),
            .source = src,
            .position = 0,
            .look_ahead = 0,
        };
    }

    pub fn findToken(lexer: *Self, look_for: []const u8) ?[]const u8 {
        const end_index = lexer.position + look_for.len;
        if (lexer.source.len < end_index) {
            return null;
        }

        if (std.mem.eql(u8, look_for, lexer.source[lexer.position..end_index])) {
            return look_for;
        } else {
            return null;
        }
    }

    fn lookaheadCharacter(lexer: *Lexer) ?[]const u8 {
        const start = lexer.position + lexer.look_ahead;
        var end = start + 1;

        var has_token = parser.keywords.has(lexer.source[start..end]);
        if (!has_token) {
            return null;
        }

        if (lexer.source.len <= end + 1) {
            return lexer.source[start..end];
        }

        const is_multi_token = parser.keywords.has(lexer.source[start .. end + 1]);
        if (is_multi_token) {
            end += 1;
        }

        return lexer.source[start..end];
    }

    fn lookaheadString(lexer: *Lexer, consume: bool) ?[]const u8 {
        const c = lexer.source[lexer.position + lexer.look_ahead];
        const result = switch (c) {
            'b' => lexer.findToken("break"),
            'c' => lexer.findToken("continue"),
            'e' => lexer.findToken("else"),
            'f' => if (lexer.findToken("for") == null) "for" else lexer.findToken("false"),
            'i' => lexer.findToken("if"),
            'l' => lexer.findToken("let"),
            'm' => lexer.findToken("mut"),
            'n' => lexer.findToken("number"),
            'r' => lexer.findToken("return"),
            's' => lexer.findToken("string"),
            't' => lexer.findToken("true"),
            'w' => lexer.findToken("while"),
            else => lexer.lookaheadCharacter(),
        };

        if (consume) {
            lexer.position += (result orelse "").len;
        }
        return result;
    }

    fn isExistingToken(lexer: *Lexer) bool {
        const current_index = lexer.position + lexer.look_ahead;
        const is_whitespace = !isWhitespace(lexer.source[current_index]);
        const is_next_token = lexer.lookaheadString(false) == null;

        return is_whitespace and is_next_token;
    }

    fn nextToken(lexer: *Self) !parser.Token {
        defer lexer.look_ahead = 0;

        while ((lexer.source.len > lexer.position + lexer.look_ahead) and lexer.isExistingToken()) {
            lexer.look_ahead += 1;
        }
        const ending_index = lexer.position + lexer.look_ahead;

        if (lexer.source.len < ending_index) {
            const formatted = try std.fmt.allocPrint(lexer.alloc, "Couldn't parse token at position: {d}\n", .{lexer.position - 1});
            defer lexer.alloc.free(formatted);
            try std.io.getStdErr().writer().writeAll(formatted);
            return LexerError.InvalidToken;
        }

        const identifiable = lexer.source[lexer.position..ending_index];
        const parsedNumber = std.fmt.parseInt(isize, identifiable, 10) catch null;

        lexer.position = ending_index;
        if (parsedNumber != null) {
            return parser.Token{
                .token = .number,
                .value = identifiable,
            };
        } else {
            return parser.Token{
                .token = .identifier,
                .value = identifiable,
            };
        }
    }

    pub fn tokenize(lexer: *Lexer) ![]parser.Token {
        var tokens = std.ArrayList(parser.Token).init(lexer.alloc);
        defer tokens.deinit();

        while (lexer.position < lexer.source.len) {
            const c = lexer.source[lexer.position];

            if (isWhitespace(c)) {
                lexer.position += 1;
                continue;
            }

            const lookahead = lexer.lookaheadString(true) orelse "";
            const found_what = parser.keywords.get(lookahead);

            if (found_what == null) {
                try tokens.append(try nextToken(lexer));
            } else {
                try tokens.append(.{
                    .token = found_what.?,
                    .value = "",
                });
            }
        }

        return tokens.toOwnedSlice();
    }
};

test "Simple let mut tokenizer" {
    const str = "let mut abc = 1337;";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .let_kw, .value = "" },
        .{ .token = .mut_kw, .value = "" },
        .{ .token = .identifier, .value = "abc" },
        .{ .token = .equal, .value = "" },
        .{ .token = .number, .value = "1337" },
        .{ .token = .semicolon, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "= parsing" {
    const str = "=";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .equal, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "' = ' parsing" {
    const str = " = ";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .equal, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "string literal parsing" {
    const str = "let str: string = \"abc\";";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .let_kw, .value = "" },
        .{ .token = .identifier, .value = "str" },
        .{ .token = .colon, .value = "" },
        .{ .token = .string, .value = "" },
        .{ .token = .equal, .value = "" },
        .{ .token = .quote, .value = "" },
        .{ .token = .identifier, .value = "abc" },
        .{ .token = .quote, .value = "" },
        .{ .token = .semicolon, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "function decl with body" {
    const str = "main :: (): string {\n}";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .identifier, .value = "main" },
        .{ .token = .fn_decl, .value = "" },
        .{ .token = .left_paren, .value = "" },
        .{ .token = .right_paren, .value = "" },
        .{ .token = .colon, .value = "" },
        .{ .token = .string, .value = "" },
        .{ .token = .left_brace, .value = "" },
        .{ .token = .right_brace, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "function mix with parameters" {
    const str =
        \\main :: (str: string): string {
        \\    if(!str.empty()) {
        \\        print("Not Empty");
        \\    }
        \\}
    ;
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .identifier, .value = "main" },
        .{ .token = .fn_decl, .value = "" },
        .{ .token = .left_paren, .value = "" },
        .{ .token = .identifier, .value = "str" },
        .{ .token = .colon, .value = "" },
        .{ .token = .string, .value = "" },
        .{ .token = .right_paren, .value = "" },
        .{ .token = .colon, .value = "" },
        .{ .token = .string, .value = "" },
        .{ .token = .left_brace, .value = "" },
        .{ .token = .if_kw, .value = "" },
        .{ .token = .left_paren, .value = "" },
        .{ .token = .bang, .value = "" },
        .{ .token = .identifier, .value = "str" },
        .{ .token = .dot, .value = "" },
        .{ .token = .identifier, .value = "empty" },
        .{ .token = .left_paren, .value = "" },
        .{ .token = .right_paren, .value = "" },
        .{ .token = .right_paren, .value = "" },
        .{ .token = .left_brace, .value = "" },
        .{ .token = .identifier, .value = "print" },
        .{ .token = .left_paren, .value = "" },
        .{ .token = .quote, .value = "" },
        .{ .token = .identifier, .value = "Not" },
        .{ .token = .identifier, .value = "Empty" },
        .{ .token = .quote, .value = "" },
        .{ .token = .right_paren, .value = "" },
        .{ .token = .semicolon, .value = "" },
        .{ .token = .right_brace, .value = "" },
        .{ .token = .right_brace, .value = "" },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    try t.expectEqual(expected_tokens.len, actual_tokens.len);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}
