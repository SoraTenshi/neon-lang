const std = @import("std");

const tokenizer = struct {
    usingnamespace @import("lexer.zig");
    usingnamespace @import("parse_info.zig");
};

const Range = struct {
    start: usize,
    end: usize,
};

// TODO: think about the pipes
const Type = enum {
    Variable,
    Literal,
    Function,
};

// TODO: investigate whether it makes sense to create new enum types based on the
// token? like unary ops, pipes, basically any token that may have any influence
// on the AST.
pub const AstNode = union(enum) {
    number_literal: i64,
    string_literal: []const u8,
    bool_literal: bool,
    identifier: []const u8,

    function_declaration: struct {
        name: []const u8,
        parameters: std.ArrayList([]const u8),
        body: std.ArrayList(*AstNode),
    },

    function_call: struct {
        name: []const u8,
        arguments: std.ArrayList(*AstNode),
    },

    return_statement: *AstNode,

    conditional_statement: struct {
        condition: *AstNode,
        then_branch: std.ArrayList(*AstNode),
        else_branch: std.ArrayList(*AstNode),
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
        // TODO: implement
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
