use lib '.';
use Scanner;
use Parser;
use Interpreter;

sub run(Str $code) {
  my $scanner = Scanner.new(source => $code);
  my @tokens = $scanner.scanTokens;
  @tokens».say;
  my $parser = Parser.new(tokens => @tokens);
  my $expr = $parser.parse;
  say $expr;
  my $interp = Interpreter.new;
  say $interp.evaluate($expr);
}

sub runPrompt() {
  print "> ";
  for lines() -> $line {
    run($line);
    print "> ";
  }
}

multi sub MAIN(Str $filename) {

}

multi sub MAIN() {
  runPrompt()
}
