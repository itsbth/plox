use v6;
use lib '.';
use Test;
use Parser;
use Interpreter;

sub test-binop(BinOpType $op, $a, $b, $expected) {
  my $ast = BinOp.new(
    :$op,
    :left(Literal.new :value($a)),
    :right(Literal.new :value($b))
  );
  my $interp = Interpreter.new;
  is $interp.evaluate($ast), $expected, "$op with $a and $b should be $expected";
}

plan 4;

test-binop BINOP_ADD, 1, 2, 3;
test-binop BINOP_SUB, 2, 1, 1;
test-binop BINOP_MUL, 2, 3, 6;
test-binop BINOP_DIV, 6, 3, 2;

done-testing;
