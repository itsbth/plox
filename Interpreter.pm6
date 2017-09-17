use Parser;

class Interpreter {
  multi method evaluate(BinOp $op) {
    return binop($op.op, self.evaluate($op.left), self.evaluate($op.right));
  }

  multi method evaluate(Literal $lit) {
    return $lit.value;
  }

  multi sub binop(BINOP_ADD, Num $a, Num $b) {
    return $a + $b;
  }

  multi sub binop(BINOP_ADD, Str $a, Str $b) {
    return $a ~ $b;
  }

  multi sub binop(BINOP_SUB, Num $a, Num $b) {
    return $a - $b;
  }
}
