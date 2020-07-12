enum TokenType <
  T_LEFT_PAREN T_RIGHT_PAREN T_LEFT_BRACE T_RIGHT_BRACE
  T_COMMA T_DOT T_MINUS T_PLUS T_SEMICOLON T_SLASH T_STAR

  T_BANG T_BANG_EQUAL
  T_EQUAL T_EQUAL_EQUAL
  T_GREATER T_GREATER_EQUAL
  T_LESS T_LESS_EQUAL

  T_IDENTIFIER T_STRING T_NUMBER

  T_AND T_CLASS T_ELSE T_FALSE T_FUN T_FOR T_IF T_NIL T_OR
  T_PRINT T_RETURN T_SUPER T_THIS T_TRUE T_VAR T_WHILE

  T_EOF
>;

constant Identifers = {
  and => T_AND, class => T_CLASS,
  else => T_ELSE, false => T_FALSE,
  fun => T_FUN, for => T_FOR,
  if => T_IF, nil => T_NIL,
  or => T_OR, print => T_PRINT,
  return => T_RETURN, super => T_SUPER,
  this => T_THIS, true => T_TRUE,
  var => T_VAR, while => T_WHILE,
};

class Token {
  has TokenType $.token is readonly;
  has Str $.lexeme is readonly;
  has Any $.literal is readonly;
  has Int $.position is readonly;
}

class Scanner {
  has Str $.source is readonly;
  has Token @!tokens;

  has Int $!start = 0;
  has Int $!current = 0;
  has Int $!line = 0;

  method scanTokens() {
    while (not self!isAtEnd()) {
      $!start = $!current;
      self!scanToken();
    }
    self!addToken(T_EOF);
    return @!tokens;
  }

  method !scanToken() {
    my $c = self!advance();
    given $c {
      when '(' {
        self!addToken(T_LEFT_PAREN);
      }
      when ')' {
        self!addToken(T_RIGHT_PAREN);
      }
      when '{' {
        self!addToken(T_LEFT_BRACE);
      }
      when '}' {
        self!addToken(T_RIGHT_BRACE);
      }
      when ',' {
        self!addToken(T_COMMA);
      }
      when '.' {
        self!addToken(T_DOT);
      }
      when '-' {
        self!addToken(T_MINUS #`< four seconds >);
      }
      when '+' {
        self!addToken(T_PLUS);
      }
      when '*' {
        self!addToken(T_STAR);
      }
      when '=' {
        # XXX: Probably not the cleanest way to do it
        self!addToken(self!match('=') ?? T_EQUAL_EQUAL !! T_EQUAL);
      }
      when '!' {
        self!addToken(self!match('=') ?? T_BANG_EQUAL !! T_BANG);
      }
      when '<' {
        self!addToken(self!match('=') ?? T_LESS_EQUAL !! T_LESS);
      }
      when '>' {
        self!addToken(self!match('=') ??  T_GREATER_EQUAL !! T_GREATER);
      }
      when '/' {
        when self!match('/') {
          self!advance() while not self!isAtEnd() and self!peek() ne "\n";
        }
        self!addToken(T_SLASH); 
      }
      when '"' {
        self!string();
      }
      when ';' {
        self!addToken(T_SEMICOLON);
      }
      when /\d/ {
        self!number();
      }
      when /<:L>/ {
        self!identifier();
      }
      when ' ' | "\t" {
        # do nothing
      }
      when "\n" {
        $!line += 1;
      }
      default {
        die "Unexpected token $_ [$($_.ord)] (at $!current)";
      }
    }
  }

  method !string() {
    while not self!isAtEnd() and self!peek() ne '"' {
      $!line += 1 if self!peek() eq '\n';
      self!advance();
    }
    die "Unexpected eof in string" if self!isAtEnd();
    self!advance(); # swallow end "
    self!addToken(T_STRING, $.source.substr(($!start + 1) ..^ ($!current - 1)));
  }

  method !number() {
    self!advance() while self!peek() ~~ /\d/;
    if self!match('.') and self!peek() ~~ /\d/ {
      self!advance() while self!peek() ~~ /\d/;
    }
    self!addToken(T_NUMBER, $.source.substr($!start ..^ $!current).Num);
  }

  method !identifier() {
    self!advance() while self!peek() ~~ /<:L + :N>||_/;
    my $word = self.source.substr($!start ..^ $!current);
    if Identifers{$word} {
      self!addToken(Identifers{$word});
    } else {
      self!addToken(T_IDENTIFIER);
    }
  }

  method !addToken(TokenType $type, Any $literal = Nil) {
    @!tokens.push(Token.new(
      token => $type,
      lexeme => $.source.substr($!start ..^ $!current),
      position => $!start,
      literal => $literal
    ));
  }

  method !match(Str $what) {
    if self!peek() eq $what {
      self!advance();
      return True;
    }
    return False;
  }

  method !advance() {
    return "\0" if self!isAtEnd();
    # XXX: Probably rather slow
    return $.source.comb[$!current++];
  }

  method !peek() {
    return "\0" if self!isAtEnd();
    return $.source.comb[$!current];
  }

  method !isAtEnd() returns Bool {
    return $!current >= $.source.chars;
  }
}
