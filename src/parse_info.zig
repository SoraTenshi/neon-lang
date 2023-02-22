const std = @import("std");
const t = std.testing;

pub const Token = struct {
    token: TokenType,
    value: []const u8,
    start: usize,
    end: usize,
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
    @"\"", // "

    // Arithmetic
    @"+", // +
    @"-", // -
    @"/", // /
    @"*", // *
    @"%", // %

    // Stream
    @"|>", // |>
    @"~>", // ~>

    // Comparison
    @"==", // ==
    @"!=", // !=
    @"<", // <
    @"<=", // <=
    @">", // >
    @">=", // >=

    // Logic
    @"||", // ||
    @"&&", // &&

    // Operator like
    @".", // .
    @",", // ,
    @";", // ;
    @"?", // ?
    @"!", // !
    @"@", // @

    // Bitwise
    @"|", // |
    @"&", // &
    @">>", // >>
    @"<<", // <<
    @"^", // ^

    // Scopes
    @"(", // (
    @")", // )
    @"{", // {
    @"}", // }
    @"[", // [
    @"]", // ]

    // Assignment
    @"=", // =
    @":", // :
    @"::", // ::

    // Keywords
    @"if", // if
    @"else", // else
    @"for", // for
    @"while", // while
    true, // true
    false, // false
    @"return", // return
    let, // let
    mut, // mut
    @"break", // break
    @"continue", // continue
};

pub const keywords = std.ComptimeStringMap(TokenType, .{
    .{ "number", .number }, // <int>
    .{ "string", .string }, // <string> (type)

    // Literal
    .{ "\"", .@"\"" }, // """

    // Arithmetic
    .{ "+", .@"+" }, // +
    .{ "-", .@"-" }, // -
    .{ "/", .@"/" }, // /
    .{ "*", .@"*" }, // *
    .{ "%", .@"%" }, // %

    // Stream
    .{ "|>", .@"|>" }, // |>
    .{ "~>", .@"~>" }, // ~>

    // Comparison
    .{ "==", .@"==" }, // ==
    .{ "!=", .@"!=" }, // !=
    .{ "<", .@"<" }, // <
    .{ "<=", .@"<=" }, // <=
    .{ ">", .@">" }, // >
    .{ ">=", .@">=" }, // >=

    // Logic
    .{ "||", .@"||" }, // ||
    .{ "&&", .@"&&" }, // &&

    // Operator like
    .{ ".", .@"." }, // .
    .{ ",", .@"," }, // ,
    .{ ";", .@";" }, // ;
    .{ "?", .@"?" }, // ?
    .{ "!", .@"!" }, // !
    .{ "@", .@"@" }, // @

    // Bitwise
    .{ "|", .@"|" }, // |
    .{ "&", .@"&" }, // &
    .{ ">>", .@">>" }, // >>
    .{ "<<", .@"<<" }, // <<
    .{ "^", .@"^" }, // ^

    // Scopes
    .{ "(", .@"(" }, // (
    .{ ")", .@")" }, // )
    .{ "{", .@"{" }, // {
    .{ "}", .@"}" }, // }
    .{ "[", .@"[" }, // [
    .{ "]", .@"]" }, // ]

    // Assignment
    .{ "=", .@"=" }, // =
    .{ ":", .@":" }, // :
    .{ "::", .@"::" }, // ::

    // Keywords
    .{ "if", .@"if" }, // if
    .{ "else", .@"else" }, // else
    .{ "for", .@"for" }, // for
    .{ "while", .@"while" }, // while
    .{ "true", .true }, // true
    .{ "false", .false }, // false
    .{ "return", .@"return" }, // return
    .{ "let", .let }, // let
    .{ "mut", .mut }, // mut
    .{ "break", .@"break" }, // break
    .{ "continue", .@"continue" }, // continue
});
