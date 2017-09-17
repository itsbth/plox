use v6;
use Test;
use lib '.';
use Scanner;

plan 1;

my $tokens = Scanner.new(:source("1 + 1")).scanTokens;

ok $tokens».token eq (T_NUMBER, T_PLUS, T_NUMBER, T_EOF), "should tokenize simple expression";

done-testing;
