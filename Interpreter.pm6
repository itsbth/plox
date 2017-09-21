use Parser;

class Scope {
  has %!vars;
  has Scope $.parent is readonly;

  method add(Str $key, $value) {
    %!vars{$key} = $value;
  }

  method set(Str $key, $value) {
    when %!vars{$key}:exists {
      %!vars{$key} = $value;
    }
    when $.parent.defined {
      $.parent.set($key, $value);
    }
    die "Trying to assign to unknown key $key";
  }

  method get(Str $key) {
    when %!vars{$key}:exists {
      return %!vars{$key};
    }
    when $.parent.defined {
      $.parent.get($key);
    }
    die "Trying to read unknown key $key";
  }

  method nest() {
    return Scope.new :parent(self);
  }

  method unnest() {
    return $.parent;
  }
}

# Forward declaration
class Interpreter { ... }

class ReturnFlow is Exception {
  has $.value is readonly;
}

role LoxCallable {
  has Int $.arity is readonly;
  method call(Interpreter, @args) { ...  }
}

class NativeFunction does LoxCallable {
  has &.func is readonly;
  method call(Interpreter $interp, @args) {
    my &fn = &.func;
    return &fn(|@args);
  }
  submethod define(&func) {
    return NativeFunction.new(:arity(&func.arity), :&func);
  }
}

class LoxFunction does LoxCallable {
  has Scope $.closure;
  has Str @.bindings;
  has Statement @.body;

  method call(Interpreter $interp, @args) {
    $interp.with-scope: self.closure.nest, -> $scope {
      for @.bindings Z @args -> [$k, $v] {
        $scope.add($k, $v);
      }
      for @.body { $interp.execute($_); }
      CATCH {
        when ReturnFlow {
          return .value;
        }
      }
    }
  }
}

class Interpreter {
  has Scope $!env = Scope.new;

  method init() {
    $!env.add("square", NativeFunction.define: { $_ ** 2 });
  }

  method with-scope(Scope $env, &block) {
    my $old = $!env;
    $!env = $env;
    LEAVE $!env = $old;
    my $ret = &block($env);
    return $ret;
  }

  multi method execute(Statement @program) {
    for @program {
      self.execute($^statement);
    }
  }

  multi method execute(ExpressionStatement $expr) {
    self.evaluate($expr.expr);
  }

  multi method execute(PrintStatement $stmt) {
    say self.evaluate($stmt.expr);
  }

  multi method execute(VarStatement $var) {
    $!env.add($var.name, self.evaluate($var.init));
  }

  multi method execute(FunStatement $fun) {
    $!env.add($fun.name,
      LoxFunction.new(:closure($!env), :bindings($fun.bindings),
        :body($fun.body), :arity($fun.bindings.elems)));
  }

  multi method execute(ReturnStatement $ret) {
    die ReturnFlow.new :value(self.evaluate($ret.expr));
  }

  multi method execute(IfStatement $stmt) {
    if self.evaluate($stmt.cond) {
      self.execute($stmt.if-true);
    } elsif $stmt.if-false.defined {
      self.execute($stmt.if-false);
    }
  }

  multi method execute(WhileStatement $stmt) {
    while self.evaluate($stmt.cond) {
      self.execute($stmt.body);
    }
  }

  multi method execute(Block $block) {
    self.with-scope: $!env.nest, {
      for $block.statements {
        self.execute($^statement);
      }
    }
  }

  multi method execute(Expr $expr) {
    return self.evaluate($expr);
  }

  multi method evaluate(BinOp $op) {
    return binop($op.op, self.evaluate($op.left), self.evaluate($op.right));
  }
  
  multi method evaluate(UnOp $op) {
    return unop($op.op, self.evaluate($op.right));
  }

  multi method evaluate(Logical $op where $op.op == LOGICAL_OR) {
    return self.evaluate($op.left) or self.evaluate($op.right);
  }

  multi method evaluate(Logical $op where $op.op == LOGICAL_AND) {
    return self.evaluate($op.left) and self.evaluate($op.right);
  }

  multi method evaluate(Assignment $ass) {
    my $val = self.evaluate($ass.value);
    $!env.set($ass.target.name, $val);
    return $val;
  }

  multi method evaluate(Call $call) {
    my $fn = self.evaluate($call.func);
    my @args = $call.args.map: { self.evaluate($_) };
    die "Unable to call $fn" unless $fn ~~ LoxCallable;
    return $fn.call(self, @args);
  }

  multi method evaluate(Literal $lit) {
    return $lit.value;
  }

  multi method evaluate(Variable $var) {
    return $!env.get($var.name);
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

  multi sub binop(BINOP_MUL, Numeric $a, Numeric $b) {
    return $a * $b;
  }

  multi sub binop(BINOP_DIV, Numeric $a, Numeric $b) {
    return $a / $b;
  }

  multi sub binop(BINOP_GT, Numeric $a, Numeric $b) {
    return $a > $b;
  }

  multi sub binop(BINOP_GE, Numeric $a, Numeric $b) {
    return $a >= $b;
  }

  multi sub binop(BINOP_LT, Numeric $a, Numeric $b) {
    return $a < $b;
  }

  multi sub binop(BINOP_LE, Numeric $a, Numeric $b) {
    return $a <= $b;
  }

  multi sub unop(UNOP_NEGATE, Numeric $a) {
    return -$a;
  }

  multi sub unop(UNOP_NOT, Numeric $a) {
    return !$a;
  }

}
