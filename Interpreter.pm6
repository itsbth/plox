use Parser;

class Interpreter {
  multi method evaluate(BinOp $op) {
    given $op.op {
      when BINOP_ADD {
        return self.evaluate($op.left) + self.evaluate($op.right);
      }
    }
  }
  multi method evaluate(Literal $lit) {
    return $lit.value;
  }
}
