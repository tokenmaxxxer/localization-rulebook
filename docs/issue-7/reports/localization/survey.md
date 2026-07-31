---
status: draft
issue: issue-7
---

# Current-state survey: plugin enforcement depth vs. implementation-rulebook bar

## What exists today (post issue-1/issue-2)

- `localization/hooks/directive.sh` — stub-form (issue-2), single
  `core_role_directive` call with 4 role-unique single-line strings
  (YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF). PRODUCES already carries
  the issue-1 methodology names ("checklist+style-guide basis",
  "MQM-tagged") but each facet is exactly one line — no steps, no
  judgment criteria, no prohibitions anywhere in the directive.
- `localization/hooks/record-fields-localization-gate.sh` — PreToolUse
  gate, fires only on `docs/issue-<n>/reports/localization.md` writes at
  terminal `loop_state`. Checks two things: a locale-list token present,
  one MQM-dimension string present anywhere in the text. This is a
  **presence** check (does the word "locale" appear, does one of 8 MQM
  words appear) — it does not check per-issue tagging, does not check
  the two-axis verdict structure (checklist vs. style-guide), does not
  check the N/A rule for non-code artifacts, and does not touch the
  **phase-1 proposal** write surface at all.
- No gate exists on `docs/issue-<n>/proposals/*localization*.md` — the
  four required proposal sections from
  `docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md` (a)
  (조사 근거 / 채택 항목 / 논리적 근거 / 반영 계획) are documented in prose
  only; nothing machine-checks a future proposal actually has them.
- No `tests/` directory anywhere in this repo. The one gate that exists
  has never been exercised by a repo-committed test — issue-1's report
  records manual `EXIT=0`/`EXIT=2` runs, not a checked-in reproducible
  test.
- No `localization/agents/` (removed in issue-2, correctly — it held only
  a generic warrant-hunter stance now superseded by core canon). No
  checklist file anywhere encodes the mechanical i18n items the
  directive's PRODUCES value already promises ("externalization/encoding/
  plural/key completeness" — named in the issue-1 proposal body, never
  written down as an actual enumerable list).
- No state-tracking file/lock anywhere in `localization/hooks/` — nothing
  like `implementation-rulebook`'s `.warrant-hunt.lock`/`.count` pair
  exists, because nothing in this rulebook currently claims an order
  constraint that would need one.

## Gap vs. the issue's stated bar (implementation-rulebook)

`implementation-rulebook/coding/hooks/` carries: a directive
(`directive.sh`), a progress gate that reads a *different role's* record
and blocks a commit on unresolved findings
(`coding-progress-gate.sh`, ~180 lines, fail-closed trap-at-top,
subject-scoped, resolved-findings cross-check), a dispatch-bounding state
machine (`hunt-guard.sh` + `hunt-state.sh`, lock+count files, staleness
detection), and `implementation-rulebook/tests/run-gate-tests.sh` running
pass/deny fixtures against every gate. `pricing-rulebook/pricing/hooks/`
carries a `methodology-gate.sh` that checks BOTH the phase-1 proposal
surface and the phase-2 record surface for the domain's own required
elements (method named, family named, inputs stated, gate-check result,
labeled numbers, residual list) — same fail-closed trap-at-top shape,
same root-resolution helper, same "role-specific extension on top of
core, never a replacement" framing.

localization has: one directive with no per-facet depth, one gate that
checks only the phase-2 record surface and only by loose keyword
presence, no tests, no state tracking, no checklist. That is the gap
issue #7 asks to close, scoped to what this role's already-adopted
methodology (issue-1 norms) actually needs enforced — not a blanket
copy of coding's or pricing's file set.

## Order-constraint question (does this role need state tracking?)

Checked the issue-1 norms proposal (b) methodology text for a temporal
dependency machine-enforceable across tool calls (the reason
`hunt-guard.sh`/`hunt-state.sh` exist for coding — dispatch count and
single-flight are process-level facts a prompt cannot self-enforce).
Localization's two-axis verdict (mechanical checklist / style-guide) and
MQM tagging are fields inside a single record write, not a sequence of
separate tool calls with a would-be-violated order between them — the
existing terminal-state gate already forces both to be present together
at the one write that matters (landing). No cross-call order exists here
for a lock/counter to guard. This is examined further against the field
in scout-brief.md and resolved as a proposal decision in
docs/issue-7/proposals/.

## Unknowns going into scouting

- Whether pricing's 6-element methodology-gate check list generalizes
  cleanly to localization's 4-section proposal + 4-element record shape,
  or needs different element names.
- What a minimal-but-real gate test harness looks like for a repo that
  has never had one (no existing `tests/run-gate-tests.sh` to reuse
  in-repo — implementation-rulebook's is the closest model, referenced
  not copied).
