# issue-13 phase-1 proposal: gate-house A+ final closure (localization)

Subject: issue-13, role: localization. Preconditions confirmed landed
(survey.md, "Precondition check"): core #75 (source-guard mandate +
`gate_bash_write_targets` py parity + missing-core mandatory test, PR
#76/#77 merged) and on-the-record #182 (`CLAUDE_PLUGIN_ROOT_CORE`
injection, PR #183/#185 merged).

## 조사 근거

- `docs/issue-13/reports/localization/survey.md` Finding 1: none of the 4
  gate scripts guard their `gate-lib.sh` source line — bare
  `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` at
  `localization/hooks/record-fields-localization-gate.sh:36`,
  `localization/plugins/proposal-gate/hooks/methodology-gate.sh:20`,
  `localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh:28`,
  `localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh:23` — this
  is the exact issue-75-confirmed fail-open shape core's own handbook
  describes, and matches the issue-13 body's "실측 fail-open 재현됨"
  verbatim.
- survey.md Finding 2: `tests/run-gate-tests.sh`'s `mandatory_group_cases`
  (lines 101-147) implements 6 of the now-7 gate-house-standard mandatory
  groups; no case exercises group 7 (missing-core deny,
  `gate-house-standard.md:84-86`) — grep for a missing-core scenario
  across the test runner and all 3 plugins' `tests/cases.sh` returns 0
  hits.
- survey.md Finding 3: all 4 `hooks.json` matchers are `.*` and each
  points at a gate script filename that actually exists on disk
  (cross-checked against `find localization/plugins -type f`) — no
  matcher-code misalignment found; this requirement axis needs no fix.
- survey.md Finding 4: no ghost files or stale role/plugin names found in
  `README.md` or any `plugin.json` (the issue-10-era ghost files were
  already fixed in `23fa5c4`); the one staleness gap is that
  `docs/issue-10/reports/localization.md:118-142`'s recorded
  `compliance-check.sh` "clean" evidence predates issue-75's new
  unguarded-source detection rule, so it no longer speaks to the current
  detector.
- scout-brief.md Angle 2: core's `gate-lib.sh` usage comment prescribes
  the exact guarded source-line shape to adopt; no alternative idiom is
  in scope, per the issue body's own "core #75의 확정 가드/규칙을 참조
  적용" instruction.
- scout-brief.md Angle 4: `mandatory_group_cases`'s existing per-case
  extra-env-args mechanism (`run "<label>" <expect> "$gate" <payload>
  ["$off_var=..."]`) already supports adding a group-7 case without a new
  bespoke runner, mirroring how groups 1-6 are shared across all 4 gates.

## 채택 항목

1. **Guard the `gate-lib.sh` source line in all 4 gates** — replace each
   bare `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` (survey Finding 1's 4 file:
   line citations) with the guarded form from `gate-lib.sh`'s own usage
   comment: `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo
   "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }`, substituting
   each gate's own `$GATE_NAME`-equivalent string. No other line in the
   existing `CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-...}"` assignment
   changes — that pattern is already correct (scout-brief Angle 2: this
   is a reference-verbatim application, not a redesign).
2. **Add the group-7 missing-core mandatory test case to
   `tests/run-gate-tests.sh`** — extend `mandatory_group_cases` (survey
   Finding 2) with a 7th case per gate: invoke the gate with
   `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path (e.g.
   `$SANDBOX/no-such-core`) and, to exclude the relative fallback, run
   from a `CLAUDE_PLUGIN_ROOT_CORE`-only invocation the fallback cannot
   satisfy (per `gate-house-standard.md:84-86`'s exact case shape:
   "nonexistent path and no valid relative fallback"); assert exit 2.
   Uses the existing `run` helper and extra-env-arg mechanism
   (scout-brief Angle 4) — no new runner needed. Applied uniformly to all
   4 gates via the shared `mandatory_group_cases` call sites (lines
   158-181), not per-gate duplication.
3. **Re-run `compliance-check.sh` and record fresh before/after
   evidence** — run `core/hooks/tests/compliance-check.sh` against
   `localization/hooks` and each plugin's `hooks/` directory before item 1
   lands (expected: FAIL, unguarded-source violation newly detected by
   issue-75's updated detector) and after (expected: clean), recording
   both outputs in the phase-2 record — closing survey Finding 4's
   staleness gap per `gate-house-standard.md`'s migration-checklist step
   4 ("Re-run `compliance-check.sh` clean").
4. **No README/manifest edit is proposed** — survey Finding 4 found no
   ghost file or stale role/plugin name to fix; re-running
   `compliance-check.sh` (item 3) is documentation-adjacent evidence, not
   a content fix, so it is scoped as its own item rather than folded into
   a README change that doesn't otherwise exist.
5. **No matcher change is proposed** — survey Finding 3 found `.*`
   matchers already aligned to real script names on disk in all 4
   `hooks.json` files; this requirement axis is confirmed clean, not
   remediated.

## 논리적 근거

- Item 1 is adopted because it is the one concrete, reproduced defect the
  issue body names ("공통(source 가드)만 ... 실측 fail-open 재현됨") and
  because core #75's handbook explicitly designates the guarded form as
  the mandatory shape every rulebook gate must carry — a hand-rolled
  guard idiom here, rather than the literal form in `gate-lib.sh`'s usage
  comment, would itself register as a `compliance-check.sh` violation the
  moment the updated detector runs (per `gate-house-standard.md`'s own
  "flags a gate that sources `gate-lib.sh` with no `||` guard" rule and
  the reference-not-copy discipline this role's issue-10 round already
  established for the shared library's other primitives).
- Item 2 is adopted because a fixed defect with no regression test is not
  durably fixed — `gate-house-standard.md`'s 7-group harness is
  mandatory ("a run that skips any of them fails the harness itself"),
  and the missing-core case is the one group this role's suite has never
  run since the guard itself (item 1) did not previously exist to test.
  Extending the existing shared helper rather than writing a bespoke
  runner keeps the 4 gates' coverage uniform, consistent with how the 6
  pre-existing groups are already structured.
- Item 3 is adopted because `gate-house-standard.md`'s migration checklist
  treats fresh before/after `compliance-check.sh` output as the delivery
  evidence for exactly this class of fix (unguarded source), and the
  existing issue-10-era record no longer reflects what the updated
  detector checks — an approver reading only the stale record would
  wrongly conclude this gap was already closed.
- Items 4 and 5 are proposed as explicit no-ops, not silent omissions,
  because the issue body requires all 4 remediation axes to be addressed
  (matcher alignment, README/manifest cleanup, missing-core coverage,
  source-guard fix) — recording "audited, found clean" for the two axes
  with no defect is itself part of closing the issue, distinguishing "not
  checked" from "checked and already correct."

## 반영 계획

Phase 2 (opens on human `APPROVE issue-13/localization`, this proposal
does not implement any of the below):

1. Apply item 1's guarded source-line edit to all 4 gate scripts (single-
   line change per file, in place of the current bare `. "$path"`).
2. Apply item 2's group-7 test case to `tests/run-gate-tests.sh`'s
   `mandatory_group_cases`, applied to all 4 `mandatory_group_cases` call
   sites (lines 158-181) so every gate gets the new case without
   duplicated logic.
3. Run `bash tests/run-gate-tests.sh` (full suite, `CORE_REF_DIR` pointed
   at a real `tokenmaxxxer-core` checkout) and record a green result
   (pass count, 0 failed) in the phase-2 record.
4. Run `core/hooks/tests/compliance-check.sh` against
   `localization/hooks` and each of the 3 plugins' `hooks/` directories
   twice: once before item 1's edit lands (on the pre-fix commit, to
   capture the newly-detected unguarded-source violation as baseline
   evidence) and once after (expected clean) — both outputs recorded
   verbatim in the phase-2 record per item 3's adoption rationale.
5. Write `docs/issue-13/reports/localization.md` (phase-2 record,
   `loop_state: landed`) citing this proposal's adopted items 1-3 by
   number, the compliance-check before/after transcripts, and an explicit
   N/A verdict for target-locale/MQM fields — consistent with issue-10's
   precedent, this round is infra/gate work only, no locale-facing
   translation artifact is produced.
6. No README.md or manifest edit ships in phase 2 (items 4-5's no-op
   findings stand unless phase-2 execution surfaces something this
   survey missed, in which case that would be flagged as a new gap
   rather than folded in silently).

## 조사-대상 표면 해당 여부 (verdict-axis / MQM 적용 가능성)

N/A — this proposal's scope is gate/test infrastructure only (source-guard
fix, missing-core test case, compliance-check re-run); no locale-facing
copy or string-external issue is produced or reviewed, so the
locale-fitness verdict axis and MQM tagging do not apply to this
document. (This proposal is not the phase-2 report file itself, where the
formal N/A verdict line will be recorded per plan item 5.)
