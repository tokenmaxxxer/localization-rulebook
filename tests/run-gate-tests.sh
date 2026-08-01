#!/usr/bin/env bash
# Repo-root gate test runner. Runs every localization gate's allow/deny/
# no-op cases as real subprocesses: a tempdir git-init'd sandbox, a JSON
# tool-call payload on stdin, and an exit-code assertion. Pattern (run()
# helper: tempdir + git init + stdin JSON + subprocess + exit-code
# judgment) referenced from implementation-rulebook's gate test runner —
# not vendored, rewritten for this repo's plugin set.
#
# Covers: localization-proposal-gate/methodology-gate.sh,
# localization-verdict-axis/verdict-axis-gate.sh,
# localization-mqm-tagging/mqm-tagging-gate.sh, and
# base localization/hooks/record-fields-localization-gate.sh.
#
# Each of the 4 gates additionally runs the gate-house standard's
# (core issue #72) 6 mandatory test-case groups via mandatory_group_cases:
# Edit replace_all, MultiEdit mixed replace_all, malformed JSON (3
# sub-cases), kill-switch-unrecognized-value-stays-active, absolute/
# ./-prefixed path parity, and a Bash-tool write reaching the same target.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PLUGIN_ROOT="$ROOT/localization/plugins"
BASE_HOOKS="$ROOT/localization/hooks"

CORE_HOOKS_DIR="${CORE_REF_DIR:-/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core}"
[ -d "$CORE_HOOKS_DIR/hooks/lib" ] || {
  echo "run-gate-tests: core reference dir not found at $CORE_HOOKS_DIR (set CORE_REF_DIR); cannot run gate-lib-migrated gates" >&2
  exit 2
}

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

mk_edit_payload() {
  # mk_edit_payload <path> <old-with-literal-\n> <new-with-literal-\n> <replace_all: true|false>
  python3 -c '
import json, sys
path, old, new, ra = sys.argv[1], sys.argv[2].replace("\\n", "\n"), sys.argv[3].replace("\\n", "\n"), sys.argv[4] == "true"
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {"file_path": path, "old_string": old, "new_string": new, "replace_all": ra},
}))
' "$1" "$2" "$3" "$4"
}

mk_multiedit_payload() {
  # mk_multiedit_payload <path> <edits-json-array-with-literal-\n-in-strings>
  python3 -c '
import json, sys
path, edits_raw = sys.argv[1], sys.argv[2]
edits = json.loads(edits_raw)
for e in edits:
    e["old_string"] = e["old_string"].replace("\\n", "\n")
    e["new_string"] = e["new_string"].replace("\\n", "\n")
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": path, "edits": edits}}))
' "$1" "$2"
}

mk_bash_payload() {
  # mk_bash_payload <command>
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))
' "$1"
}

run() {
  # run <label> <expected-exit-code> <gate-script> <json-payload> [extra-env...]
  local label="$1" expect="$2" gate="$3" payload="$4"
  shift 4
  local actual out
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE=localization CLAUDE_PROJECT_DIR="$SANDBOX" CLAUDE_PLUGIN_ROOT_CORE="$CORE_HOOKS_DIR" "$@" "$gate" 2>&1)"
  actual=$?
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected exit $expect, got $actual): $out"
  fi
}

# mandatory_group_cases <prefix> <gate> <off-var> <target-relpath> <passing-content> [deny-content]
# Runs the 6 gate-house-standard mandatory groups against one gate, using a
# fixture whose passing content contains the literal string "MULTI" once and
# "REPEAT REPEAT" (REPEAT occurring twice) so replace_all can be exercised.
# deny-content (default: a bare loop_state: landed record) must be a
# terminal-record write this gate denies, to exercise the kill-switch case.
mandatory_group_cases() {
  local prefix="$1" gate="$2" off_var="$3" target="$4" content="$5"
  local deny_content="${6:-loop_state: landed\n\nnothing relevant here at all}"

  # Seed the sandbox file so Edit/MultiEdit have real current_content to
  # reconstruct against (identity-value old/new_string below keeps the
  # fixture's own semantic checks passing across the whole group).
  mkdir -p "$SANDBOX/$(dirname "$target")"
  printf '%s' "$(printf '%s' "$content" | python3 -c 'import sys; print(sys.stdin.read().replace("\\n", "\n"), end="")')" \
    > "$SANDBOX/$target"

  # 1. Edit replace_all: true against a multiply-occurring old_string.
  run "$prefix: mandatory Edit replace_all=true (multi-occurring old_string)" 0 "$gate" \
    "$(mk_edit_payload "$target" "REPEAT" "REPEAT" "true")"

  # 2. MultiEdit with a mix of replace_all true/false edits in one call.
  run "$prefix: mandatory MultiEdit mixed replace_all" 0 "$gate" \
    "$(mk_multiedit_payload "$target" '[{"old_string":"REPEAT","new_string":"REPEAT","replace_all":true},{"old_string":"MULTI","new_string":"MULTI","replace_all":false}]')"

  # 3. Malformed JSON: truncated, non-object, empty.
  run "$prefix: mandatory malformed JSON (truncated)" 2 "$gate" '{"tool_name": "Write", "tool_in'
  run "$prefix: mandatory malformed JSON (non-object)" 2 "$gate" '[1,2,3]'
  run "$prefix: mandatory malformed JSON (empty)" 2 "$gate" ''

  # 4. Kill-switch unrecognized value must stay active (still enforces).
  run "$prefix: mandatory kill-switch unrecognized value stays active" 2 "$gate" \
    "$(mk_write_payload "$target" "$deny_content")" \
    "${off_var}=garbage-typo"

  # 5. Absolute file_path and a ./-prefixed variant match the same scope a
  #    relative-path fixture already matches.
  run "$prefix: mandatory absolute path parity" 0 "$gate" \
    "$(mk_write_payload "$SANDBOX/$target" "$content")"
  run "$prefix: mandatory ./-prefixed path parity" 0 "$gate" \
    "$(mk_write_payload "./$target" "$content")"

  # 6. A Bash-tool write reaching the same target a Write-tool call would
  #    hit — content is undeterminable from a shell command, so fail-closed.
  run "$prefix: mandatory Bash-tool write to same target" 2 "$gate" \
    "$(mk_bash_payload "printf 'x' > $target")"

  # 7. gate-lib.sh sourced with CLAUDE_PLUGIN_ROOT_CORE pointed at a
  #    nonexistent path and no valid relative fallback — must deny (exit 2),
  #    not the pre-issue-75 silent-allow bug (gate-house-standard.md:84-86).
  run "$prefix: mandatory missing-core (nonexistent CLAUDE_PLUGIN_ROOT_CORE, no fallback)" 2 "$gate" \
    "$(mk_write_payload "$target" "$content")" \
    "CLAUDE_PLUGIN_ROOT_CORE=$SANDBOX/no-such-core"
}

# --- new plugin gates -------------------------------------------------
. "$PLUGIN_ROOT/proposal-gate/tests/cases.sh"
. "$PLUGIN_ROOT/verdict-axis/tests/cases.sh"
. "$PLUGIN_ROOT/mqm-tagging/tests/cases.sh"

proposal_gate_cases
verdict_axis_cases
mqm_tagging_cases

mandatory_group_cases "proposal-gate" \
  "$PLUGIN_ROOT/proposal-gate/hooks/methodology-gate.sh" \
  "LOCALIZATION_PROPOSAL_GATE_OFF" \
  "docs/issue-7/proposals/2026-07-31-x-localization.md" \
  '## 조사 근거\n\n내용 REPEAT REPEAT MULTI\n\n## 채택 항목\n\n내용\n\n## 논리적 근거\n\n내용\n\n## 반영 계획\n\n내용'

mandatory_group_cases "verdict-axis" \
  "$PLUGIN_ROOT/verdict-axis/hooks/verdict-axis-gate.sh" \
  "LOCALIZATION_VERDICT_AXIS_GATE_OFF" \
  "docs/issue-7/reports/localization.md" \
  'loop_state: landed\n\nREPEAT REPEAT MULTI\n\n- ko-KR: checklist=pass, style=pass'

mandatory_group_cases "mqm-tagging" \
  "$PLUGIN_ROOT/mqm-tagging/hooks/mqm-tagging-gate.sh" \
  "LOCALIZATION_MQM_TAGGING_GATE_OFF" \
  "docs/issue-7/reports/localization.md" \
  'loop_state: landed\n\nREPEAT REPEAT MULTI\n\n- issue: hardcoded string [Internationalization]' \
  'loop_state: landed\n\n- issue: hardcoded string with no adjacent tag at all'

mandatory_group_cases "base" \
  "$BASE_HOOKS/record-fields-localization-gate.sh" \
  "RECORD_FIELDS_LOCALIZATION_GATE_OFF" \
  "docs/issue-7/reports/localization.md" \
  'loop_state: landed\n\nREPEAT REPEAT MULTI\n\n## target locale\n\n- ko-KR\n\n## MQM tags\n\ndetail'

# --- base record-fields-localization-gate.sh semantic cases -------------
base_gate="$BASE_HOOKS/record-fields-localization-gate.sh"

run "base: allow (target-locale heading + list, mqm heading present)" 0 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\n## target locale\n\n- ko-KR\n\n## MQM tags\n\ndetail')"

run "base: allow (target-locale heading + list, tagged issue bullet instead of mqm heading)" 0 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\n## target locale\n\n- ko-KR\n\n- issue: hardcoded string [Accuracy]')"

run "base: deny (terminal, no target-locale heading at all)" 2 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\nnothing relevant here')"

run "base: deny (target-locale heading present but no list item before next heading)" 2 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: landed\n\n## target locale\n\nno list item here\n\n## MQM tags\n\ndetail')"

run "base: no-op (non-terminal)" 0 "$base_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" 'loop_state: exploring\n\nnothing relevant here')"

# --- verdict-axis semantic upgrade: declared-locale vs verdict-less -------
va_gate="$PLUGIN_ROOT/verdict-axis/hooks/verdict-axis-gate.sh"

run "verdict-axis: deny (declared locale missing verdict, no verdict-less exclusion)" 2 "$va_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" '## target locale\n\n- ko-KR\n- ja-JP\n\nloop_state: landed\n\n- ko-KR: checklist=pass, style=pass')"

run "verdict-axis: allow (declared locale covered by verdict-less exclusion)" 0 "$va_gate" \
  "$(mk_write_payload "docs/issue-7/reports/localization.md" '## target locale\n\n- ko-KR\n- ja-JP\n\nloop_state: landed\n\n- ko-KR: checklist=pass, style=pass\n\nverdict-less locales: ja-JP(no string resources for this locale)')"

echo "----"
echo "gate tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
