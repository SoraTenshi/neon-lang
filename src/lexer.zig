const std = @import("std");
const mem = std.mem;

const t = std.testing;

const parser = @import("parse_info.zig");
const stdout = std.io.getStdOut().writer();
const isWhitespace = std.ascii.isWhitespace;

pub const LexerError = error{
    InvalidToken,
    InvalidIdentifier,
    NoMatchingQuote,
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

        _ = std.meta.stringToEnum(parser.TokenType, lexer.source[start..end]) orelse return null;

        if (end + 1 > lexer.source.len) {
            return lexer.source[start..end];
        }

        const is_multi_token = std.meta.stringToEnum(parser.TokenType, lexer.source[start .. end + 1]);
        if (is_multi_token != null) {
            end += 1;
        }

        return lexer.source[start..end];
    }

    fn lookaheadString(lexer: *Lexer, consume: bool) ?[]const u8 {
        const c = lexer.source[lexer.position + lexer.look_ahead];
        const result = switch (c) {
            'a' => lexer.findToken("any"),
            'b' => lexer.findToken("bool"),
            'c' => lexer.findToken("cond"),
            'd' => lexer.findToken("do"),
            'e' => lexer.findToken("else"),
            'f' => lexer.findToken("false"),
            'i' => lexer.findToken("ignore"),
            'l' => lexer.findToken("let"),
            'm' => lexer.findToken("mut"),
            'n' => lexer.findToken("number"),
            'r' => lexer.findToken("return"),
            's' => lexer.findToken("string"),
            't' => lexer.findToken("true"),
            'u' => lexer.findToken("unique"),
            'w' => lexer.findToken("while"),
            else => lexer.lookaheadCharacter(),
        };

        if (consume) {
            lexer.position += (result orelse "").len;
        }
        return result;
    }

    fn parseLiteral(lexer: *Lexer, token: parser.TokenType) LexerError!?parser.Token {
        if (token != .@"\"") {
            return null;
        }

        var pointer = lexer.position + lexer.look_ahead;
        var escape = false;
        while (pointer < lexer.source.len) : (pointer += 1) {
            const current = lexer.source[pointer];

            if (current == '\r' or current == '\n') {
                return LexerError.NoMatchingQuote;
            }

            const last = if (pointer > 0) lexer.source[pointer - 1] else current;

            if (last == '\\') {
                escape = !escape;
            } else {
                escape = false;
            }

            const is_literal = !escape and current == '\"';
            if (!is_literal) {
                continue;
            } else {
                const old_pos = lexer.position;
                lexer.position = pointer + 1;
                return parser.Token{
                    .token = .str_literal,
                    .value = lexer.source[old_pos..pointer],
                    .start = old_pos,
                    .end = pointer,
                };
            }
        }

        return null;
    }

    fn isExistingToken(lexer: *Lexer) bool {
        const current_index = lexer.position + lexer.look_ahead;
        if (current_index > lexer.source.len) {
            return false;
        }

        const is_whitespace = isWhitespace(lexer.source[current_index]);
        const is_next_token = lexer.lookaheadString(false) != null;

        return !is_whitespace and !is_next_token;
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
        const parsedNumber = std.fmt.parseInt(isize, identifiable, 0) catch null;

        const identifiable_pos = lexer.position;
        lexer.position = ending_index;
        if (parsedNumber != null) {
            return parser.Token{
                .token = .num_literal,
                .value = identifiable,
                .start = identifiable_pos,
                .end = ending_index,
            };
        } else {
            for (identifiable) |current| {
                const is_dash_char = current == '-' and current == '_';
                if (!std.ascii.isAlphanumeric(current) and !is_dash_char) {
                    return LexerError.InvalidIdentifier;
                }
            }
            return parser.Token{
                .token = .identifier,
                .value = identifiable,
                .start = identifiable_pos,
                .end = ending_index,
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
            const found_what = std.meta.stringToEnum(parser.TokenType, lookahead);

            if (found_what) |found| {
                try tokens.append(.{
                    .token = found,
                    .value = "",
                    .start = lexer.position,
                    .end = lexer.position,
                });

                const literals = try lexer.parseLiteral(found);
                if (literals) |l| {
                    try tokens.append(l);
                    try tokens.append(parser.Token{
                        .token = .@"\"",
                        .value = "",
                        .start = lexer.position,
                        .end = lexer.position,
                    });
                }
            } else {
                const next_token = try nextToken(lexer);
                try tokens.append(next_token);
            }
        }

        return tokens.toOwnedSlice();
    }
};

test "Simple let mut tokenizer" {
    const str = "let mut abc = 1337;";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .let, .value = "", .start = 0, .end = 2 },
        .{ .token = .mut, .value = "", .start = 4, .end = 7 },
        .{ .token = .identifier, .value = "abc", .start = 9, .end = 12 },
        .{ .token = .@"=", .value = "", .start = 14, .end = 14 },
        .{ .token = .num_literal, .value = "1337", .start = 16, .end = 20 },
        .{ .token = .@";", .value = "", .start = 21, .end = 21 },
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
    const str = "let str: string = \"ab\\\"cd\";";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .let, .value = "", .start = 0, .end = 2 },
        .{ .token = .identifier, .value = "str", .start = 4, .end = 7 },
        .{ .token = .@":", .value = "", .start = 8, .end = 8 },
        .{ .token = .string, .value = "", .start = 10, .end = 15 },
        .{ .token = .@"=", .value = "", .start = 17, .end = 17 },
        .{ .token = .@"\"", .value = "", .start = 19, .end = 19 },
        .{ .token = .str_literal, .value = "ab\\\"cd", .start = 20, .end = 27 },
        .{ .token = .@"\"", .value = "", .start = 28, .end = 28 },
        .{ .token = .@";", .value = "", .start = 29, .end = 29 },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "command literal parsing" {
    const str = "let str: string = @\"ab\\\"cd\";";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .let, .value = "", .start = 0, .end = 2 },
        .{ .token = .identifier, .value = "str", .start = 4, .end = 6 },
        .{ .token = .@":", .value = "", .start = 7, .end = 7 },
        .{ .token = .string, .value = "", .start = 9, .end = 14 },
        .{ .token = .@"=", .value = "", .start = 16, .end = 16 },
        .{ .token = .@"@", .value = "", .start = 18, .end = 18 },
        .{ .token = .@"\"", .value = "", .start = 19, .end = 19 },
        .{ .token = .str_literal, .value = "ab\\\"cd", .start = 20, .end = 27 },
        .{ .token = .@"\"", .value = "", .start = 28, .end = 28 },
        .{ .token = .@";", .value = "", .start = 29, .end = 29 },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

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
        .{ .token = .identifier, .value = "main", .start = 0, .end = 3 },
        .{ .token = .@"::", .value = "", .start = 5, .end = 7 },
        .{ .token = .@"(", .value = "", .start = 8, .end = 8 },
        .{ .token = .@")", .value = "", .start = 9, .end = 9 },
        .{ .token = .@":", .value = "", .start = 11, .end = 11 },
        .{ .token = .string, .value = "", .start = 13, .end = 18 },
        .{ .token = .@"{", .value = "", .start = 20, .end = 20 },
        .{ .token = .@"}", .value = "", .start = 22, .end = 22 },
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

test "invalid token sequence" {
    const str = "++/::";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .@"+", .value = "", .start = 0, .end = 0 },
        .{ .token = .@"+", .value = "", .start = 1, .end = 1 },
        .{ .token = .@"/", .value = "", .start = 2, .end = 2 },
        .{ .token = .@"::", .value = "", .start = 3, .end = 5 },
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

test "arithmetic expression" {
    const str = "10 + 20 / 5 * 3 - 15 % 4";
    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .num_literal, .value = "10", .start = 0, .end = 1 },
        .{ .token = .@"+", .value = "", .start = 3, .end = 3 },
        .{ .token = .num_literal, .value = "20", .start = 5, .end = 6 },
        .{ .token = .@"/", .value = "", .start = 8, .end = 8 },
        .{ .token = .num_literal, .value = "5", .start = 10, .end = 11 },
        .{ .token = .@"*", .value = "", .start = 13, .end = 13 },
        .{ .token = .num_literal, .value = "3", .start = 15, .end = 16 },
        .{ .token = .@"-", .value = "", .start = 18, .end = 18 },
        .{ .token = .num_literal, .value = "15", .start = 20, .end = 22 },
        .{ .token = .@"%", .value = "", .start = 24, .end = 24 },
        .{ .token = .num_literal, .value = "4", .start = 26, .end = 27 },
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
        \\    cond(!str.empty()) {
        \\        true => print("Not Empty"),
        \\        false => ignore,
        \\    }
        \\}
    ;

    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .identifier, .value = "main", .start = 0, .end = 3 },
        .{ .token = .@"::", .value = "", .start = 5, .end = 7 },
        .{ .token = .@"(", .value = "", .start = 8, .end = 8 },
        .{ .token = .identifier, .value = "str", .start = 9, .end = 11 },
        .{ .token = .@":", .value = "", .start = 12, .end = 12 },
        .{ .token = .string, .value = "", .start = 13, .end = 19 },
        .{ .token = .@")", .value = "", .start = 20, .end = 20 },
        .{ .token = .@":", .value = "", .start = 21, .end = 21 },
        .{ .token = .string, .value = "", .start = 22, .end = 27 },
        .{ .token = .@"{", .value = "", .start = 28, .end = 28 },
        .{ .token = .cond, .value = "", .start = 30, .end = 33 },
        .{ .token = .@"(", .value = "", .start = 34, .end = 34 },
        .{ .token = .@"!", .value = "", .start = 35, .end = 35 },
        .{ .token = .identifier, .value = "str", .start = 36, .end = 38 },
        .{ .token = .@".", .value = "", .start = 39, .end = 39 },
        .{ .token = .identifier, .value = "empty", .start = 40, .end = 44 },
        .{ .token = .@"(", .value = "", .start = 45, .end = 45 },
        .{ .token = .@")", .value = "", .start = 46, .end = 46 },
        .{ .token = .@")", .value = "", .start = 47, .end = 47 },
        .{ .token = .@"{", .value = "", .start = 49, .end = 49 },
        .{ .token = .true, .value = "", .start = 51, .end = 54 },
        .{ .token = .@"=>", .value = "", .start = 55, .end = 56 },
        .{ .token = .identifier, .value = "print", .start = 58, .end = 62 },
        .{ .token = .@"(", .value = "", .start = 63, .end = 63 },
        .{ .token = .@"\"", .value = "", .start = 64, .end = 64 },
        .{ .token = .str_literal, .value = "Not Empty", .start = 65, .end = 73 },
        .{ .token = .@"\"", .value = "", .start = 74, .end = 74 },
        .{ .token = .@")", .value = "", .start = 75, .end = 75 },
        .{ .token = .@",", .value = "", .start = 69, .end = 69 },
        .{ .token = .false, .value = "", .start = 70, .end = 75 },
        .{ .token = .@"=>", .value = "", .start = 76, .end = 77 },
        .{ .token = .ignore, .value = "", .start = 78, .end = 84 },
        .{ .token = .@",", .value = "", .start = 85, .end = 85 },
        .{ .token = .@"}", .value = "", .start = 86, .end = 86 },
        .{ .token = .@"}", .value = "", .start = 87, .end = 87 },
    };

    const actual_tokens = try lexer.tokenize();
    defer lexer.alloc.free(actual_tokens);

    var value: usize = 0;
    while (value < expected_tokens.len) : (value += 1) {
        try t.expectEqual(expected_tokens[value].token, actual_tokens[value].token);
        try t.expectEqualStrings(expected_tokens[value].value, actual_tokens[value].value);
    }
}

test "comparison expression" {
    const str =
        \\cond(abc) {
        \\    >10 => print("abc"),
        \\    else => print("cool"),
        \\}
    ;

    var lexer = Lexer.init(t.allocator, str);

    const expected_tokens = &[_]parser.Token{
        .{ .token = .cond, .value = "", .start = 0, .end = 3 },
        .{ .token = .@"(", .value = "", .start = 4, .end = 4 },
        .{ .token = .identifier, .value = "abc", .start = 5, .end = 7 },
        .{ .token = .@")", .value = "", .start = 8, .end = 8 },
        .{ .token = .@"{", .value = "", .start = 9, .end = 9 },
        .{ .token = .@">", .value = "", .start = 11, .end = 12 },
        .{ .token = .num_literal, .value = "10", .start = 13, .end = 14 },
        .{ .token = .@"=>", .value = "", .start = 15, .end = 16 },
        .{ .token = .identifier, .value = "print", .start = 18, .end = 22 },
        .{ .token = .@"(", .value = "", .start = 23, .end = 23 },
        .{ .token = .@"\"", .value = "", .start = 24, .end = 24 },
        .{ .token = .str_literal, .value = "abc", .start = 25, .end = 27 },
        .{ .token = .@"\"", .value = "", .start = 28, .end = 28 },
        .{ .token = .@")", .value = "", .start = 29, .end = 29 },
        .{ .token = .@",", .value = "", .start = 30, .end = 30 },
        .{ .token = .@"else", .value = "", .start = 32, .end = 35 },
        .{ .token = .@"=>", .value = "", .start = 36, .end = 37 },
        .{ .token = .identifier, .value = "print", .start = 39, .end = 43 },
        .{ .token = .@"(", .value = "", .start = 44, .end = 44 },
        .{ .token = .@"\"", .value = "", .start = 45, .end = 45 },
        .{ .token = .str_literal, .value = "cool", .start = 46, .end = 49 },
        .{ .token = .@"\"", .value = "", .start = 50, .end = 50 },
        .{ .token = .@")", .value = "", .start = 51, .end = 51 },
        .{ .token = .@",", .value = "", .start = 52, .end = 52 },
        .{ .token = .@"}", .value = "", .start = 53, .end = 53 },
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
