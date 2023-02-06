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

    const Self = @This();

    pub fn init(alloc: mem.Allocator, src: []const u8) Self {
        return Self{
            .alloc = alloc,
            .tokens = std.ArrayList(parser.Token).init(alloc),
            .source = src,
            .position = 0,
        };
    }

    pub fn findToken(lexer: *Self, look_for: []const u8) ?[]const u8 {
        const end_index = lexer.position + look_for.len;
        if (lexer.source.len < lexer.position + end_index) {
            return null;
        }

        if (std.mem.eql(u8, look_for, lexer.source[lexer.position..end_index])) {
            lexer.position += look_for.len;
            return look_for;
        } else {
            return null;
        }
    }

    fn lookaheadString(lexer: *Lexer, c: u8, consume: bool) ?[]const u8 {
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
            else => |s| blk: {
                const as_str: []const u8 = &[_]u8{s};
                std.debug.print("token: {s}\n", .{as_str});
                const token = parser.keywords.get(as_str);
                if (token != null and consume) {
                    lexer.position += 1;
                }
                break :blk if (token == null) null else as_str;
            },
        };

        return result;
    }

    fn isExistingToken(lexer: *Lexer, read_ahead: usize) bool {
        const current_index = lexer.position + read_ahead;
        const is_whitespace = !isWhitespace(lexer.source[current_index]);
        const is_next_token = lookaheadString(lexer, lexer.source[current_index], false) == null;

        return is_whitespace and is_next_token;
    }

    fn nextToken(lexer: *Self) !parser.Token {
        var read_ahead: usize = 0;
        while ((lexer.source.len > lexer.position + read_ahead) and lexer.isExistingToken(read_ahead)) : (read_ahead += 1) {}

        if (lexer.position + read_ahead > lexer.source.len) {
            const formatted = try std.fmt.allocPrint(lexer.alloc, "Couldn't parse token at position: {d}\n", .{lexer.position - 1});
            defer lexer.alloc.free(formatted);
            try std.io.getStdErr().writer().writeAll(formatted);
            return LexerError.InvalidToken;
        }

        const identifiable = lexer.source[lexer.position .. lexer.position + read_ahead];
        const parsedNumber = std.fmt.parseInt(isize, identifiable, 10) catch null;

        lexer.position += read_ahead;
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

            if (isWhitespace(lexer.source[lexer.position])) {
                lexer.position += 1;
                continue;
            }

            std.debug.print("c = {c}\n", .{c});
            const found_what = parser.keywords.get(lexer.lookaheadString(c, true) orelse "");

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
    // pub fn findPair(lexer: *Self, look_for: []const u8, skip_next: bool) []const u8 {
    //     var rel_pos: usize = if (skip_next) 1 else 0;
    //     while (lexer.source.len > lexer.position + rel_pos) : (rel_pos += 1) {}
    // }
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

    for (actual_tokens) |token| {
        try stdout.writeAll(@tagName(token.token));
        try stdout.writeAll(" ------- value: ");

        try stdout.writeAll(token.value);
        try stdout.writeAll("\n");
    }

    try t.expectEqual(expected_tokens.len, actual_tokens.len);
    try t.expectEqualSlices(parser.Token, expected_tokens, actual_tokens);
}
