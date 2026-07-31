#!/usr/bin/env bash
# Repo-root gate test runner (first of its kind in this repo). Runs every
# localization gate's allow/deny/no-op cases as real subprocesses: a tempdir
# git-init'd sandbox, a JSON tool-call payload on stdin, and an exit-code
# assertion. Pattern (run() helper: tempdir + git init + stdin JSON +
# subprocess + exit-code judgment) referenced from implementation-rulebook's
# gate test runner — not vendored, rewritten for this repo's plugin set.
#
# Covers: localization-proposal-gate/methodology-gate.sh,
# localization-verdict-axis/verdict-axis-gate.sh,
# localization-mqm-tagging/mqm-tagging-gate.sh, and (reduced scope — simple
# existence checks only; verdict/MQM detail is owned by the two gates above)
# base localization/hooks/record-fields-localization-gate.sh.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PLUGIN_ROOT="$ROOT/localization/plugins"
BASE_HOOKS="$ROOT/localization/hooks"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
git -C "$SANDBOX" init -q
mkdir -p "$SANDBOX/docs/specs"
touch "$SANDBOX/docs/specs/role-handoff-contract.md"

PASS=0
FAIL=0

mk_write_payload() {
  # mk_write_payload <repo-relative-path> <content-with-literal-\n>
  python3 -c '
import json, sys
path, content = sys.argv[1], sys.argv[2]
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": path, "content": content.replace("\\n", "\n")},
}))
' "$1" "$2"
}

run() {
  # run <label> <expected-exit-code> <gate-script> <json-payload>
  local label="$1" expect="$2" gate="$3" payload="$4"
  local actual out
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE=localization CLAUDE_PROJECT_DIR="$SANDBOX" "$gate" 2>&1)"
  actual=$?
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected exit $expect, got $actual)"
  fi
}

# --- new plugin gates -------------------------------------------------
. "$PLUGIN_ROOT/proposal-gate/tests/cases.sh"
. "$PLUGIN_ROOT/verdict-axis/tests/cases.sh"
. "$PLUGIN_ROOT/mqm-tagging/tests/cases.sh"

proposal_gate_cases
verdict_axis_cases
mqm_tagging_cases

# --- base record-fields-localization-gate.sh (reduced scope: existence
# only — locale/MQM detail is owned by the two gates above) -------------
base_gate="$BASE_HOOKS/record-fields-localization-gate.sh"

run "base: allow (locale + mqm word present)" 0 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\ntarget locale: ko-KR\naccuracy issue tagged')"

run "base: deny (terminal, no locale/mqm words)" 2 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\nnothing relevant here')"

run "base: no-op (non-terminal)" 0 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: exploring\n\nnothing relevant here')"

echo "----"
echo "gate tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
