# issue-13 phase-2 record: gate-house A+ final closure

Subject: issue-13, role: localization.

loop_state: landed

## What was done

Per the approved phase-1 proposal
(`docs/issue-13/proposals/localization-gate-a-plus-final.md`, approved by
the `APPROVE issue-13/localization` issue comment): guarded the
`gate-lib.sh` source line in all 4 gates
(`record-fields-localization-gate.sh`, `methodology-gate.sh`,
`verdict-axis-gate.sh`, `mqm-tagging-gate.sh`) with core issue #75's
mandatory `||` guard, added the group-7 missing-core mandatory test case
to `tests/run-gate-tests.sh`'s `mandatory_group_cases` (applied uniformly
to all 4 gates via the shared helper), and re-ran `compliance-check.sh`
before/after as delivery evidence. No README/manifest edit and no
matcher change shipped — the phase-1 survey found both axes already
clean, and this round's execution confirmed that finding, not a defect.

## Why

The issue-13 body's one reproduced defect ("공통(source 가드)만 — 실측
fail-open 재현됨") is exactly core issue #75's confirmed shape: an
unguarded `. "$path"` source line runs no code — including no `gate_*`
function definition — when core is unreachable, and every
`gate_kill_switch_active ... || { exit 0; }` call site then reads the
resulting "command not found" (127) as the kill switch being off,
silently allowing everything through. This round's own deliverable is
infra/gate work, not a locale-facing translation artifact — no
locale-specific content was produced, recorded below as an explicit N/A
verdict rather than omitted.

## target locale

- xx: no locale-specific deliverable this round (gate/test/doc remediation only, see the N/A verdict below).

## MQM tags

No string-external issues were produced or reviewed this round; this
delivery does not touch any translated or locale-facing copy, so there is
nothing for the MQM-tagging gate's adjacency check to tag.

## 1. Source-guard fix (adopted item 1)

All 4 gates' `CORE_HOOKS_ROOT=...` source line now reads:

```
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

substituting each gate's own name, pulled verbatim from `gate-lib.sh`'s
own usage comment (`core/hooks/lib/gate-lib.sh:18`) — the reference-not-
copy form core issue #75 mandates, not a hand-rolled guard idiom.

## 2. Group-7 missing-core mandatory test case (adopted item 2)

`tests/run-gate-tests.sh`'s `mandatory_group_cases` now runs a 7th case
per gate (all 4 gates, via the shared helper — no per-gate duplication):
invokes the gate with `CLAUDE_PLUGIN_ROOT_CORE` pointed at
`$SANDBOX/no-such-core` (nonexistent, and since the env var is set —
even to a bad value — the gate's own `${CLAUDE_PLUGIN_ROOT_CORE:-...}`
relative fallback never triggers) and asserts exit 2, per
`gate-house-standard.md:84-86`'s exact case shape.

## 3. compliance-check.sh evidence (adopted item 3)

`core/hooks/tests/compliance-check.sh`, run against each gate's directory
before and after item 1's fix (before: `git stash` on this delivery's
uncommitted edit, reproducing the pre-fix commit's tree; after: the
delivered tree):

Before:

```
compliance-check: FAIL — localization/hooks/record-fields-localization-gate.sh:
  - sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)
compliance-check: FAIL — localization/plugins/proposal-gate/hooks/methodology-gate.sh: (same reason)
compliance-check: FAIL — localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh: (same reason)
compliance-check: FAIL — localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh: (same reason)
```

After (this delivery):

```
compliance-check: ok — localization/hooks/record-fields-localization-gate.sh
compliance-check: ok — localization/plugins/proposal-gate/hooks/methodology-gate.sh
compliance-check: ok — localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh
compliance-check: ok — localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh
```

## 4. Matcher/manifest/README audit (items 4-5, confirmed no-op)

- `hooks.json` matchers: all 4 files use `.*` and reference a gate
  script filename verified to exist on disk this round (`find localization
  -name hooks.json`, cross-checked against each referenced
  `${CLAUDE_PLUGIN_ROOT}/hooks/*.sh` path) — no matcher/code
  misalignment, confirming survey Finding 3.
- README/manifest: no stale role name or ghost file reference found in
  `README.md` or any `.claude-plugin/plugin.json` this round, confirming
  survey Finding 4 (already fixed in `23fa5c4`).

## 5. Full suite — delivery-state run

`bash tests/run-gate-tests.sh` (`CORE_REF_DIR` defaulting to the local
`tokenmaxxxer-core` checkout, all 4 gates x 10 mandatory-group cases
including the new group-7 missing-core case, plus role-specific semantic
cases):

```
gate tests: 59 passed, 0 failed
```

## Verdict

- xx: checklist=N/A(no locale-specific string content this round; gate/test/doc code only), style=N/A(no locale-facing copy was produced or reviewed this round)

## Open findings

None outstanding — the one reproduced defect (unguarded `gate-lib.sh`
source line) is fixed in all 4 gates, the group-7 missing-core case is
now covered across all 4 gates, `compliance-check.sh` is clean on all 4
(section 3), matcher/manifest/README are confirmed clean with no
remediation needed (section 4), and the full suite is green at 59/59
(section 5). This closes issue-13's requirements 1-4 in full.
