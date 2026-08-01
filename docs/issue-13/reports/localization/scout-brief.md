# issue-13 phase-1 scout brief: gate-house A+ final closure

## Angle 1: this role's own prior gate-house remediation round (issue-10)

`docs/issue-10/proposals/2026-08-01-gate-house-aplus-remediation.md` and
its delivery record `docs/issue-10/reports/localization.md` (commits
f30e968/23fa5c4) are the direct structural precedent: same 4 gates, same
"reference core's shared lib, never re-derive" adoption logic, same
per-item citation-to-survey-finding discipline in 채택 항목, same
before/after `compliance-check.sh` evidence pattern. **Adopt**: the
survey→scout→proposal→(phase-2 record with before/after compliance-check
output) shape wholesale for issue-13 — it is this role's own established
format, not a borrowed one. **Adopt**: citing `gate-house-standard.md`'s
own migration-checklist steps as the rationale backbone, as issue-10's
proposal did.

## Angle 2: core's own canon fix (issue-75) as the sole implementation
source

`docs/handbooks/gate-house-standard.md`'s "Transition note (issue-75...)"
section is the canon description of exactly this defect and its fix
shape. **Adopt**: the guarded source-line form verbatim from
`gate-lib.sh`'s own usage comment (`. "${CLAUDE_PLUGIN_ROOT_CORE:-...}"
|| { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`) —
there is no design decision to make here; core prescribes the exact guard
shape and the issue-13 body itself says "core #75의 확정 가드/규칙을 참조
적용" (apply the fixed guard/rule from core #75 by reference). **Skip**:
inventing an alternative guard idiom — the whole point of the shared
library is one canonical shape across all 43 rulebooks.

## Angle 3: whether any other rulebook has already migrated to the
issue-75 guard (precedent search)

Searched for a landed sibling-rulebook migration to cite as a second
example beyond core's own handbook text. `gh api` calls against core and
on-the-record only surface the two named preconditions (#75, #182)
merged; no evidence of another rulebook's own issue-13-equivalent PR was
available to fetch cheaply from inside this session's sandboxed network
(only `github.com`/`*.github.com`/registries reachable, and enumerating
all 43 sibling rulebook repos for a landed PR was out of proportion to
what this angle needed). **Assumption (가정)**: no other rulebook has
landed this specific fix yet as of this survey (2026-08-01), so this
role's proposal treats `gate-house-standard.md`'s prescription itself,
not a sibling migration, as the primary and sufficient source — consistent
with issue-10's precedent, which also had "no sibling rulebook has
migrated yet" as an explicit scout finding at that time.

## Angle 4: whether the missing-core test case (Finding 2) needs its own
design decision

`gate-house-standard.md:84-86` fully specifies the group-7 test shape
(`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path, no valid
relative fallback, must assert deny). `tests/run-gate-tests.sh`'s existing
`mandatory_group_cases` helper (lines 101-147) already has an established
per-gate case-group pattern (`run "<label>" <expect> "$gate" <payload>
["$off_var=..."]`) that a group-7 case slots into directly, using `run`'s
existing extra-env-args mechanism to override `CLAUDE_PLUGIN_ROOT_CORE`
per-case instead of the helper's own default. **Adopt**: extend
`mandatory_group_cases` itself (not a bespoke one-off runner) so all 4
gates get the case uniformly, mirroring how groups 1-6 are already shared
across gates rather than duplicated per-gate.

## Sources

- `docs/issue-10/proposals/2026-08-01-gate-house-aplus-remediation.md`
- `docs/issue-10/reports/localization.md`
- `docs/handbooks/gate-house-standard.md` (fetched live via `gh api
  repos/tokenmaxxxer/tokenmaxxxer-core/contents/docs/handbooks/gate-house-standard.md`)
- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` (fetched live,
  same method)
- `gh issue view 75` / `gh pr list -R tokenmaxxxer/tokenmaxxxer-core
  --search 75` (issue-75 CLOSED, PR #76/#77 MERGED)
- `gh pr list -R tokenmaxxxer/on-the-record --search 182` (PR #183/#185
  MERGED); `spawn.py` fetched via `WebFetch` on
  `raw.githubusercontent.com/tokenmaxxxer/on-the-record/main/spawn.py`
- `tests/run-gate-tests.sh` (this repo)
