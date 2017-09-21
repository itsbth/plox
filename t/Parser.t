use v6;
use Test;
use lib '.';
use Scanner;
use Parser;

sub test-parse(@tokens, $expected) {
  my $parser = Parser.new(:@tokens);
  is-deeply $parser.parse[0], $expected, "should parse token stream";
}

sub tok(TokenType $token, $literal = Nil) {
  return Token.new(:$token, :$literal, :position(-1));
}

plan 2;

test-parse (tok(T_NUMBER, 1), tok(T_PLUS), tok(T_NUMBER, 2), tok(T_SEMICOLON), tok(T_EOF)), BinOp.new(
  :op(BINOP_ADD),
  :left(Literal.new :value(1)),
  :right(Literal.new :value(2))
);

test-parse (tok(T_PRINT), tok(T_STRING, "Hello, World!"), tok(T_SEMICOLON), tok(T_EOF)), PrintStatement.new(
  :expr(Literal.new :value("Hello, World!")),
);

done-testing;
