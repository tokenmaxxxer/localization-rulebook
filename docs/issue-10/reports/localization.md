# issue-10 phase-2 record: gate-house A+ remediation delivery

Subject: issue-10, role: localization.

loop_state: landed

## What was done

This delivery migrates all 4 of this role's gates
(`record-fields-localization-gate.sh`, `methodology-gate.sh`,
`verdict-axis-gate.sh`, `mqm-tagging-gate.sh`) to source core issue #72's
gate-house standard library, fixes the two confirmed defect classes (no
real fail-closed trap, no verdict-less-locale check despite the header
promising one), upgrades 2 semantic checks from substring to
section/heading-anchored, adds the gate-house standard's 6 mandatory test
groups plus 3 semantic-upgrade cases across all 4 gates, and realigns
README.md with the actual plugin set.

## Why

Per issue-10 (based on the 2026-08-01 real-code audit that graded this
rulebook's gates B: "trap-at-top 주석만 있고 실물 부재"; "verdict-less
locales 검사 미구현") and the approved phase-1 proposal
(docs/issue-10/proposals/2026-08-01-gate-house-aplus-remediation.md,
approved by the `APPROVE issue-10/localization` issue comment): the gate
code's own header comments made promises (fail-closed trap,
verdict-less-locale exclusion) the code did not implement, and the
semantic checks were bare substrings a document could pass by mentioning
a word anywhere, not by actually satisfying the methodology. This round's
own deliverable is infra/gate work, not a locale-facing translation
artifact — no locale-specific content was produced, recorded below as an
explicit N/A verdict rather than omitted.

## target locale

- xx: no locale-specific deliverable this round (gate/test/doc remediation only, see the N/A verdict below).

## MQM tags

No string-external issues were produced or reviewed this round; this
delivery does not touch any translated or locale-facing copy, so there is
nothing for the MQM-tagging gate's adjacency check to tag.

## 1. gate-lib migration (adopted item 1)

All 4 gates now:

- Source `core/hooks/lib/gate-lib.sh` and call `gate_trap_fail_closed` as
  the literal first statement (before `set -uo pipefail`), replacing the
  "trap-at-top" comment-only shape the 2026-08-01 audit found — the
  header now matches real code: any non-0/2 exit remaps to 2.
- Call `gate_kill_switch_active "${..._OFF:-}"` instead of the old
  `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac` idiom, which
  treated any unrecognized value (including a typo) as "disable" — the
  confirmed fail-open bug. The new convention: only a recognized
  on-spelling (`1`/`true`/`yes`/`on`) disables; everything else, including
  garbage, stays active.
- Call `gate_deny`/`gate_allow` in place of the hand-rolled `deny()`
  helper and bare `exit 0`/`exit 2`.
- Load `gate-lib.py` via `importlib` in each gate's Python payload and
  call `gate_parse_json_or_deny`, `gate_normalize_path`,
  `gate_reconstruct_write` instead of 4 independently hand-rolled copies
  of JSON parsing, path resolution, and `Edit`/`MultiEdit` reconstruction
  (the previous code always did `text.replace(old, new, 1)` regardless of
  `replace_all` — the second confirmed defect class).
- Match a `Bash`-tool write reaching the same target path via
  `gate_bash_write_targets`, fail-closed denying it (a shell command's
  resulting content cannot be reconstructed the way a `Write`/`Edit`/
  `MultiEdit` call's can).

## 2. Semantic upgrades (adopted items 2-4)

- `record-fields-localization-gate.sh`: replaced the substring checks
  (`"locale" in low`, any MQM dimension word "anywhere") with a
  section-anchored check — requires a `target locale` heading followed by
  at least one list item before the next heading, and either an
  `MQM tags` heading or at least one adjacently-tagged `- issue:` bullet.
- `verdict-axis-gate.sh`: implemented the verdict-less-locale check the
  header already promised but the code never ran — the declared
  target-locale list (from the `target locale` heading's items) is now
  cross-referenced against locales with a two-axis verdict line, denying
  any declared locale with neither a verdict nor an explicit
  `verdict-less locales: <locale>(<reason>)` entry.
- `methodology-gate.sh`: replaced the bare "section name anywhere in the
  document" substring check with a heading-anchored check — each of the 4
  required section names must appear as a markdown heading line.
- `mqm-tagging-gate.sh`: no semantic change — its same-line/next-line
  adjacency check was already confirmed structural in phase-1 survey
  Finding 3, so only the gate-lib migration applies.

## 3. Mandatory test cases (adopted item 5) — full suite green

`tests/run-gate-tests.sh` now runs, for all 4 gates:

1. `Edit` `replace_all: true` against a multiply-occurring `old_string`.
2. `MultiEdit` with mixed `replace_all` flags in one call.
3. Malformed JSON: truncated, non-object, and empty payloads (3 cases).
4. Kill-switch set to an unrecognized value, asserting the gate stays
   active (denies a write it would otherwise deny).
5. An absolute `file_path` and a `./`-prefixed variant, both matching the
   same scope a relative-path fixture already matches.
6. A `Bash`-tool write reaching the same target a `Write`-tool call would
   hit.

Plus 3 role-specific semantic-upgrade cases: a proposal denied for
mentioning all 4 section names in prose with no headings, a base-record
denied for a `target locale` heading with no list item before the next
heading, and a verdict-axis denial/allow pair for a declared locale
covered (or not) by a `verdict-less locales:` exclusion.

Delivery-state run (`bash tests/run-gate-tests.sh`, `CORE_REF_DIR` pointed
at the local `tokenmaxxxer-core` checkout):

```
gate tests: 55 passed, 0 failed
```

## 4. compliance-check.sh evidence (adopted item 6)

`core/hooks/tests/compliance-check.sh`, run against each gate's directory
before and after migration:

Before (baseline, on `f30e968`, the commit this phase-2 work started
from):

```
compliance-check: FAIL — record-fields-localization-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write
compliance-check: FAIL — methodology-gate.sh: (same 2 reasons)
compliance-check: FAIL — verdict-axis-gate.sh: (same 2 reasons)
compliance-check: FAIL — mqm-tagging-gate.sh: (same 2 reasons)
```

After (this delivery):

```
compliance-check: ok — localization/hooks/record-fields-localization-gate.sh
compliance-check: ok — localization/plugins/proposal-gate/hooks/methodology-gate.sh
compliance-check: ok — localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh
compliance-check: ok — localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh
```

## 5. README realignment (adopted item 7)

`README.md`'s Layout section no longer names the nonexistent
`record-fields-gate.sh`/`trailer-gate.sh`/`handbook-trigger-gate.sh`/
`agents/warrant-hunter.md` — it now documents the real base gate plus all
3 issue-7 plugins (their kill switches, gate-lib sourcing, and
`Bash`-tool coverage), and `tests/run-gate-tests.sh`.

## Verdict

- xx: checklist=N/A(no locale-specific string content this round; gate/test/doc code only), style=N/A(no locale-facing copy was produced or reviewed this round)

## Open findings

None outstanding — all 6 mandatory gate-house-standard test groups plus
the 3 semantic-upgrade cases pass across all 4 gates, and
`compliance-check.sh` is clean on all 4 (see section 4). This closes
issue-10's requirements 1-4 in full.
