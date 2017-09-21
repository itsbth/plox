use Scanner;

class Node {}

class Expr is Node {}

enum BinOpType <
  BINOP_ADD BINOP_SUB BINOP_MUL BINOP_DIV
  BINOP_EQ BINOP_NE
  BINOP_GT BINOP_GE BINOP_LT BINOP_LE
>;

constant TokenToBinOp = :{
  (T_EQUAL_EQUAL) => BINOP_EQ,
  (T_BANG_EQUAL) => BINOP_NE,
  (T_GREATER) => BINOP_GT,
  (T_GREATER_EQUAL) => BINOP_GE,
  (T_LESS) => BINOP_LT,
  (T_LESS_EQUAL) => BINOP_LE,
  (T_PLUS) => BINOP_ADD,
  (T_MINUS) => BINOP_SUB,
  (T_STAR) => BINOP_MUL,
  (T_SLASH) => BINOP_DIV,
};

class BinOp is Expr {
  has Expr $.left is readonly;
  has Expr $.right is readonly;
  has BinOpType $.op is readonly;
}

enum LogicalType <LOGICAL_OR LOGICAL_AND>;

constant TokenToLogical = :{
  (T_OR) => LOGICAL_OR,
  (T_AND) => LOGICAL_AND,
};

class Logical is Expr {
  has Expr $.left is readonly;
  has Expr $.right is readonly;
  has LogicalType $.op is readonly;
}

enum UnOpType <UNOP_NEGATE UNOP_NOT>;

constant TokenToUnOp = :{
  (T_MINUS) => UNOP_NEGATE,
  (T_BANG) => UNOP_NOT,
};

class UnOp is Expr {
  has Expr $.right is readonly;
  has UnOpType $.op is readonly;
}

class Literal is Expr {
  has Any $.value is readonly;
}

class Variable is Expr {
  has Str $.name is readonly;
}

class Assignment is Expr {
  has Variable $.target is readonly;
  has Expr $.value is readonly;
}

class Call is Expr {
  has Expr $.func is readonly;
  has Expr @.args is readonly;
}

class Statement is Node {}

class ExpressionStatement is Statement {
  has $.expr is readonly;
}

class PrintStatement is Statement {
  has Expr $.expr is readonly;
}

class VarStatement is Statement {
  has Str $.name is readonly;
  has Expr $.init is readonly;
}

class FunStatement is Statement {
  has Str $.name is readonly;
  has Str @.bindings is readonly;
  has Statement @.body is readonly;
}

class ReturnStatement is Statement {
  has Expr $.expr is readonly;
}

class Block is Statement {
  has Statement @.statements is readonly;
}

class IfStatement is Statement {
  has Expr $.cond is readonly;
  has Statement $.if-true is readonly;
  has Statement $.if-false is readonly;
}

class WhileStatement is Statement {
  has Expr $.cond is readonly;
  has Statement $.body is readonly;
}

class Parser {
  has Token @.tokens is readonly;
  has Int $!current = 0;

  method parse() {
    return do while not self!isAtEnd and self!peek.token != T_EOF {
      self!declaration
    };
  }

  # PARSER

  method !declaration() {
    if self!match(T_VAR) {
      return self!parse-var;
    }
    if self!match(T_FUN) {
      return self!parse-fun;
    }
    return self!statement;
  }

  method !statement() {
    if self!match(T_PRINT) {
      my $expr = self!expression;
      my $print = PrintStatement.new(:$expr);
      self!consume(T_SEMICOLON);
      return $print;
    }
    if self!match(T_IF) {
      self!consume(T_LEFT_PAREN);
      my $cond = self!expression;
      self!consume(T_RIGHT_PAREN);
      my $if-true = self!statement;
      my Statement $if-false;
      $if-false = self!statement if self!match(T_ELSE);
      return IfStatement.new(:$cond, :$if-true, :$if-false);
    }
    if self!match(T_WHILE) {
      self!consume(T_LEFT_PAREN);
      my $cond = self!expression;
      self!consume(T_RIGHT_PAREN);
      my $body = self!statement;
      return WhileStatement.new(:$cond, :$body);
    }
    if self!match(T_FOR) {
      self!consume(T_LEFT_PAREN);
      my $init;
      my $cond;
      my $inc;
      my $body;
      if self!match(T_VAR) {
        $init = self!parse-var;
      } elsif not self!match(T_SEMICOLON) {
        $init = ExpressionStatement.new(:expr(self!expression));
        self!consume(T_SEMICOLON);
      }
      $cond = self!expression;
      self!consume(T_SEMICOLON);
      if not self!match(T_RIGHT_PAREN) {
        $inc = ExpressionStatement.new(:expr(self!expression));
        self!consume(T_RIGHT_PAREN);
      }
      $body = self!statement;
      if $inc {
        if not $body ~~ Block {
          $body = Block.new :statements($body);
        }
        $body.statements.push($inc);
      }
      my $loop = WhileStatement.new(:$cond, :$body);
      if $init {
        $loop = Block.new :statements($init, $loop);
      }
      return $loop;
    }
    if self!match(T_LEFT_BRACE) {
      my @statements = do while not self!match(T_RIGHT_BRACE) {
        self!declaration;
      }
      return Block.new(:@statements);
    }
    if self!match(T_RETURN) {
      my $expr = self!expression;
      self!consume(T_SEMICOLON);
      return ReturnStatement.new(:$expr);
    }
    my $expr = self!expression;
    self!consume(T_SEMICOLON);
    return ExpressionStatement.new(:$expr);
  }

  method !expression() returns Expr {
    return self!assignment;
  }

  method !assignment() returns Expr {
    my $lhs = self!or;
    if self!match(T_EQUAL) {
      die "Left hand side of assignment must be an lvalue at $(self!peek.position)" if not is-lvalue($lhs);
      my $rhs = self!expression;
      return Assignment.new(:target($lhs), :value($rhs));
    }
    return $lhs;
  }

  method !or() returns Expr {
    my $lhs = self!and;
    while self!match(T_OR) {
      my $rhs = self!and;
      $lhs = Logical.new(:left($lhs), :right($rhs), :op(LOGICAL_OR));
    }
    return $lhs;
  }

  method !and() returns Expr {
    my $lhs = self!equality;
    while self!match(T_AND) {
      my $rhs = self!equality;
      $lhs = Logical.new(:left($lhs), :right($rhs), :op(LOGICAL_AND));
    }
    return $lhs;
  }

  method !equality() returns Expr {
    my $lhs = self!comparison();
    while self!match(T_EQUAL_EQUAL | T_BANG_EQUAL) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!comparison();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !comparison() returns Expr {
    my $lhs = self!addition();
    while self!match(T_LESS | T_LESS_EQUAL | T_GREATER | T_GREATER_EQUAL) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!addition();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !addition() returns Expr {
    my $lhs = self!multiplication();
    while self!match(T_PLUS | T_MINUS) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!multiplication();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !multiplication() returns Expr {
    my $lhs = self!unary();
    while self!match(T_STAR | T_SLASH) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!unary();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !unary() returns Expr {
    if self!match(T_MINUS | T_BANG) {
      my $op = TokenToUnOp{self!previous.token};
      my $rhs = self!call;
      return UnOp.new(op => $op, right => $rhs);
    }
    return self!call;
  }

  method !call() returns Expr {
    my $lhs = self!primary;
    if self!match(T_LEFT_PAREN) {
      my @args;
      if not self!match(T_RIGHT_PAREN) {
        repeat {
          @args.push(self!expression);
        } while self!match(T_COMMA);
        self!consume(T_RIGHT_PAREN);
      }
      return Call.new(:func($lhs), :@args);
    }
    return $lhs;
  }

  method !primary() returns Expr {
    if self!match(T_NUMBER | T_STRING) {
      return Literal.new :value(self!previous.literal);
    }
    if self!match(T_TRUE) {
      return Literal.new :value(True);
    }
    if self!match(T_FALSE) {
      return Literal.new :value(False);
    }
    if self!match(T_NIL) {
      return Literal.new :value(Nil);
    }
    if self!match(T_IDENTIFIER) {
      return Variable.new :name(self!previous.lexeme);
    }
    if self!match(T_LEFT_PAREN) {
      my $expr = self!expression;
      self!consume(T_RIGHT_PAREN);
      return $expr;
    }
    die "$(self!peek.token) found while looking for expression at $(self!peek.position)";
  }

  # PARSER HELPERS
  # Most expect the first token to already have been consumed

  method !parse-var() {
    self!consume(T_IDENTIFIER);
    my $name = self!previous.lexeme;
    my $init = self!match(T_EQUAL) ?? self!expression !! Literal.new(:value(Nil));
    self!consume(T_SEMICOLON);
    return VarStatement.new(:$name, :$init);
  }

  method !parse-fun() {
      # next if not self!match(T_IDENTIFIER); # anonymous / expression function, skip
      self!consume(T_IDENTIFIER);
      my $name = self!previous.lexeme;
      self!consume(T_LEFT_PAREN);
      my @bindings;
      if not self!match(T_RIGHT_PAREN) {
        repeat {
          self!consume(T_IDENTIFIER);
          @bindings.push(self!previous.lexeme);
        } while self!match(T_COMMA);
        self!consume(T_RIGHT_PAREN);
      }
      self!consume(T_LEFT_BRACE);
      my @body;
      while not self!match(T_RIGHT_BRACE) {
        @body.push(self!declaration);
      }
      return FunStatement.new(:$name, :@bindings, :@body);
  }


  # TOKEN STREAM HELPERS

  method !match(TokenType $type) {
    if self!isAtEnd() { return False;  }
    if self!check($type) {
      self!advance();
      return True;
    }
    return False;
  }

  method !consume(TokenType $type) {
    if self!check($type) {
      return self!advance;
    }
    die "Expected $type at $(self!peek.position), found $(self!peek.token)";
  }
  
  method !check(TokenType $type) {
    if self!isAtEnd() { return False;  }
    return so self!peek.token == $type;
  }

  method !advance() {
    $!current += 1;
  }

  method !peek() {
    return @.tokens[$!current];
  }

  method !previous() {
    return @.tokens[$!current - 1];
  }

  method !isAtEnd() {
    return $!current >= @.tokens.elems;
  }

  # MISC HELPERS

  sub is-lvalue(Expr $e) {
    return $e ~~ Variable;
  }
}
