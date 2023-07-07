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

    // Types
    number, // <int>
    string, // <string>
    bool, // <bool>
    any, // <any>

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
    @"=>", // =>

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
    @"~", // ~

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
    ignore, // _
    cond, // cond
    @"else", // else
    true, // true
    false, // false
    @"return", // return
    let, // let
    mut, // mut
    unique, // unique
    do, // do
};
