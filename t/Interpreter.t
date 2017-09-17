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
  CATCH { default { flunk "error evaluating $op"; } }
}

sub test-unop(UnOpType $op, $a, $expected) {
  my $ast = UnOp.new(
    :$op,
    :right(Literal.new :value($a))
  );
  my $interp = Interpreter.new;
  is $interp.evaluate($ast), $expected, "$op with $a should be $expected";
  CATCH { default { flunk "error evaluating $op"; } }
}

plan 10;

test-binop BINOP_ADD, 1, 2, 3;
test-binop BINOP_SUB, 2, 1, 1;
test-binop BINOP_MUL, 2, 3, 6;
test-binop BINOP_DIV, 6, 3, 2;

test-binop BINOP_GT, 6, 3, True;
test-binop BINOP_GE, 6, 3, True;
test-binop BINOP_LT, 6, 3, False;
test-binop BINOP_LE, 6, 3, False;

test-unop UNOP_NEGATE, 5, -5;
test-unop UNOP_NOT, True, False;

done-testing;
