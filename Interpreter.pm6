use Parser;

class Interpreter {
  multi method evaluate(BinOp $op) {
    return binop($op.op, self.evaluate($op.left), self.evaluate($op.right));
  }

  multi method evaluate(Literal $lit) {
    return $lit.value;
  }

  multi sub binop(BINOP_ADD, Numeric $a, Numeric $b) {
    return $a + $b;
  }

  multi sub binop(BINOP_ADD, Str $a, Str $b) {
    return $a ~ $b;
  }

  multi sub binop(BINOP_SUB, Numeric $a, Numeric $b) {
    return $a - $b;
  }
}
