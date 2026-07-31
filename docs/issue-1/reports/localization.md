# issue-1 implementation record (phase 2)

## what was done

Executed the approved proposal
(`docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md`) section
(d) exactly as planned:

1. `localization/hooks/directive.sh`: updated the `PRODUCES` value (single
   value only, structure and `core_role_directive` call form unchanged) to
   "locale-fitness verdict (checklist+style-guide basis) per target locale,
   MQM-tagged string-external issue list", reflecting the checklist+style-guide
   verdict methodology and MQM 8-dimension issue tagging adopted in the
   proposal.
2. New gate `localization/hooks/record-fields-localization-gate.sh`:
   PreToolUse (Write|Edit|MultiEdit) check that fires only when the target is
   this role's own record (`docs/issue-<n>/reports/localization.md`) and the
   resulting `loop_state` is terminal (core default `landed`, unchanged —
   no role-specific terminal state was found in phase 1). On a terminal
   write it additionally requires a target-locale list and at least one MQM
   8-dimension tag string present. This is an addition on top of core's
   `record-fields-gate.sh` (§20 minimums), not a replacement, and is not a
   vendored copy of core's file — core canon is referenced only via
   `directive.sh`'s `core_role_directive` call.
3. Registered the new gate's `PreToolUse` hook in
   `localization/hooks/hooks.json` (matcher `.*`, single entry).
4. `RECORD_FIELDS_TERMINAL_STATES`: left unset, per the proposal — the core
   default (`landed`) is used, no role-specific terminal state was found.

## why

Per issue #1's phase 2 instruction: enforce the phase 1/phase 2 norms
approved in `docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md`
in this rulebook's plugin (directive + record fields + gates), derived from
MQM/ISO 17100 survey findings in
`docs/issue-1/reports/localization/survey.md` and
`docs/issue-1/reports/localization/scout-brief.md`. Canon scripts
(`role-directive.sh`) are referenced only, never copied, per issue-2's
already-landed core-canon-reference switch; the new gate is role-unique
logic with no home in core, so it is written fresh rather than vendored.

## upstream basis

`docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md` section
(d), approved via issue comment `APPROVE issue-1/localization` by
`JiwonJung94` (registered in `docs/specs/approvers.md`). Core's
`core/hooks/lib/role-directive.sh` call-form contract (single-line
`core_role_directive` call, per issue-2's `docs/issue-2/reports/implementation.md`)
preserved unchanged; only the `PRODUCES` value was edited.

Verification results:

- Step 4, missing-tag payload (`loop_state: landed`, no locale/MQM tag):
  `EXIT=2`, denied with message:
  "record-fields-localization-gate: refused — terminal localization record
  is missing required field(s): locale-list, mqm-tag. Per the approved
  norms proposal, a terminal-state record must show a target-locale list
  and tag every string-external issue with one of the MQM 8 top-level
  dimensions (Accuracy, Fluency, Terminology, Locale convention, Style,
  Verity, Design, Internationalization)."
- Step 4, passing payload (`loop_state: landed`, target-locale list present,
  one issue tagged `[Terminology]`): `EXIT=0` (allowed).
- Step 5, `directive.sh` run against core's real
  `core/hooks/lib/role-directive.sh`, output PRODUCES line:
  "PRODUCES: locale-fitness verdict (checklist+style-guide basis) per
  target locale, MQM-tagged string-external issue list" — matches the
  edited value exactly.

loop_state: landed

## open findings

None — plugin reflection plan executed as approved with no deviation.
