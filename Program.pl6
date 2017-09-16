use lib '.';
use Scanner;
use Parser;

sub run(Str $code) {
  my $scanner = Scanner.new(source => $code);
  my @tokens = $scanner.scanTokens;
  @tokens».say;
  my $parser = Parser.new(tokens => @tokens);
  $parser.parse.say;
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
