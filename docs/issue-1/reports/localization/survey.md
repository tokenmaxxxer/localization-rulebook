---
status: draft
issue: issue-1
---

# Current-state survey (before scouting)

## What this rulebook currently has

- `localization/hooks/directive.sh` — core-canon stub (post issue-2/#4):
  role-unique 4 values only (YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF),
  sourced from `core/hooks/lib/role-directive.sh`. No local gates,
  no local `warrant-hunter.md` — both retired to core canon per
  `docs/issue-2/proposals/2026-07-31-core-canon-reference-switch.md`.
- `localization/hooks/hooks.json` — registers only `SessionStart` →
  `directive.sh`. Core canon (`tokenmaxxxer-core` repo, not vendored here)
  supplies `record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` globally via its own `hooks.json`
  (`matcher: ".*"`), so this rulebook does not need its own copies.
- `docs/specs/approvers.md` — single approver (`JiwonJung94`), so this
  role runs in single-account mode: phase 2 opens via the exact issue
  comment `APPROVE issue-1/localization`.
- No `docs/issue-1/*` content exists yet (this issue's own tree is being
  created now). No prior localization-specific proposal or record.
- `RECORD_FIELDS_TERMINAL_STATES` is unset for this rulebook — core
  default `landed` applies; no rulebook-specific terminal `loop_state`
  documented anywhere in this repo.

## What §20 / record-fields-gate.sh already force on the phase-2 record

Read from `core/hooks/record-fields-gate.sh` (tokenmaxxxer-core repo,
checked out locally at `~/tokenmaxxxer/tokenmaxxxer-core`): any write to
`docs/issue-<n>/reports/localization.md` is rejected unless the content
contains, in some recognizable form: a "what was done" section, a "why"
section, an upstream basis (commit hash / `docs/issue-` reference /
"based on"), a `loop_state:` line, and an "open findings" section — plus
a next-steps section when `loop_state` is non-terminal. This is a floor
already enforced mechanically; the proposal below must not weaken it,
only decide what *additional*, domain-specific structure sits on top.

## Gaps this proposal must aim at (this is what scouting should test)

1. **No decision method for the phase-1 proposal document itself.** The
   directive gives no norm for how a locale-fitness *proposal* should be
   argued (evidence format, adoption rationale shape) — issue-1 asks for
   exactly this.
2. **No decision method for the phase-2 deliverable.** "locale-fitness
   verdict per target locale, string-external issue list" is stated as
   an output shape (from the directive) but not as a *methodology* —
   nothing says how the verdict is produced, on what basis a target
   locale passes/fails, or what "string-external issue" categories
   exist.
3. **No plugin-level enforcement of either.** The only gate this role's
   hooks.json wires locally is the core §20 record-fields floor; there
   is no domain check (e.g., "did the proposal cite an adoption
   rationale", "did the record enumerate per-locale verdicts") — a
   gap the issue explicitly asks to close via directive/record-field/
   gate additions.

Scouting (next: `scout-brief.md`) should therefore look for established,
citable localization QA / L10n project methodologies whose structure can
plug into these three gaps without duplicating the core §20 floor.
