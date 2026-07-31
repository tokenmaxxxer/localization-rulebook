#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — role-specific extension on top of
# core's record-fields-gate.sh (§20 minimums). Applies only when the write
# targets this role's own record (docs/issue-<n>/reports/localization.md)
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
# fields §20 does not know about. Not a copy of core/hooks/record-fields-gate.sh
# (core canon is referenced via role-directive.sh, never vendored here).
#
# Kill switch: export RECORD_FIELDS_LOCALIZATION_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-}"
deny() { echo "${role:-record-fields-localization-gate}: refused — $1" >&2; exit 2; }

case "${RECORD_FIELDS_LOCALIZATION_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "$role" = "localization" ] || exit 0

command -v python3 >/dev/null 2>&1 || deny "record-fields-localization-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "record-fields-localization-gate: empty tool-use payload on stdin; cannot evaluate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
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

RF_PAYLOAD="$payload" RF_ROOT="$root" \
RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("record-fields-localization-gate: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("RF_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; cannot judge localization record fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["RF_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/localization\.md$')
    TERMINAL = set(os.environ["RF_TERMINAL"].split())

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
            "old_string matches, so locale/MQM fields can be checked." % (rel, tool)
        )

    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    loop_state = m_ls.group(1).strip().lower() if m_ls else None
    if loop_state not in TERMINAL:
        sys.exit(0)  # non-terminal record: this extension does not apply yet

    low = new_text.lower()
    missing = []

    if not re.search(r'\btarget locale', low) and "locale" not in low:
        missing.append("locale-list")

    mqm_dims = ["accuracy", "fluency", "terminology", "locale convention",
                "style", "verity", "design", "internationalization"]
    if not any(d in low for d in mqm_dims):
        missing.append("mqm-tag")

    if missing:
        deny(
            "terminal localization record is missing required field(s): %s. Per the "
            "approved norms proposal, a terminal-state record must show a target-locale "
            "list and tag every string-external issue with one of the MQM 8 top-level "
            "dimensions (Accuracy, Fluency, Terminology, Locale convention, Style, "
            "Verity, Design, Internationalization)." % ", ".join(missing)
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
