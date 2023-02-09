const std = @import("std");
const t = std.testing;

pub const Token = struct {
    token: TokenType,
    value: []const u8,
};

pub const TokenType = enum(u8) {
    // Identifier
    identifier, // <any>

    // Type expression
    num_literal, // <number>
    str_literal, // <string>

    number, // <int>
    string, // <string> (type)

    // Literal
    quote,

    // Operator like
    operator, // see Operator
    dot, // .
    comma, // ,
    semicolon, // ;
    question, // ?
    bang, // !
    at, // @

    // Scopes
    left_paren, // (
    right_paren, // )
    left_brace, // {
    right_brace, // }
    left_bracket, // [
    right_bracket, // ]

    // Assignment
    equal, // =
    colon, // :
    fn_decl, // ::

    // Keywords
    if_kw, // if
    else_kw, // else
    for_kw, // for
    while_kw, // while
    true_kw, // true
    false_kw, // false
    return_kw, // return
    let_kw, // let
    mut_kw, // mut
    break_kw, // break
    continue_kw, // continue
};

pub const OperatorType = enum {
    // Arithmetic
    plus, // +
    minus, // -
    divide, // /
    multiply, // *
    modulo, // %

    // ??
    pipe_next, // |>
    falsy, // !

    // Comparison
    equality, // ==
    n_equality, // !=
    less, // <
    less_eq, // <=
    greater, // >
    greater_eq, // >=

    // Logic
    log_or, // ||
    log_and, // &&
};

pub const BinaryType = enum {
    // Bitwise
    bit_or, // |
    bit_and, // &
    bit_shf_right, // >>
    bit_shf_left, // <<
    xor, // ^
};

const UnaryType = enum {
    minus, // -
    plus, // +
    not, // ~
};

pub const keywords = std.ComptimeStringMap(TokenType, .{
    // Operator like
    .{ ".", .dot },
    .{ ",", .comma },
    .{ ";", .semicolon },
    .{ "?", .question },
    .{ "!", .bang },
    .{ "@", .at },

    // Literal
    .{ "\"", .quote },

    // Scopes
    .{ "(", .left_paren },
    .{ ")", .right_paren },
    .{ "{", .left_brace },
    .{ "}", .right_brace },
    .{ "[", .left_bracket },
    .{ "]", .right_bracket },

    // Assignment
    .{ "=", .equal },
    .{ ":", .colon },
    .{ "::", .fn_decl },

    // Keywords
    .{ "break", .break_kw },
    .{ "continue", .continue_kw },
    .{ "else", .else_kw },
    .{ "false", .false_kw },
    .{ "for", .for_kw },
    .{ "if", .if_kw },
    .{ "let", .let_kw },
    .{ "mut", .mut_kw },
    .{ "number", .number },
    .{ "return", .return_kw },
    .{ "string", .string },
    .{ "true", .true_kw },
    .{ "while", .while_kw },
});
