# issue-2 implementation record (phase 2)

## what was done

Executed the approved proposal
(`docs/issue-2/proposals/2026-07-31-core-canon-reference-switch.md`) exactly
as planned.

1. Deleted `localization/agents/warrant-hunter.md` — the `warrant` plugin
   (core issue-63) is installed at the orchestrator level and no longer
   supports a per-role stance file; the local copy had no separate hunt
   cadence text elsewhere in the repo.
2. Deleted `localization/hooks/trailer-gate.sh`,
   `localization/hooks/record-fields-gate.sh`,
   `localization/hooks/handbook-trigger-gate.sh` and removed their two
   `PreToolUse` matcher blocks from `localization/hooks/hooks.json`. Only
   the `SessionStart` (`directive.sh`) registration remains. Core's
   `core/hooks/hooks.json` already fires all three globally with matcher
   `.*`, superseding the deleted copies with stronger logic (notably
   `handbook-trigger-gate.sh`, whose local copy was an `exit 0` placeholder).
3. Rewrote `localization/hooks/directive.sh` to the stub form: sources
   `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
   the four role-unique values (YOU DECIDE / USE WHEN / PRODUCES /
   HAND-OFF), single-line call form (required by `stub-check.sh`'s
   structural line-classifier — a multi-line backslash-continued call
   reads each continuation line as non-stub content and fails). Dropped
   `WRITE_SCOPE: []` and the `BOUNDARY CASE` paragraph per the proposal's
   explicit decision (no home in `core_role_directive`'s 4-arg signature;
   empty scope/generic hand-off principle carry no gate-relevant
   information `board-gate.sh`/`approval-gate.sh` don't already own).
4. `RECORD_FIELDS_TERMINAL_STATES`: not set. Per the proposal and survey,
   no role-specific terminal `loop_state` is documented anywhere in this
   rulebook beyond core's default (`landed`); phase 2 relies on the core
   default as planned. Not raised in the Approve comment, so left unset.

## why

Core issue-63/issue-66 landed a single canon for the warrant-hunter stance
and the three role-agnostic gates plus the directive boilerplate; per this
repo's issue #2, vendored copies here are now drift, not customization, and
must be replaced with canon references.

## upstream basis

Core issue-63 (`warrant/` plugin), core issue-66 (`core/hooks/` global gate
registration + `core/hooks/lib/role-directive.sh` +
`core/hooks/tests/stub-check.sh`), read live from
`tokenmaxxxer/tokenmaxxxer-core@main` via `gh api` (no local core checkout
exists in this environment). Approved via issue comment
`APPROVE issue-2/implementation` by `JiwonJung94` (registered in
`docs/specs/approvers.md`, commit d419fd0 on `main`).

`stub-check.sh` result: **PASS**. `core/hooks/tests/stub-check.sh` is not
yet vendored into this rulebook (no local core checkout to copy it from at
execution time), so it was fetched from
`tokenmaxxxer/tokenmaxxxer-core@main` (`core/hooks/tests/stub-check.sh`)
and run against `localization/hooks`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under localization/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under localization/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under localization/hooks
stub-check: ok — no vendored 'parse-check.sh' under localization/hooks
stub-check: ok — localization/hooks/directive.sh is a role-directive stub
```

(`parse-check.sh` was never vendored into this rulebook — not applicable,
per the proposal's success criteria.)

Manual verification: ran `localization/hooks/directive.sh` with
`CLAUDE_ROLE=localization` (against a temporary local copy of
`core/hooks/lib/role-directive.sh`, removed after the check — not part of
this commit) and confirmed the SessionStart output reproduces all four
role-unique values (YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF) plus the
core-supplied `RECORD:` line unchanged.

loop_state: landed

## open findings

None — the one open question from phase 1 (role-specific terminal
`loop_state`) resolved by the Approve comment carrying no correction, so
the core default stands per the proposal's stated resolution path.
