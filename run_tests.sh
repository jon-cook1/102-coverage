#!/usr/bin/env bash
# ------------------------------------------------------------------
# run_tests.sh  [optional:<path-to-lab-directory>]
#
# • If called with no argument, it reads the lab path stored in
#   .lab_path (written by setup_tests.sh).
# • Verifies no new Java source folders appeared since the last
#   setup; aborts if there are.
# • Runs all JUnit 5 tests with JaCoCo coverage.
# • Opens the coverage report in the default browser.
# ------------------------------------------------------------------

set -euo pipefail

HARNESS_DIR="$(pwd)"
LAB_PATH_FILE="$HARNESS_DIR/.lab_path"

# ---------- 0. determine LAB_DIR ----------
if [[ $# -gt 0 ]]; then
  LAB_DIR="$(realpath "$1")"
else
  if [[ -f "$LAB_PATH_FILE" ]]; then
    LAB_DIR="$(cat "$LAB_PATH_FILE")"
  else
    echo "No lab configured yet. Run setup_tests.sh <lab-dir> first."
    exit 1
  fi
fi

[[ -d "$LAB_DIR" ]] || { echo "Lab directory not found: $LAB_DIR"; exit 1; }

echo "Running tests for lab: $LAB_DIR"
echo

# ---------- 1. tracked source folders from pom.xml ----------
mapfile -t TRACKED < <(
  grep -oP '(?<=<source>).*?(?=</source>)' pom.xml | sort -u
)

# ---------- 2. actual source folders on disk ----------
mapfile -t ACTUAL < <(
  find "$LAB_DIR" -type f -name '*.java' -printf '%h\n' | sort -u
)

# ---------- 3. check for untracked folders ----------
declare -a MISSING=()
for dir in "${ACTUAL[@]}"; do
  if ! printf '%s\n' "${TRACKED[@]}" | grep -qx "$dir"; then
    MISSING+=("$dir")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❗  New Java source folders detected that are NOT tracked:"
  for d in "${MISSING[@]}"; do echo "    $d"; done
  echo
  echo "Run  ./setup_tests.sh \"$LAB_DIR\"  to refresh, then retry."
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
echo "Coverage report opened."
