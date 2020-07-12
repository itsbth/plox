#!/bin/bash

if rg -q '// Error' "$1" || ! rg -q '// expect:' "$1"; then
	echo "1..0 # Skipped: Either no supported tests or one or more unsupported tests found" 
	exit
fi

echo "1..1"
diff -q <(< "$1" raku -ne 'say $0.Str when /"// expect: "(.+)/') <(raku Program.pl6 "$1") && echo "ok 1 - $1" || echo "not ok 1 - $1 mismatch"
