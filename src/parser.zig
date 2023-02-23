const std = @import("std");

const tokenizer = struct {
    usingnamespace @import("lexer.zig");
    usingnamespace @import("parse_info.zig");
};

const Range = struct {
    start: usize,
    end: usize,
};

const Type = enum {
    Variable,
    Literal,
    Function,
};

pub const AstNode = struct {
    node_type: Type,
    range: Range,
    depth: usize,
    content: union(Type) {
        Function: struct {
            name: []const u8,
            parameters: ?[]AstNode,
            body: ?[]AstNode,
        },
        Variable: struct {
            name: []const u8,
        },
        Literal: struct {
            name: []const u8,
        },
    },
};

pub const Ast = struct {
    root: ?AstNode,
    alloc: std.mem.Allocator,
    tokens: std.ArrayList(tokenizer.Token),

    current_depth: usize,
    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, tokens: std.ArrayList(tokenizer.Token)) Self {
        return Self{
            .root = null,
            .alloc = alloc,
            .tokens = tokens,
            .current_depth = 0,
        };
    }

    fn generate_ast(self: *Self) !void {
        var root = self.root;
        if (root != null) {
            return;
        }
        for (self.tokens) |_| {}
    }
};

// const t = std.testing;
// test "basic tree build" {
//     const expected_tokens = &[_]tokenizer.Token{
//         .{ .token = .let, .value = "", .start = 0, .end = 2 },
//         .{ .token = .identifier, .value = "str", .start = 4, .end = 7 },
//         .{ .token = .@"=", .value = "", .start = 17, .end = 17 },
//         .{ .token = .identifier, .value = "init", .start = 19, .end = 24 },
//         .{ .token = .@"(", .value = "", .start = 25, .end = 25 },
//         .{ .token = .@"\"", .value = "", .start = 26, .end = 26 },
//         .{ .token = .str_literal, .value = "ab\\\"cd", .start = 27, .end = 34 },
//         .{ .token = .@"\"", .value = "", .start = 35, .end = 35 },
//         .{ .token = .@")", .value = "", .start = 36, .end = 36 },
//         .{ .token = .@";", .value = "", .start = 37, .end = 37 },
//     };
// }
