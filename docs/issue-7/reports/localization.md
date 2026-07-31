# issue-7 implementation record (phase 2)

## what was done

Executed the approved (revised) proposal
(`docs/issue-7/proposals/2026-07-31-plugin-enforcement-deepening.md`)
plugin plan exactly as designed — a **plugin set**, per the approver's
structural correction (issue #7 comment, 2026-07-31T13:08:55Z), not a
single directive/gate deepening:

1. **`localization/plugins/proposal-gate/`** (issue-1 (a) phase-1 제안서
   구조 규범 전담): `.claude-plugin/plugin.json`, `hooks/hooks.json`
   (SessionStart → `directive.sh`, PreToolUse `.*` →
   `methodology-gate.sh`), `hooks/directive.sh`, `hooks/methodology-gate.sh`
   (targets `docs/issue-<n>/proposals/*localization*.md`, requires the 4
   sections 조사 근거/채택 항목/논리적 근거/반영 계획), `tests/cases.sh`
   (allow/deny/no-op), `README.md`.
2. **`localization/plugins/verdict-axis/`** (issue-1 (b)-1 두 축 판정
   방법론 전담): same skeleton + `hooks/verdict-axis-gate.sh` (targets
   `docs/issue-<n>/reports/localization.md` at terminal `loop_state`,
   requires per-locale `checklist=`/`style=` verdict lines, N/A verdicts
   must carry a reason) + `checklists/locale-fitness-checklist.md` (4
   mechanical i18n items + N/A rule) + `tests/cases.sh` + `README.md`.
3. **`localization/plugins/mqm-tagging/`** (issue-1 (b)-2 MQM 8-dimension
   축소 채용 분류 전담): same skeleton + `hooks/mqm-tagging-gate.sh`
   (same record surface/terminal condition, requires each `- issue:`
   bullet to carry an adjacent MQM 8-dimension tag — same-line or
   next-line, not "anywhere in the document") + `tests/cases.sh` +
   `README.md`.
4. **Composition, not merge**: `verdict-axis` and `mqm-tagging` each
   register an independent PreToolUse hook on the exact same surface
   (`docs/issue-<n>/reports/localization.md`, matcher `.*`). Neither
   script references the other; Claude Code's "run every matching hook,
   deny if any denies" behavior is what makes the phase-2 AND requirement
   ("두 축 판정 AND MQM 태깅 모두 만족") hold, with no hand-written
   `if axis_ok && mqm_ok` anywhere.
5. **Base `localization` plugin untouched**: `core_role_directive`
   4-argument call form (issue-2 §3 frozen) not reopened; the existing
   `record-fields-localization-gate.sh` (loose existence check) stays as
   base's own minimal gate — the 3 new plugins layer stricter, precise
   checks on top (locale/MQM word-existence → structured verdict/tag
   parsing). Duplicate denial across gates is by design (fail-closed:
   several independent gates catching the same defect is strictly safer,
   never a bug).
6. **`.claude-plugin/marketplace.json`**: 3 new entries added next to
   `"localization"` — `localization-proposal-gate`,
   `localization-verdict-axis`, `localization-mqm-tagging` — each source
   pointing at its plugin directory, each description naming exactly one
   methodology.
7. **`tests/run-gate-tests.sh`** (repo-root, first of its kind): sources
   each plugin's `tests/cases.sh`, runs every case as a real subprocess
   (tempdir `git init` sandbox, JSON tool-call payload on stdin, exit-code
   assertion), plus base gate's reduced-scope existence cases. All 14
   cases pass (see Verification below).

## why

Per issue #7's phase-2 instruction and the approver's issue-level
correction comment: the maturation round (issue-1) left the adopted
methodology as a directive summary line + documentation only, with no
mechanical enforcement, and a single merged gate/directive would hide
which of the three methodologies a given check-failure is about behind
code-reading. Splitting one methodology = one self-contained plugin makes
`plugin.json`'s description the answer to "what does this check", mirrors
core's `freelunch`/`scout` pattern, and lets phase-1 (proposal-gate alone)
and phase-2 (verdict-axis + mqm-tagging composed) norms both be expressed
as plugin combinations rather than one script each — exactly what the
proposal's 플러그인 목록 table commits to.

No state-tracking machine (lock/count files) was introduced in any of the
3 plugins: per the phase-1 survey's order-constraint conclusion (reaffirmed
in the proposal), all three methodologies are single-terminal-write field
completeness checks, not tool-call-sequence constraints — splitting into
plugins does not change that.

## upstream basis

`docs/issue-7/proposals/2026-07-31-plugin-enforcement-deepening.md`
(revised per approver correction), approved via issue-level comment
`APPROVE issue-7/localization` by `JiwonJung94` (registered in
`docs/specs/approvers.md`, single-account mode). Derived from
`docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md` (a)/(b)
— the original definition of the 3 adopted methodologies — and
`docs/issue-7/reports/localization/survey.md` +
`docs/issue-7/reports/localization/scout-brief.md` for the current-state
gap analysis and the implementation-rulebook/pricing-rulebook reference
patterns (trap-at-top fail-closed gate structure, subprocess-based gate
test runner). Core canon scripts (`role-directive.sh`,
`record-fields-gate.sh`) are referenced only via the base plugin's
existing call form — not copied into any of the 3 new plugins.

## verification results

- `bash tests/run-gate-tests.sh`: **14 passed, 0 failed** — covers
  proposal-gate (allow/deny/no-op), verdict-axis (allow/deny-missing-
  reason/deny-no-verdict/no-op-nonterminal), mqm-tagging (allow/deny-
  untagged/allow-no-issues/no-op-nonterminal), and base gate's reduced-
  scope existence cases (allow/deny/no-op).
- All 7 new/edited JSON files (`marketplace.json` + 3×
  `plugin.json` + 3× `hooks.json`) parse as valid JSON
  (`python3 -c "import json; json.load(...)"`, all 7 `ok`).
- `directive.sh` heredoc content for all 3 plugins manually reviewed
  against the proposal's per-plugin directive spec (facet lists match the
  proposal's 채택 항목 section item-for-item).

**open verification point, not resolved this session** (carried from the
proposal, stated as an assumption, not a fact): whether Claude Code merges
SessionStart hooks across multiple plugins registered under the same role,
or only runs the last-registered one, was not confirmed by installing the 4
localization-family plugins together in a live session — this repo
checkout has no `core/` submodule content available to run a full
multi-plugin install here. PreToolUse's "all matching hooks run, any deny
blocks" behavior is confirmed by existing precedent (base's
`record-fields-localization-gate.sh` already coexists with core's own
`record-fields-gate.sh` PreToolUse hook), and this record's own gate tests
run each of the 3 new gates in isolation (subprocess per gate, not a
multi-plugin Claude Code session), which validates each gate independently
but does not validate cross-plugin runtime composition end-to-end.

## locale verdicts

This is an infrastructure/enforcement-tooling delivery (plugin set for
issue-7), not a translation review deliverable — no target locale had
content in scope this round.

- xx: checklist=N/A(infra/plugin delivery only; no string-external content this round), style=N/A(same)

## mqm tags

No string-external issues were found or reviewed this round (no `- issue:`
items below).

loop_state: landed

## open findings

None — plugin-set reflection executed as approved (revised architecture)
with no deviation. The one open verification point (multi-plugin
SessionStart merge behavior) is carried forward explicitly above, not
buried.
