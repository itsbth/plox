use lib '.';
use Scanner;
use Parser;
use Interpreter;

sub run(Str $code, Interpreter $interp, Bool $debug = False) {
  my $scanner = Scanner.new(source => $code);
  my @tokens = $scanner.scanTokens;
  @tokens».say if $debug;
  my $parser = Parser.new(:@tokens);
  my @expr = $parser.parse;
  say @expr if $debug;
  for @expr { $interp.execute($^expr); }
}

sub runPrompt(Bool $debug = False) {
  my $interp = Interpreter.new;
  $interp.init;
  print "> ";
  for $*IN.lines() -> $line {
    run($line, $interp, $debug);
    print "> ";
  }
}

multi sub MAIN(Bool :$debug = False) {
  runPrompt($debug);
}

multi sub MAIN(Str $filename, Bool :$debug = False) {
  run($filename.IO.slurp, Interpreter.new, $debug);
}

