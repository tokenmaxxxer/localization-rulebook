#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|Bash) — role-specific extension on
# top of core's record-fields-gate.sh (§20 minimums). Applies only when the
# write targets this role's own record (docs/issue-<n>/reports/localization.md)
# AND the resulting loop_state is terminal (default: core's "landed", via
# RECORD_FIELDS_TERMINAL_STATES — unset here, no role-specific terminal
# state was found in phase 1 survey/scout).
#
# Per docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md (b):
# a terminal-state localization record must additionally show
#   (i) a target-locale list, and
#   (ii) every string-external issue tagged with one of the MQM 8
#       top-level dimensions (Accuracy, Fluency, Terminology, Locale
#       convention, Style, Verity, Design, Internationalization).
# This does not replace core's §20 check — it runs alongside it, checking
# fields §20 does not know about.
#
# Migrated to the gate-house standard (core issue #72):
# core/hooks/lib/gate-lib.sh / gate-lib.py are sourced/loaded for the
# fail-closed trap, kill-switch convention, JSON parse, path normalize and
# Write/Edit/MultiEdit reconstruction primitives, replacing the 4 hand-rolled
# copies this gate used to carry. Referenced only, never vendored
# (docs/handbooks/canon-scripts.md at core).
#
# Semantic upgrade (issue-10): section-anchored checks instead of bare
# substring matches — requires a `target locale` markdown heading with at
# least one list item before the next heading, and either an MQM-tagging
# heading marker (`## MQM tags`) or at least one adjacently-tagged
# `- issue:` bullet, instead of the word "locale"/a dimension name occurring
# anywhere in the document. (Full per-issue tag coverage is still owned by
# localization-mqm-tagging's own gate — this check only requires the field
# to be present at all.)
#
# Kill switch: export RECORD_FIELDS_LOCALIZATION_GATE_OFF=1
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="record-fields-localization-gate"

gate_kill_switch_active "${RECORD_FIELDS_LOCALIZATION_GATE_OFF:-}" || exit 0
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

# Bash-tool coverage: a shell command writing the target record directly
# (redirection, sed -i, etc.) has no reconstructable content, so it is
# fail-closed denied rather than silently allowed through a gate that only
# ever looked at Write/Edit/MultiEdit tool_input.
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
    gate_deny "$GATE_NAME" "a Bash command appears to write docs/issue-<n>/reports/localization.md but its resulting content cannot be reconstructed from a shell command; use Write/Edit/MultiEdit so locale/MQM fields can be checked."
  fi
  exit 0
fi

RF_PAYLOAD="$payload" RF_ROOT="$root" \
RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("record-fields-localization-gate: refused — %s\n" % m)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("RF_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["RF_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/localization\.md$')
    TERMINAL = set(os.environ["RF_TERMINAL"].split())

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
            "old_string matches, so locale/MQM fields can be checked." % (rel, tool)
        )

    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    loop_state = m_ls.group(1).strip().lower() if m_ls else None
    if loop_state not in TERMINAL:
        sys.exit(0)  # non-terminal record: this extension does not apply yet

    lines = new_text.splitlines()

    def heading_has_list_item(heading_re):
        for i, line in enumerate(lines):
            if heading_re.match(line):
                for j in range(i + 1, len(lines)):
                    if re.match(r'^#{1,6}\s', lines[j]):
                        break
                    if re.match(r'^\s*[-*]\s+\S', lines[j]):
                        return True
                return False
        return None

    missing = []

    locale_heading_re = re.compile(r'^#{1,6}\s*target locale\b', re.I)
    has_list = heading_has_list_item(locale_heading_re)
    if has_list is None:
        missing.append("target-locale-heading")
    elif has_list is False:
        missing.append("target-locale-list-item")

    mqm_heading_re = re.compile(r'^#{1,6}\s*mqm tags?\b', re.I)
    has_mqm_heading = any(mqm_heading_re.match(line) for line in lines)
    if not has_mqm_heading:
        DIMS = ["accuracy", "fluency", "terminology", "locale convention",
                "style", "verity", "design", "internationalization"]
        DIM_RE = re.compile(r'\[(%s)\]|\(tag:\s*(%s)\)' % (
            "|".join(DIMS), "|".join(DIMS)), re.I)
        ISSUE_RE = re.compile(r'^\s*-\s*issue\s*:', re.I)
        found = False
        for i, line in enumerate(lines):
            if not ISSUE_RE.match(line):
                continue
            adjacent = line
            if i + 1 < len(lines) and not ISSUE_RE.match(lines[i + 1]):
                adjacent += "\n" + lines[i + 1]
            if DIM_RE.search(adjacent):
                found = True
                break
        if not found:
            missing.append("mqm-heading-or-tagged-issue")

    if missing:
        deny(
            "terminal localization record is missing required field(s): %s. Per the "
            "approved norms proposal, a terminal-state record must show a "
            "`target locale` heading with at least one declared locale, and either "
            "an `MQM tags` heading or at least one MQM-tagged `- issue:` bullet." % (
                ", ".join(missing)
            )
        )

    sys.exit(0)
except Exception as _fc_e:
    _fc_sys.stderr.write("record-fields-localization-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "record-fields-localization-gate: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
