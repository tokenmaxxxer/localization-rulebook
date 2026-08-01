# issue-10 scout brief

Stage count: 1 (sweep only) — mode: single-session sequential (no parallel
subagent/tool-call fan-out was dispatched; batched-sequential fallback,
stated explicitly per protocol). Reason for 1 stage: the survey (above)
already located a single authoritative exemplar the issue itself names as
the mandatory reference (core issue #72's gate-lib), so the sweep's only
job was confirming that exemplar's actual shape and checking whether any
sibling rulebook has already migrated to it (a stronger, closer-to-segment
exemplar would beat core's own doc). JUDGE POINT 1 found no such sibling
migration exists yet (`gh search code "gate-lib.sh" --owner tokenmaxxxer`
returned zero hits) — core's own canon is the only landed exemplar, so no
deepening round could add new decision-relevant signal. Saturation reached
after stage 1; stopped rather than spending the remaining budget on a
round with nothing left to find.

## Must-bes (from the exemplar: `tokenmaxxxer-core` gate-house-standard)

- A gate migrating to the standard must call `gate_trap_fail_closed` as
  its literal first statement, before `set -uo pipefail`.
- Kill switches must route through `gate_kill_switch_active`, never a
  hand-rolled case statement.
- `Edit`/`MultiEdit` reconstruction must honor each edit's own
  `replace_all` flag via `gate_reconstruct_write`, not `.replace(o, n, 1)`.
- Malformed JSON must deny via `gate_parse_json_or_deny`.
- The exemplar's own mandatory test harness fixes 6 case groups as
  non-negotiable (`run-gate-lib-tests.sh`'s list) — a rulebook adapting the
  standard is expected to run an adapted copy of the same 6, not a subset.
- `compliance-check.sh` is the sanctioned self-audit: run it against this
  role's `hooks/` before and after migration and cite the diff as
  evidence, rather than asserting compliance by narrative.

## Performance axes the exemplar competes on

1. **Fail-closed completeness** — every one of the 6 case groups green,
   not just the ones a given gate happened to already handle.
2. **Reference discipline** — sourced, never vendored (a rulebook that
   copies `gate-lib.sh`'s body inline would itself become a
   `compliance-check.sh`/`stub-check.sh` violation of the canon-scripts
   reference-not-copy rule).

## Adopt / skip

- **Adopt**: `gate_trap_fail_closed`, `gate_kill_switch_active`,
  `gate_deny`/`gate_allow`, `gate_parse_json_or_deny`,
  `gate_normalize_path`, `gate_reconstruct_write`, `gate_bash_write_targets`
  — all 7, across all 4 of this role's gate scripts. Also adopt running
  `compliance-check.sh` against `localization/` as the pre/post migration
  evidence gate.
- **Skip**: writing a role-specific variant of `gate-lib.sh` itself, or
  copying its body — the standard's entire point is one shared library;
  a role-local fork would recreate the exact drift problem issue #72 was
  raised to kill. Also skip inventing a 7th shared-lib function for the
  semantic upgrades below (locale-declaration parsing, verdict-less-locale
  cross-check, heading-structure section check) — those are this role's
  own methodology semantics, not generic gate-house plumbing, and belong
  in this role's gate scripts, not in core's shared library.

## Segment fit

This role's write surface (`docs/issue-<n>/reports/localization.md`,
`docs/issue-<n>/proposals/*localization*.md`) is a narrow, already-known
target set — the exemplar's generic path-normalization/reconstruction
machinery transfers directly with no adaptation needed beyond wiring the
existing per-file `RECORD_RE`/`TARGET_RE` patterns through
`gate_normalize_path` instead of the hand-rolled `resolve()`.

## Gap line

Current state already meets: MQM same-line/next-line adjacency (Finding
3) — no change needed there. Current state is missing every other
must-be listed above: no real trap, hand-rolled kill switches, no
`replace_all` handling, no `NotebookEdit` support, no malformed-JSON
centralization, no Bash-write coverage, and (role-specific, not from the
shared-lib gap) no verdict-less-locale check and two substring-only
semantic checks (base locale/MQM check, proposal 4-section check).

## Sources

- https://github.com/tokenmaxxxer/tokenmaxxxer-core (`main`, cloned
  read-only): `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`,
  `docs/handbooks/gate-house-standard.md`,
  `core/hooks/tests/run-gate-lib-tests.sh`,
  `core/hooks/tests/compliance-check.sh`.
- `gh search code "gate-lib.sh" --owner tokenmaxxxer` (2026-08-01, this
  session): 0 results — no sibling rulebook has migrated yet.
