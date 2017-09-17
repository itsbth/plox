use Scanner;

class Expr {
  
}

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

class BinOp does Expr {
  has Expr $.left is readonly;
  has Expr $.right is readonly;
  has BinOpType $.op is readonly;
}

enum UnOpType <UNOP_NEGATE UNOP_NOT>;

constant TokenToUnOp = :{
  (T_MINUS) => UNOP_NEGATE,
  (T_BANG) => UNOP_NOT,
};

class UnOp does Expr {
  has Expr $.right is readonly;
  has UnOpType $.op is readonly;
}

class Literal does Expr {
  has Any $.value is readonly;
}

class Parser {
  has Token @.tokens is readonly;
  has Int $!current = 0;

  method parse() {
    return self!expression();
  }

  method !expression() {
    return self!equality();
  }

  method !equality() {
    my $lhs = self!comparison();
    while self!match(T_EQUAL_EQUAL | T_BANG_EQUAL) {
      self!previous.say;
      TokenToBinOp.say;
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!comparison();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !comparison() {
    my $lhs = self!addition();
    while self!match(T_PLUS | T_MINUS) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!addition();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !addition() {
    my $lhs = self!multiplication();
    while self!match(T_PLUS | T_MINUS) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!multiplication();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !multiplication() {
    my $lhs = self!unary();
    while self!match(T_STAR | T_SLASH) {
      my $op = TokenToBinOp{self!previous.token};
      my $rhs = self!unary();
      $lhs = BinOp.new(left => $lhs, right => $rhs, op => $op);
    }
    return $lhs;
  }

  method !unary() {
    if self!match(T_MINUS | T_BANG) {
      my $op = TokenToUnOp{self!previous.token};
      my $rhs = self!primary;
      return UnOp.new(op => $op, right => $rhs);
    }
    return self!primary;
  }

  method !primary() {
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
    if self!match(T_LEFT_PAREN) {
      return self!expression;
      LEAVE self!consume(T_RIGHT_PAREN);
    }
  }

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
}
