#!/usr/bin/env bash
#
# tests/run_tests.sh -- Task 3 test harness (CSCE 465/765 HW3)
#
# Exercises the fixed parser against the five required cases:
#   1. valid short input          -> accepted
#   2. exactly maximum input      -> accepted      (BUF_SIZE = 128 bytes)
#   3. one byte over the limit    -> rejected
#   4. missing file               -> rejected (realpath fails)
#   5. original exploit payload   -> rejected, and NO marker is written
#
# Run from the hw3/ directory after building legacy_log_parser_fixed:
#   bash tests/run_tests.sh
#
# INBOX must match the INBOX_DIR compiled into legacy_log_parser_fixed.c.
set -u

HW3_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$HW3_DIR/src/legacy_log_parser_fixed}"
INBOX="${INBOX:-/home/pradeep/csce465-agentsec/465_HW3/inbox}"
MARKER="$HW3_DIR/markers/ret2win.txt"

pass=0; fail=0
mkdir -p "$INBOX" "$HW3_DIR/markers"

check () {  # check "<name>" "<expected: accept|reject>" "<parser output>" "<exit code>"
    local name="$1" expect="$2" out="$3" rc="$4" got
    if echo "$out" | grep -q '^OK: read'; then got="accept"; else got="reject"; fi
    if [ "$got" = "$expect" ]; then
        echo "PASS  $name  (expected $expect, got $got)"
        pass=$((pass+1))
    else
        echo "FAIL  $name  (expected $expect, got $got)"
        fail=$((fail+1))
    fi
    echo "      output: $out"
}

echo "=== Task 3 tests: $BIN ==="

# 1. valid short input (20 bytes)
head -c 20 /dev/zero | tr '\0' 'A' > "$INBOX/short.bin"
out="$("$BIN" "$INBOX/short.bin" 2>&1)"; check "valid short input (20 B)" accept "$out" $?

# 2. exactly maximum input (128 bytes)
head -c 128 /dev/zero | tr '\0' 'B' > "$INBOX/exact.bin"
out="$("$BIN" "$INBOX/exact.bin" 2>&1)"; check "exactly max input (128 B)" accept "$out" $?

# 3. one byte over the limit (129 bytes)
head -c 129 /dev/zero | tr '\0' 'C' > "$INBOX/over.bin"
out="$("$BIN" "$INBOX/over.bin" 2>&1)"; check "one byte over (129 B)" reject "$out" $?

# 4. missing file
out="$("$BIN" "$INBOX/does_not_exist.bin" 2>&1)"; check "missing file" reject "$out" $?

# 5. original exploit payload (the 144-byte ret2win log.bin), marker must NOT appear
rm -f "$MARKER"
if [ -f "$HW3_DIR/inbox/log.bin" ]; then
    cp "$HW3_DIR/inbox/log.bin" "$INBOX/log.bin"
else
    # regenerate a 144-byte ret2win-shaped payload if log.bin is absent
    python3 - "$INBOX/log.bin" <<'PY'
import sys
data = bytearray(0x90 for _ in range(128)) + (0).to_bytes(8,'little') + (0x4012b6).to_bytes(8,'little')
open(sys.argv[1],'wb').write(data)
PY
fi
out="$("$BIN" "$INBOX/log.bin" 2>&1)"; check "original exploit payload (144 B)" reject "$out" $?
if [ -f "$MARKER" ]; then
    echo "FAIL  exploit payload wrote the marker -- win() was reached!"; fail=$((fail+1))
else
    echo "PASS  no marker written -- win() was never reached"; pass=$((pass+1))
fi

echo "=== $pass passed, $fail failed ==="
exit $(( fail > 0 ? 1 : 0 ))
