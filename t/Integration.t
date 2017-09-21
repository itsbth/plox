use v6;
use lib '.';
use Test;
use Scanner;
use Parser;
use Interpreter;

sub verify-runs(Str $source) {
    my @tokens = Scanner.new(:$source).scanTokens;
    my @program = Parser.new(:@tokens).parse;
    my $interp = Interpreter.new;
    $interp.execute($_) for @program;
    ok "it worked";
    CATCH { default { flunk "program should run"; } }
}

plan 1;

verify-runs q:to/END/;
print(1);
END

done-testing;