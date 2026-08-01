# issue-10 phase-1 proposal: gate-house A+ remediation

Subject: issue-10, role: localization. Precondition confirmed (survey,
"Prerequisite check"): core issue #72 has landed —
`core/hooks/lib/gate-lib.sh`/`gate-lib.py` and
`docs/handbooks/gate-house-standard.md` exist on `tokenmaxxxer-core` main.

## 조사 근거

- `docs/issue-10/reports/localization/survey.md` Finding 1: all 4 gate
  scripts carry a "trap-at-top" header comment but contain no `trap ...
  EXIT` statement anywhere in the bash layer — confirms the issue body's
  "trap-at-top 주석만 있고 실물 부재" verbatim.
- survey.md Finding 2: `verdict-axis-gate.sh:8-9`'s own comment describes a
  "verdict-less locales:" exclusion check that `verdict-axis-gate.sh:165-
  189`'s code never implements — confirms "verdict-less locales 검사
  미구현" verbatim.
- survey.md Finding 3: `mqm-tagging-gate.sh:169-181`'s adjacency logic is
  genuinely structural (same-line-or-next-line), confirming the issue
  body's "MQM 인접성은 진짜" — this file's semantic logic needs no rewrite,
  only the gate-lib migration below.
- survey.md Finding 4: `record-fields-localization-gate.sh:171-177` and
  `methodology-gate.sh:150-151` are bare substring-anywhere-in-document
  checks — the issue body's requirement 2 ("시맨틱 검사를 부분문자열에서
  섹션/인접성/구조 검사로 상향") names exactly this gap.
- survey.md Finding 5: 4 independent hand-rolled `Edit`/`MultiEdit`
  reconstructions, none honoring `replace_all`, none supporting
  `NotebookEdit` — matches the issue body's explicit ask ("Edit/MultiEdit/
  replace_all 완전 재구성") and `gate-house-standard.md`'s named bug #2
  ("`replace_all` ignored").
- survey.md Finding 6/7: hand-rolled malformed-JSON handling and the
  pre-issue-72 inverted kill-switch idiom in all 4 gates — matches the
  issue body's "malformed-JSON deny, 킬스위치 비인식 값=활성" ask and
  `gate-house-standard.md`'s named bug #1.
- survey.md Finding 8: no gate matches `Bash`-tool writes — the issue body
  requires this as a mandatory test case class (§3), and
  `gate-house-standard.md:34-37` names `gate_bash_write_targets` as the
  existing canon fix, already precedented in `approval-gate.sh`/
  `board-gate.sh`.
- survey.md Finding 9: `README.md:25` names a nonexistent
  `record-fields-gate.sh` and omits all 3 issue-7 plugins — matches the
  issue body's requirement 4 verbatim.
- scout-brief.md: core's `gate-house-standard.md` is the sole landed
  exemplar (no sibling rulebook has migrated yet, confirmed by a 0-hit
  code search); its 7 `gate_*` functions and 6 mandatory test-case groups
  are adopted directly. The scout brief also flags, as an explicit
  assumption (no external precedent existed to cite): the verdict-less-
  locale check and the two substring→structure semantic upgrades are
  this role's own methodology semantics and are not expected to live in
  core's shared library — assumed, not sourced, because no exemplar
  addresses a role-specific semantic check by definition.

## 채택 항목

1. **Source `gate-lib.sh`/`gate-lib.py` in all 4 gate scripts**
   (`record-fields-localization-gate.sh`, `methodology-gate.sh`,
   `verdict-axis-gate.sh`, `mqm-tagging-gate.sh`), per the usage comment
   in `gate-lib.sh:11-26`:
   - `gate_trap_fail_closed` called as the literal first statement, before
     `set -uo pipefail`.
   - Kill-switch checks replaced with `gate_kill_switch_active
     "${..._OFF:-}"`.
   - `gate_deny`/`gate_allow` replace the hand-rolled `deny()` helper and
     bare `exit 0`/`exit 2` calls.
   - The Python payload loads `gate-lib.py` via `$GATE_LIB_PY`
     (`importlib`, per `gate-lib.sh:21-26`) and calls
     `gate_parse_json_or_deny`, `gate_normalize_path`,
     `gate_reconstruct_write` instead of the 4 independent hand-rolled
     copies of each.
   - Bash-layer `Bash`-tool coverage added via `gate_bash_write_targets`,
     applying each gate's existing path pattern
     (`RECORD_RE`/`TARGET_RE`) to every candidate token, so a
     `Bash`-tool write to the same target file is caught identically to
     a `Write`-tool call.
2. **Semantic upgrade: base locale/MQM check
   (`record-fields-localization-gate.sh`)** — replace the substring
   checks (survey Finding 4) with a section-anchored check: require a
   markdown heading matching `^#+\s*target locale` (case-insensitive)
   followed by at least one non-empty list item before the next heading,
   and require at minimum one of the MQM-tagging plugin's own section
   markers (`## mqm tags`/adjacent tag) to exist as a heading, not merely
   the word "locale"/a dimension name anywhere in the document.
3. **Semantic upgrade: verdict-less-locale enforcement
   (`verdict-axis-gate.sh`)** — implement the check the header comment
   already promises: parse the declared target-locale list from the same
   `## target locale`-style heading item 2 introduces, cross-reference
   against `verdicted` (already-collected two-axis verdict lines), and
   deny when a declared locale has neither a verdict line nor an entry in
   an explicit `verdict-less locales: <locale>(<reason>)` line.
4. **Semantic upgrade: proposal 4-section structure
   (`methodology-gate.sh`)** — replace the bare substring check (survey
   Finding 4) with a heading-anchored check: each of the 4 required
   section names must appear as a markdown heading line (`^#+\s*<name>`),
   not merely anywhere in prose.
5. **Mandatory test cases** — extend each plugin's `tests/cases.sh` plus
   `tests/run-gate-tests.sh`'s base-gate cases with all 6
   `gate-house-standard.md:60-72` groups, run against every one of the 4
   gates: `Edit` `replace_all: true` on a multiply-occurring
   `old_string`; `MultiEdit` with mixed `replace_all` flags; malformed
   JSON (truncated/non-object/empty, 3 sub-cases); kill-switch set to an
   unrecognized value asserting the gate stays active; an absolute
   `file_path` plus a `./`-prefixed variant matching the same scope a
   relative-path fixture already matches; a `Bash`-tool write reaching
   the same target a `Write`-tool call would hit. Plus 3 new cases for
   items 2-4's semantic upgrades (verdict-less-locale deny,
   section-heading-vs-substring-only deny, locale-list-heading deny).
   Full suite green in delivery state (issue body §3).
6. **`compliance-check.sh` as delivery evidence** — run
   `core/hooks/tests/compliance-check.sh` against `localization/hooks`
   before migration (recording the violation list) and after (asserting
   clean), citing both runs in the phase-2 record, per
   `gate-house-standard.md`'s per-repo migration checklist steps 1 and 4.
7. **README realignment** — fix `README.md:25`'s nonexistent
   `record-fields-gate.sh` reference to the real filename
   (`record-fields-localization-gate.sh`), and add the 3 issue-7 plugins,
   their kill switches, and `tests/run-gate-tests.sh` to the Layout
   section (issue body requirement 4).

## 논리적 근거

- Items 1 and 6 are adopted because the issue's own precondition names
  core issue #72's library as the mandatory reference ("그 라이브러리를
  참조해 구현(자체 재구현 금지)") — sourcing `gate-lib.sh`/`gate-lib.py`
  directly, rather than re-deriving fixes for the same 6 defect classes
  independently in this repo, is both what the issue requires and what
  `gate-house-standard.md`'s reference-not-copy rule and
  `canon-manifest.txt`/`stub-check.sh` enforcement expect: a hand-rolled
  fix here would itself register as a compliance violation the moment
  `compliance-check.sh` runs.
- Items 2-4 exist because the shared library only fixes the 3 *generic*
  defect classes (trap, kill switch, JSON/reconstruction) named in
  `gate-house-standard.md` — it does not and should not know this role's
  own methodology semantics (locale declarations, MQM tag structure,
  4-section proposal structure). The issue's requirement 2
  ("시맨틱 검사를 부분문자열에서 섹션/인접성/구조 검사로 상향") is a
  role-specific ask that has to be implemented in this role's own gate
  code, using the now-shared reconstruction/normalization primitives but
  not delegating the judgment itself to core.
- Item 5 is adopted verbatim from `gate-house-standard.md`'s own mandatory
  test harness list (6 groups) plus 3 role-specific cases for the 3
  semantic upgrades — the issue body explicitly requires these case
  classes and a fully green suite at delivery (§3); running a subset would
  leave exactly the gap `gate-house-standard.md`'s harness was built to
  close as untested.
- Item 7 is adopted because a ghost file reference and undocumented
  plugins are themselves an audit-grade defect (issue requirement 4,
  survey Finding 9) independent of the gate-code fixes — a reader
  following `README.md` today cannot find the file it names, and cannot
  discover 3 of the 4 gates that actually run.

## 반영 계획

Phase 2 (opens only after an approvers.md Approve, per contract v3 s19),
in dependency order:

1. Migrate `record-fields-localization-gate.sh`, `methodology-gate.sh`,
   `verdict-axis-gate.sh`, `mqm-tagging-gate.sh` to source
   `gate-lib.sh`/load `gate-lib.py` (adopted item 1). Run
   `compliance-check.sh` before (baseline) and after (must be clean) —
   adopted item 6.
2. Implement the 3 semantic upgrades (adopted items 2-4) on top of the
   migrated gates, so the section/adjacency/verdict-less checks use
   `gate_normalize_path`/`gate_reconstruct_write` from step 1 rather than
   the old hand-rolled reconstruction.
3. Extend `tests/cases.sh` per plugin and `tests/run-gate-tests.sh`'s
   base-gate section with all 6 mandatory groups + 3 semantic-upgrade
   cases (adopted item 5); run to green.
4. Fix `README.md` (adopted item 7).
5. Record the phase-2 delivery in
   `docs/issue-10/reports/localization.md` (this role's terminal record),
   citing the before/after `compliance-check.sh` output and the full
   green test run as verification evidence — the same record-fields
   gates this issue is remediating apply to that write, so its own
   locale-list/MQM-tag/verdict fields must satisfy the now-upgraded
   checks.
