# issue-10 phase-1 survey: current-state gate audit

Scope: the 4 write-surface gates under `localization/` — base
`hooks/record-fields-localization-gate.sh`, and the 3 issue-7 plugins'
`hooks/methodology-gate.sh` (proposal-gate), `hooks/verdict-axis-gate.sh`
(verdict-axis), `hooks/mqm-tagging-gate.sh` (mqm-tagging) — plus
`tests/run-gate-tests.sh`, each plugin's `tests/cases.sh`, and the root
`README.md`. Read in full before this survey; line numbers below are from
the working-tree copies on `issue-10/localization`.

## Finding 1 — trap-at-top is a comment, not code (confirms issue body)

All 4 gate scripts (`record-fields-localization-gate.sh:1-20`,
`methodology-gate.sh:1-18`, `verdict-axis-gate.sh:1-19`,
`mqm-tagging-gate.sh:1-18`) carry header comments describing
"trap-at-top ... fail-closed" as a referenced structural property, but
none of the 4 files contains an actual `trap ... EXIT` statement. Each
script does `set -uo pipefail` then runs a Python payload inside a
`try/except` (e.g. `mqm-tagging-gate.sh:72-196`) that catches *internal*
Python exceptions and denies — but nothing in the *bash* layer traps a
bash-level abort (e.g. `python3` not found after the `command -v` check
races, a signal, an unexpected `set -e`-independent failure in the
`_target`/`_under` shell functions). Per Claude Code's hook contract, an
exit code other than 0/2 is treated as non-blocking (fail-open); with no
bash-level trap remapping other exits to 2, an unexpected abort before the
Python heredoc runs is fail-open. This is exactly the defect class
`gate_trap_fail_closed` (`core/hooks/lib/gate-lib.sh:36-41`) was built to
close.

## Finding 2 — verdict-less-locale check is documented, not implemented (confirms issue body)

`verdict-axis-gate.sh:8-9`'s header comment states: "A locale with no
verdict line at all is denied unless it appears in an explicit
'verdict-less locales:' exclusion line with a reason." The implementation
(`verdict-axis-gate.sh:165-189`) only does two things: (a) regex-collects
whatever `- <locale>: checklist=..., style=...` lines exist into
`verdicted`, denying only if the dict is empty; (b) for each *collected*
locale, denies an `N/A` axis with no reason. It never reads a declared
target-locale list and never checks for the `verdict-less locales:` line
at all — there is no code path that can fire on "declared locale ko-KR
has no verdict line and no exclusion entry." A terminal record that lists
`ko-KR, ja-JP` as target locales but only writes a verdict line for
`ko-KR` currently passes this gate, silently.

## Finding 3 — MQM adjacency is real (issue body: correct, not a defect)

`mqm-tagging-gate.sh:169-181` builds `adjacent = line [+ next line if not
another issue bullet]` and requires `DIM_RE.search(adjacent)` — genuine
same-line-or-next-line structural adjacency, not a document-wide
substring scan. Confirmed correct; no change needed to this file's
semantic logic itself (only the gate-lib migration below applies to it).

## Finding 4 — semantic checks elsewhere are substring, not
   section/structure (issue requirement 2, beyond the two named bugs)

- `record-fields-localization-gate.sh:171-177`: the base gate's "locale"
  and "mqm tag" checks are bare substring tests over the whole lower-cased
  document (`"locale" not in low`, `any(d in low for d in mqm_dims)`). A
  sentence anywhere in the document containing the word "locale" (e.g. in
  this very survey's prose, if pasted into a record) satisfies it; there
  is no requirement that a locale list or MQM tag appear in any
  particular section.
- `methodology-gate.sh:150-151` (proposal-gate): `REQUIRED = ["조사 근거",
  "채택 항목", "논리적 근거", "반영 계획"]` then `s not in new_text` — a bare
  substring-anywhere check. A proposal whose only occurrence of "채택
  항목" is inside an unrelated sentence (not a section heading) currently
  passes.

## Finding 5 — Edit/MultiEdit/replace_all reconstruction is hand-rolled and incomplete

All 4 gates independently reimplement content reconstruction
(`record-fields-localization-gate.sh:132-154`,
`methodology-gate.sh:119-141`, `mqm-tagging-gate.sh:128-150`,
`verdict-axis-gate.sh:129-151` — four near-identical copies). None
supports `NotebookEdit`. `Edit`'s reconstruction is
`current.replace(o, n, 1)` unconditionally — it ignores the tool call's
own `replace_all` field entirely (a `replace_all: true` Edit against a
multiply-occurring `old_string` is judged against a text where only the
first occurrence was replaced, mismatching what Claude Code will actually
write). `MultiEdit`'s loop calls `text.replace(o, n, 1)` per edit
unconditionally too — same bug, and a `MultiEdit` with a per-edit
`replace_all: true` flag is silently judged wrong. This is exactly
`gate-house-standard.md`'s bug #2 (record-fields-gate.sh's own
pre-issue-72 history in core) reproduced independently in all 4 of this
role's gates.

## Finding 6 — malformed-JSON handling exists but is hand-rolled per gate

Each gate's Python payload does `json.loads(raw)` in a bare `try/except
ValueError` (e.g. `verdict-axis-gate.sh:81-83`) and a manual
`isinstance(ev, dict)` check. Functionally closer to correct than
Findings 1/2/5, but this is 4 independent hand-rolled copies of exactly
what `gate_lib.gate_parse_json_or_deny` (Python, `gate-lib.py`) now
centralizes — per `gate-house-standard.md`'s reference-not-copy rule, this
role should source it instead of keeping 4 divergent copies that can each
independently drift.

## Finding 7 — kill switches use the pre-issue-72 inverted idiom

Every one of the 4 gates' kill-switch check
(`record-fields-localization-gate.sh:25-28`, `methodology-gate.sh:15-18`,
`verdict-axis-gate.sh:23-26`, `mqm-tagging-gate.sh:22-25`) is:
`case "${..._OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac` — the
exact idiom `gate-house-standard.md`'s "two bugs this issue fixed" §1
names as core's own pre-issue-72 bug: any unrecognized value (a typo,
`1 ` with trailing space, `ON` vs `on` — actually case-insensitive here so
casing itself is fine, but any garbage string) falls to the `*)` branch
and disables the gate. All 4 of this role's kill switches reproduce this
exact defect and must move to `gate_kill_switch_active`.

## Finding 8 — no Bash-tool write coverage

All 4 gates match only `tool in ("Write", "Edit", "MultiEdit")`
(e.g. `verdict-axis-gate.sh:106-111`). A `Bash` tool call that writes to
`docs/issue-<n>/reports/localization.md` or a `*localization*.md` proposal
via shell redirection (`echo ... > docs/issue-7/reports/localization.md`)
is invisible to every one of these 4 gates today. `gate_bash_write_targets`
(`gate-lib.sh:88-90`) exists precisely to close this gap and is already
core canon precedent (`approval-gate.sh`/`board-gate.sh` per
`gate-house-standard.md:34-37`).

## Finding 9 — README references a nonexistent file, omits the 3 plugins

`README.md:25` documents `localization/hooks/record-fields-gate.sh` — the
actual file at that path is `record-fields-localization-gate.sh`
(confirmed absent: no `record-fields-gate.sh` exists under
`localization/hooks/`). The 3 issue-7 plugins
(`localization-proposal-gate`, `localization-verdict-axis`,
`localization-mqm-tagging`), their kill switches
(`LOCALIZATION_PROPOSAL_GATE_OFF`, `LOCALIZATION_VERDICT_AXIS_GATE_OFF`,
`LOCALIZATION_MQM_TAGGING_GATE_OFF`), and `tests/run-gate-tests.sh` are
entirely unmentioned in `README.md`.

## Prerequisite check — core issue #72 landing

`tokenmaxxxer/tokenmaxxxer-core` `main` (cloned read-only for this survey)
contains `core/hooks/lib/gate-lib.sh` + `gate-lib.py`,
`docs/handbooks/gate-house-standard.md`,
`core/hooks/tests/run-gate-lib-tests.sh`, and
`core/hooks/tests/compliance-check.sh` — issue #10's stated precondition
(core issue #72 landed) is satisfied; the reference library exists and is
usable today.

## Test-suite baseline

`tests/run-gate-tests.sh` currently runs 14 cases covering only
allow/deny/no-op per gate on the existing (substring/no-replace_all/no-JSON-
malform/no-kill-switch-value/no-absolute-path/no-Bash-write) semantics.
None of the 6 mandatory case groups `gate-house-standard.md:60-72`
requires (Edit `replace_all`, mixed-flag `MultiEdit`, malformed JSON,
kill-switch unrecognized-value-stays-active, absolute/`./`-prefixed path,
Bash-tool write) exist anywhere in this repo's test tree today.
