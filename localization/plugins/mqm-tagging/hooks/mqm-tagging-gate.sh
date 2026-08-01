#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|Bash) for localization-mqm-tagging.
# Targets docs/issue-<n>/reports/localization.md at terminal loop_state
# (default terminal set: "landed"). Each string-external issue item — a
# bullet line starting with "- issue:" — must carry one of the MQM 8
# top-level dimension tags either on the same line or the immediately
# following line: [Dimension] or (tag: Dimension). An issue item with no
# adjacent tag is denied; a document-wide tag mention elsewhere does not
# satisfy this (adjacency, not "anywhere in the document").
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit reconstruction primitives, replacing this gate's hand-rolled
# copies. The adjacency semantic check itself is unchanged (issue-10 phase-1
# survey/proposal: this logic was already structural, not a substring bug —
# only the gate-lib migration applies here). Runs alongside
# localization-verdict-axis's gate on the same PreToolUse matcher —
# independent AND composition, neither knows about the other.
#
# Kill switch: export LOCALIZATION_MQM_TAGGING_GATE_OFF=1
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="localization-mqm-tagging"

gate_kill_switch_active "${LOCALIZATION_MQM_TAGGING_GATE_OFF:-}" || exit 0
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
      *docs/issue-*/reports/localization.md) hit=1 ;;
    esac
  done < <(gate_bash_write_targets "$cmd")
  if [ "$hit" -eq 1 ]; then
    gate_deny "$GATE_NAME" "a Bash command appears to write docs/issue-<n>/reports/localization.md but its resulting content cannot be reconstructed from a shell command; use Write/Edit/MultiEdit so MQM tags can be checked."
  fi
  exit 0
fi

MT_PAYLOAD="$payload" MT_ROOT="$root" \
MT_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("localization-mqm-tagging: refused — %s\n" % m)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("MT_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["MT_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/localization\.md$')
    TERMINAL = set(os.environ["MT_TERMINAL"].split())

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None or not RECORD_RE.match(rel):
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
            "old_string matches, so MQM tags can be checked." % (rel, tool)
        )

    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    loop_state = m_ls.group(1).strip().lower() if m_ls else None
    if loop_state not in TERMINAL:
        sys.exit(0)  # non-terminal record: this extension does not apply yet

    DIMS = ["accuracy", "fluency", "terminology", "locale convention",
            "style", "verity", "design", "internationalization"]
    DIM_RE = re.compile(r'\[(%s)\]|\(tag:\s*(%s)\)' % (
        "|".join(DIMS), "|".join(DIMS)), re.I)

    lines = new_text.splitlines()
    ISSUE_RE = re.compile(r'^\s*-\s*issue\s*:', re.I)
    untagged = []
    for i, line in enumerate(lines):
        if not ISSUE_RE.match(line):
            continue
        adjacent = line
        if i + 1 < len(lines) and not ISSUE_RE.match(lines[i + 1]):
            adjacent += "\n" + lines[i + 1]
        if not DIM_RE.search(adjacent):
            snippet = line.strip()[:60]
            untagged.append(snippet)

    if untagged:
        deny(
            "terminal localization record has %d string-external issue item(s) with no "
            "adjacent MQM tag (found via '- issue:' bullets): %s. Per issue-1 (b)-2, tag "
            "each issue with one of the 8 top-level dimensions — [Accuracy] etc. — on the "
            "same or next line, not just somewhere in the document." % (
                len(untagged), "; ".join(untagged)
            )
        )

    sys.exit(0)
except Exception as _fc_e:
    _fc_sys.stderr.write("localization-mqm-tagging: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "localization-mqm-tagging: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
