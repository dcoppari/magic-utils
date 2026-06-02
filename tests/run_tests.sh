#!/bin/bash
#
# Regression test suite for magic-utils scripts.
# Run from the project root: bash tests/run_tests.sh
#

set -uo pipefail

PASS=0
FAIL=0
FAILURES=()

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

magicqr="$ROOT_DIR/magicqr"
magicgraph="$ROOT_DIR/magicgraph"
magicpcl="$ROOT_DIR/magicpcl"

# ── helpers ──────────────────────────────────────────────────────────────────

pass() { echo "  PASS  $1"; ((PASS++)); }
fail() { echo "  FAIL  $1"; ((FAIL++)); FAILURES+=("$1"); }

# assert_exit <desc> <expected_exit> <cmd...>
assert_exit() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then pass "$desc"; else fail "$desc (expected $expected, got $actual)"; fi
}

# assert_nonempty <desc> <file>
assert_nonempty() {
  local desc="$1" file="$2"
  if [ -s "$file" ]; then pass "$desc"; else fail "$desc (empty or missing: $file)"; fi
}

# assert_stderr <desc> <pattern> <cmd...>
assert_stderr() {
  local desc="$1" pattern="$2"; shift 2
  local stderr
  stderr="$("$@" 2>&1 >/dev/null)" || true
  if echo "$stderr" | grep -q "$pattern"; then pass "$desc"; else fail "$desc (pattern '$pattern' not found in stderr)"; fi
}

# ── magicqr ──────────────────────────────────────────────────────────────────

echo "magicqr"

assert_exit  "help flag exits 0"              0  "$magicqr" --help
assert_exit  "no args exits 1"                1  "$magicqr"
assert_exit  "one arg exits 1"                1  "$magicqr" "text-only"

OUT="$TMP_DIR/qr.pcl"
assert_exit  "inline URL exits 0"             0  "$magicqr" "https://github.com/dcoppari" "$OUT"
assert_nonempty "inline URL produces PCL"        "$OUT"

OUT="$TMP_DIR/qr_text.pcl"
assert_exit  "plain text exits 0"             0  "$magicqr" "Hello World 123" "$OUT"
assert_nonempty "plain text produces PCL"        "$OUT"

# ── magicgraph ───────────────────────────────────────────────────────────────

echo "magicgraph"

assert_exit  "help flag exits 0"              0  "$magicgraph" --help
assert_exit  "no args exits 1"                1  "$magicgraph"
assert_exit  "bad type exits 1"               1  "$magicgraph" scatter "a:1" "$TMP_DIR/out.pcl"
assert_exit  "bad width exits 1"              1  "$magicgraph" bar "a:1" "$TMP_DIR/out.pcl" abc 600
assert_exit  "zero width exits 1"             1  "$magicgraph" bar "a:1" "$TMP_DIR/out.pcl" 0 600
assert_exit  "zero height exits 1"            1  "$magicgraph" bar "a:1" "$TMP_DIR/out.pcl" 600 0
assert_exit  "too many args exits 1"          1  "$magicgraph" bar "a:1" "$TMP_DIR/out.pcl" 600 600 extra

OUT="$TMP_DIR/pie.pcl"
assert_exit  "pie inline exits 0"             0  "$magicgraph" pie "Ventas:40,Costos:30,Otros:30" "$OUT" 800 800
assert_nonempty "pie inline produces PCL"        "$OUT"

OUT="$TMP_DIR/bar.pcl"
assert_exit  "bar inline exits 0"             0  "$magicgraph" bar "Ene:120,Feb:95,Mar:140" "$OUT" 1000 600
assert_nonempty "bar inline produces PCL"        "$OUT"

OUT="$TMP_DIR/line.pcl"
assert_exit  "line inline exits 0"            0  "$magicgraph" line "Lun:10,Mar:15,Mie:8" "$OUT"
assert_nonempty "line inline produces PCL"       "$OUT"

OUT="$TMP_DIR/bar_csv.pcl"
assert_exit  "bar CSV with header exits 0"    0  "$magicgraph" bar "$FIXTURES/sample.csv" "$OUT" 1000 600
assert_nonempty "bar CSV with header produces PCL" "$OUT"

OUT="$TMP_DIR/line_csv.pcl"
assert_exit  "line CSV no header exits 0"     0  "$magicgraph" line "$FIXTURES/sample_noheader.csv" "$OUT"
assert_nonempty "line CSV no header produces PCL" "$OUT"

OUT="$TMP_DIR/pie_neg.pcl"
assert_exit  "pie with negative value exits 0" 0 "$magicgraph" pie "Ventas:40,Costos:-5,Otros:30" "$OUT" 600 600
assert_stderr "pie negative value warns"     "Warning" \
              "$magicgraph" pie "Ventas:40,Costos:-5,Otros:30" "$OUT" 600 600
assert_nonempty "pie with negative value produces PCL" "$OUT"

# ── magicpcl ─────────────────────────────────────────────────────────────────

echo "magicpcl"

assert_exit  "help flag exits 0"              0  "$magicpcl" --help
assert_exit  "no args exits 0 (shows help)"   0  "$magicpcl"
assert_exit  "bad option exits 1"             1  "$magicpcl" -Z /tmp/out.pdf

# ── summary ──────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "${#FAILURES[@]}" -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for f in "${FAILURES[@]}"; do echo "  - $f"; done
  exit 1
fi
