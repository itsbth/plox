use v6;
use lib '.';
use Test;
use Parser;
use Interpreter;

plan 1;

my $ast = BinOp.new(
  :op(BINOP_ADD),
  :left(Literal.new :value(1.0)),
  :right(Literal.new :value(1.0))
);
my $interp = Interpreter.new;
ok $interp.evaluate($ast) eq 2, "should evaluate simple expression";

done-testing;
