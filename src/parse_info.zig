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

    // Arithmetic
    plus, // +
    minus, // -
    divide, // /
    multiply, // *
    modulo, // %

    // Stream
    pipe_next, // |>
    pipe_err, // ~>

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

    // Operator like
    operator, // see Operator
    dot, // .
    comma, // ,
    semicolon, // ;
    question, // ?
    bang, // !
    at, // @

    // Bitwise
    bit_or, // |
    bit_and, // &
    bit_shf_right, // >>
    bit_shf_left, // <<
    xor, // ^

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

pub const keywords = std.ComptimeStringMap(TokenType, .{
    .{ "number", .number }, // <int>
    .{ "string", .string }, // <string> (type)

    // Literal
    .{ "\"", .quote }, // """

    // Arithmetic
    .{ "+", .plus }, // +
    .{ "-", .minus }, // -
    .{ "/", .divide }, // /
    .{ "*", .multiply }, // *
    .{ "%", .modulo }, // %

    // Stream
    .{ "|>", .pipe_next }, // |>
    .{ "~>", .pipe_err }, // ~>

    // Comparison
    .{ "==", .equality }, // ==
    .{ "!=", .n_equality }, // !=
    .{ "<", .less }, // <
    .{ "<=", .less_eq }, // <=
    .{ ">", .greater }, // >
    .{ ">=", .greater_eq }, // >=

    // Logic
    .{ "||", .log_or }, // ||
    .{ "&&", .log_and }, // &&

    // Operator like
    .{ "Operator", .operator }, // see Operator
    .{ ".", .dot }, // .
    .{ ",", .comma }, // ,
    .{ ";", .semicolon }, // ;
    .{ "?", .question }, // ?
    .{ "!", .bang }, // !
    .{ "@", .at }, // @

    // Bitwise
    .{ "|", .bit_or }, // |
    .{ "&", .bit_and }, // &
    .{ ">>", .bit_shf_right }, // >>
    .{ "<<", .bit_shf_left }, // <<
    .{ "^", .xor }, // ^

    // Scopes
    .{ "(", .left_paren }, // (
    .{ ")", .right_paren }, // )
    .{ "{", .left_brace }, // {
    .{ "}", .right_brace }, // }
    .{ "[", .left_bracket }, // [
    .{ "]", .right_bracket }, // ]

    // Assignment
    .{ "=", .equal }, // =
    .{ ":", .colon }, // :
    .{ "::", .fn_decl }, // ::

    // Keywords
    .{ "if", .if_kw }, // if
    .{ "else", .else_kw }, // else
    .{ "for", .for_kw }, // for
    .{ "while", .while_kw }, // while
    .{ "true", .true_kw }, // true
    .{ "false", .false_kw }, // false
    .{ "return", .return_kw }, // return
    .{ "let", .let_kw }, // let
    .{ "mut", .mut_kw }, // mut
    .{ "break", .break_kw }, // break
    .{ "continue", .continue_kw }, // continue
});
