#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|Bash) for localization-verdict-axis.
# Targets docs/issue-<n>/reports/localization.md at terminal loop_state
# (default terminal set: "landed"). Requires, per declared target locale, a
# two-axis verdict line in the form:
#   - <locale>: checklist=<pass|fail|N/A(reason)>, style=<pass|fail|N/A(reason)>
# A declared locale (from a `target locale` heading's list items) with no
# verdict line is denied unless it appears in an explicit
# "verdict-less locales:" exclusion line with a reason.
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit reconstruction primitives, replacing this gate's hand-rolled
# copies. This gate runs alongside base's record-fields-localization-gate.sh
# (loose existence check) and localization-mqm-tagging's gate (independent
# AND composition on the same PreToolUse matcher) — none of the three knows
# about the others.
#
# Semantic upgrade (issue-10): implements the verdict-less-locale check the
# header already promised — the declared target-locale list (from the
# `target locale` heading) is cross-referenced against locales that have a
# verdict line, and a declared locale with neither a verdict nor a
# "verdict-less locales: <locale>(<reason>)" entry is denied.
#
# Kill switch: export LOCALIZATION_VERDICT_AXIS_GATE_OFF=1
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "localization-verdict-axis.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="localization-verdict-axis"

gate_kill_switch_active "${LOCALIZATION_VERDICT_AXIS_GATE_OFF:-}" || exit 0
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
    gate_deny "$GATE_NAME" "a Bash command appears to write docs/issue-<n>/reports/localization.md but its resulting content cannot be reconstructed from a shell command; use Write/Edit/MultiEdit so locale verdicts can be checked."
  fi
  exit 0
fi

VA_PAYLOAD="$payload" VA_ROOT="$root" \
VA_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("localization-verdict-axis: refused — %s\n" % m)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("VA_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["VA_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/localization\.md$')
    TERMINAL = set(os.environ["VA_TERMINAL"].split())

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
            "old_string matches, so locale verdicts can be checked." % (rel, tool)
        )

    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    loop_state = m_ls.group(1).strip().lower() if m_ls else None
    if loop_state not in TERMINAL:
        sys.exit(0)  # non-terminal record: this extension does not apply yet

    lines = new_text.splitlines()

    VERDICT_LINE = re.compile(
        r'^\s*-\s*([A-Za-z]{2}(?:-[A-Za-z]{2})?)\s*:\s*checklist=(\S.*?)\s*,\s*style=(\S.*?)\s*$',
        re.M,
    )
    verdicted = {}
    for mo in VERDICT_LINE.finditer(new_text):
        verdicted[mo.group(1)] = (mo.group(2).strip(), mo.group(3).strip())

    VERDICT_LESS_LINE = re.compile(r'^\s*verdict-less locales?\s*:\s*(.+)$', re.M | re.I)
    verdictless = set()
    m_vl = VERDICT_LESS_LINE.search(new_text)
    if m_vl:
        for tok in re.findall(r'([A-Za-z]{2}(?:-[A-Za-z]{2})?)\s*\([^)]*\)', m_vl.group(1)):
            verdictless.add(tok)

    # Declared target-locale list: list items under a `target locale`
    # heading, before the next heading of any level.
    locale_heading_re = re.compile(r'^#{1,6}\s*target locale\b', re.I)
    declared = []
    for i, line in enumerate(lines):
        if locale_heading_re.match(line):
            for j in range(i + 1, len(lines)):
                if re.match(r'^#{1,6}\s', lines[j]):
                    break
                mm = re.match(r'^\s*[-*]\s+([A-Za-z]{2}(?:-[A-Za-z]{2})?)\b', lines[j])
                if mm:
                    declared.append(mm.group(1))
            break

    if declared:
        missing_locales = [loc for loc in declared if loc not in verdicted and loc not in verdictless]
        if missing_locales:
            deny(
                "declared target locale(s) %s have neither a two-axis verdict line nor "
                "a 'verdict-less locales: <locale>(<reason>)' exclusion entry." % (
                    ", ".join(missing_locales)
                )
            )
    elif not verdicted:
        deny(
            "terminal localization record has no per-locale two-axis verdict line. Per "
            "issue-1 (b)-1, each target locale needs a line "
            "'- <locale>: checklist=<verdict>, style=<verdict>' (verdict may be "
            "N/A(reason) when the axis does not apply)."
        )

    for locale, (checklist_v, style_v) in verdicted.items():
        for axis, v in (("checklist", checklist_v), ("style", style_v)):
            if v.upper().startswith("N/A") and "(" not in v:
                deny(
                    "locale %s has an N/A %s verdict with no reason given — N/A verdicts "
                    "must state why the axis does not apply, e.g. 'N/A(no string "
                    "resources)'." % (locale, axis)
                )

    sys.exit(0)
except Exception as _fc_e:
    _fc_sys.stderr.write("localization-verdict-axis: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "localization-verdict-axis: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
