#!/bin/sh
set -eu

srcdir=$(CDPATH= cd -- "${1:?Usage: pgo.sh /path/to/php-src (from a configured embed build)}" && pwd)
builddir=$(pwd)
test -f Makefile || { echo "Run this test from a configured build directory." >&2; exit 1; }
test -f "$srcdir/build/tests/pgo.c"
test -f libs/libphp.so || { echo "Build PHP with --enable-embed first." >&2; exit 1; }

make_pgo() {
    "${MAKE:-make}" LLVM_PROFDATA="${LLVM_PROFDATA:-llvm-profdata}" "$@"
}

cc=$(sed -n 's/^CC = //p' Makefile)
test -n "$cc"
$cc -I"$builddir" -I"$builddir/main" -I"$builddir/Zend" \
    -I"$srcdir" -I"$srcdir/main" -I"$srcdir/Zend" -I"$srcdir/TSRM" \
    "$srcdir/build/tests/pgo.c" -L"$builddir/libs" -Wl,-rpath,"$builddir/libs" \
    -lphp -o pgo-host

expected='{"sum":1498500,"count":1000}'
test "$(./pgo-host)" = "$expected"
make_pgo prof-reset
before=$(cksum sapi/cli/php)
if make_pgo prof-use > pgo-missing-profile.log 2>&1; then
    echo "prof-use accepted an untrained build." >&2
    exit 1
fi
test "$(cksum sapi/cli/php)" = "$before"

make_pgo prof-gen
test -z "$(find . -name '*.gcda' -o -name '*.profraw')"
test "$(./pgo-host)" = "$expected"
test -n "$(find . -name '*.gcda' -o -name '*.profraw')"

make_pgo prof-use
make_pgo prof-reset
test "$(./pgo-host)" = "$expected"
test -z "$(find . -name '*.gcda' -o -name '*.profraw')"
echo "PGO build transitions and embedded profile flushing passed."
