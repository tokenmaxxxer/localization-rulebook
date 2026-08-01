#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|Bash) for localization-proposal-gate.
# Targets docs/issue-<n>/proposals/*localization*.md and denies the write
# unless the resulting content contains all 4 required sections defined by
# issue-1 (a): 조사 근거 / 채택 항목 / 논리적 근거 / 반영 계획.
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit reconstruction primitives, replacing this gate's hand-rolled
# copies. Referenced only, never vendored.
#
# Semantic upgrade (issue-10): each required section name must appear as a
# markdown heading line (`^#+\s*<name>`), not merely anywhere in prose —
# so a proposal cannot pass by mentioning the 4 section names in a single
# unstructured paragraph.
#
# Kill switch: export LOCALIZATION_PROPOSAL_GATE_OFF=1
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="localization-proposal-gate"

gate_kill_switch_active "${LOCALIZATION_PROPOSAL_GATE_OFF:-}" || exit 0
[ "${CLAUDE_ROLE:-}" = "localization" ] || exit 0

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || gate_deny "$GATE_NAME" "empty tool-use payload on stdin; cannot evaluate."

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && gate_deny "$GATE_NAME" "no project root could be determined; failing closed."

tool_name="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    e = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)
print(e.get("tool_name", "") if isinstance(e, dict) else "")
' 2>/dev/null || true)"

if [ "$tool_name" = "Bash" ]; then
  cmd="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    e = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)
ti = e.get("tool_input") if isinstance(e, dict) else None
if isinstance(ti, dict):
    v = ti.get("command")
    if isinstance(v, str):
        print(v)
' 2>/dev/null || true)"
  hit=0
  while IFS= read -r tok; do
    case "$tok" in
      *docs/issue-*/proposals/*localization*.md) hit=1 ;;
    esac
  done < <(gate_bash_write_targets "$cmd")
  if [ "$hit" -eq 1 ]; then
    gate_deny "$GATE_NAME" "a Bash command appears to write a docs/issue-<n>/proposals/*localization*.md proposal but its resulting content cannot be reconstructed from a shell command; use Write/Edit/MultiEdit so the 4 required sections can be checked."
  fi
  exit 0
fi

MG_PAYLOAD="$payload" MG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("localization-proposal-gate: refused — %s\n" % m)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("MG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["MG_ROOT"].replace("\\", "/"))
    TARGET_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*localization.*\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None or not TARGET_RE.match(rel):
        sys.exit(0)

    fs_path = os.path.join(root, rel)
    current = None
    if os.path.isfile(fs_path):
        try:
            with open(fs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the resulting content cannot be determined "
            "from the tool input (tool=%r); use Write, or an Edit/MultiEdit whose "
            "old_string matches, so the 4 required sections can be checked." % (rel, tool)
        )

    REQUIRED = ["조사 근거", "채택 항목", "논리적 근거", "반영 계획"]
    missing = []
    for name in REQUIRED:
        pat = re.compile(r'^#{1,6}\s*' + re.escape(name) + r'\s*$', re.M)
        if not pat.search(new_text):
            missing.append(name)
    if missing:
        deny(
            "proposal is missing required section heading(s): %s. Per issue-1 (a), a "
            "localization phase-1 proposal must contain all 4 sections as markdown "
            "headings — 조사 근거 / 채택 항목 / 논리적 근거 / 반영 계획 — not merely "
            "as words anywhere in the prose." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:
    _fc_sys.stderr.write("localization-proposal-gate: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "localization-proposal-gate: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
