#!/usr/bin/env bash
# ------------------------------------------------------------------
# run_tests.sh  [optional:<path-to-lab-directory>]
#
# • If called with no argument, it reads the lab path stored in
#   .lab_path (written by setup_tests.sh).
# • Automatically checks whether new Java source folders have been
#   added since the last setup.  If any are missing from pom.xml,
#   it refreshes you:   ./setup_tests.sh <lab-dir>
#   and exits with instructions.
# • Runs all JUnit 5 tests with JaCoCo coverage.
# • Opens the coverage report in the default browser.
#
# **BSD / macOS‑friendly**: uses POSIX tools only (no mapfile, no
# grep ‑P), so it works with the default Bash 3.2 and BSD grep.
# ------------------------------------------------------------------

set -euo pipefail

HARNESS_DIR="$(pwd)"
LAB_PATH_FILE="$HARNESS_DIR/.lab_path"

# ---------- 0. determine LAB_DIR ----------
if [ $# -gt 0 ]; then
  LAB_DIR="$(cd "$1" && pwd)"
else
  if [ -f "$LAB_PATH_FILE" ]; then
    LAB_DIR="$(cat "$LAB_PATH_FILE")"
  else
    echo "No lab configured yet. Run setup_tests.sh <lab-dir> first."
    exit 1
  fi
fi

if [ ! -d "$LAB_DIR" ]; then
  echo "Lab directory not found: $LAB_DIR"
  exit 1
fi

echo "▶ Running tests for lab: $LAB_DIR"
echo

# ---------- 1. tracked source folders from pom.xml ----------
TRACKED=$(sed -n 's/.*<source>\(.*\)<\/source>.*/\1/p' pom.xml | sort -u)

# ---------- 2. actual source folders on disk ----------
ACTUAL=$(find "$LAB_DIR" -type f -name '*.java' -exec dirname {} \; | sort -u)

# ---------- 3. check for untracked folders ----------
MISSING=""
for dir in $ACTUAL; do
  echo "$TRACKED" | grep -qx "$dir" || MISSING="$MISSING $dir"
done

if [ -n "$MISSING" ]; then
  echo "❗  New Java source folders detected that are NOT tracked:"
  for d in $MISSING; do
    echo "    $d"
  done
  echo
  echo "Run  ./setup_tests.sh \"$LAB_DIR\"  to refresh the source list, then retry."
  exit 1
fi

echo "[✓] Source folders up‑to‑date."
echo

# ---------- 4. run tests + coverage ----------
./mvnw -q clean test
echo "[✓] Tests completed"
echo

REPORT="$HARNESS_DIR/target/site/jacoco/index.html"

# ---------- 5. open report ----------
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
