#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) for localization-verdict-axis.
# Targets docs/issue-<n>/reports/localization.md at terminal loop_state
# (default terminal set: "landed" — no role-specific terminal state found in
# phase-1 survey, kept as-is). Requires, per declared target locale, a
# two-axis verdict line in the form:
#   - <locale>: checklist=<pass|fail|N/A(reason)>, style=<pass|fail|N/A(reason)>
# A locale with no verdict line at all is denied unless it appears in an
# explicit "verdict-less locales:" exclusion line with a reason.
#
# Structure (trap-at-top, independent root resolution, Write/Edit/MultiEdit
# content reconstruction, fail-closed) referenced from pricing-rulebook's
# methodology-gate.sh — not vendored, rewritten for this surface. This gate
# runs alongside base's record-fields-localization-gate.sh (loose existence
# check) and localization-mqm-tagging's gate (independent AND composition on
# the same PreToolUse matcher) — none of the three knows about the others.
#
# Kill switch: export LOCALIZATION_VERDICT_AXIS_GATE_OFF=1
set -uo pipefail

deny() { echo "localization-verdict-axis: refused — $1" >&2; exit 2; }

case "${LOCALIZATION_VERDICT_AXIS_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "${CLAUDE_ROLE:-}" = "localization" ] || exit 0

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    v=ti.get("file_path")
    if isinstance(v,str) and v: print(v)
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed."

VA_PAYLOAD="$payload" VA_ROOT="$root" \
VA_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("localization-verdict-axis: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("VA_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; cannot judge locale verdicts on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["VA_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/localization\.md$')
    TERMINAL = set(os.environ["VA_TERMINAL"].split())

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the resulting content cannot be determined "
            "from the tool input (tool=%r); use Write, or an Edit/MultiEdit whose "
            "old_string matches, so locale verdicts can be checked." % (rel, tool)
        )

    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    loop_state = m_ls.group(1).strip().lower() if m_ls else None
    if loop_state not in TERMINAL:
        sys.exit(0)  # non-terminal record: this extension does not apply yet

    VERDICT_LINE = re.compile(
        r'^\s*-\s*([A-Za-z]{2}(?:-[A-Za-z]{2})?)\s*:\s*checklist=(\S.*?)\s*,\s*style=(\S.*?)\s*$',
        re.M,
    )
    verdicted = {}
    for mo in VERDICT_LINE.finditer(new_text):
        verdicted[mo.group(1)] = (mo.group(2).strip(), mo.group(3).strip())

    if not verdicted:
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
