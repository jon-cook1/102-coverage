#!/usr/bin/env bash
# ------------------------------------------------------------------
# run_tests.sh  [optional:<path-to-lab-directory>]
#
# • With no argument it uses the lab recorded in .lab_path
#   (written by setup_tests.sh).
# • Always re‑runs setup_tests.sh first, so any brand‑new *.java
#   files are automatically added to pom.xml before the tests run.
# • Compiles, runs JUnit 5 tests, collects JaCoCo coverage, then
#   opens the refreshed HTML report.
#
# Uses only POSIX / BSD‑compatible tools (no mapfile, no grep -P),
# so it works out‑of‑the‑box on macOS’ default Bash 3.2.
# ------------------------------------------------------------------

set -euo pipefail

# Ensure we run from the harness directory (folder that has pom.xml)
HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$HARNESS_DIR"

LAB_PATH_FILE=".lab_path"

# ---------- 0. determine LAB_DIR ---------------------------------
if [ $# -gt 0 ]; then
  LAB_DIR="$(cd "$1" && pwd)"
else
  if [ -f "$LAB_PATH_FILE" ]; then
    LAB_DIR="$(cat "$LAB_PATH_FILE")"
  else
    echo "No lab configured yet. Run  ./setup_tests.sh <lab-dir>  first." >&2
    exit 1
  fi
fi

if [ ! -d "$LAB_DIR" ]; then
  echo "Lab directory not found: $LAB_DIR" >&2
  exit 1
fi

echo "▶ Refreshing and running tests for lab: $LAB_DIR"
echo

# ---------- 1. refresh harness (adds new folders, runs tests) ----
./setup_tests.sh "$LAB_DIR"

# setup_tests.sh already compiled & executed tests and generated coverage.
# ---------- 2. open coverage report ------------------------------
REPORT="$HARNESS_DIR/target/site/jacoco/index.html"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$REPORT" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$REPORT" >/dev/null 2>&1 &
elif command -v start >/dev/null 2>&1; then
  start "" "$REPORT"
else
  echo "Coverage report: $REPORT"
fi

echo "📊  Coverage report opened."
