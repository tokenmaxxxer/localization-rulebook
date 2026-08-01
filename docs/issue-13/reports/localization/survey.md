# issue-13 phase-1 survey: gate-house A+ final closure (re-audit gaps)

Subject: issue-13, role: localization. This survey establishes the current
state of this role's plugin artifacts against the two landed preconditions
named in the issue body — core #75 and on-the-record #182 — and against
the issue's 4 requirements (all-remaining-defects fix, matcher-code
alignment, missing-core case coverage, README/manifest cleanup).

## Precondition check: both preconditions are landed

- **core #75** (`gate-lib` source-guard mandate + `gate_bash_write_targets`
  py parity + missing-core mandatory test): issue #75 is CLOSED, PR #76
  (propose) and PR #77 (deliver) both MERGED into `tokenmaxxxer-core`
  main, confirmed via `gh pr list -R tokenmaxxxer/tokenmaxxxer-core`.
  `core/hooks/lib/gate-lib.sh` (fetched via `gh api
  repos/tokenmaxxxer/tokenmaxxxer-core/contents/core/hooks/lib/gate-lib.sh`)
  now documents the mandatory guarded source line in its usage comment:
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo
  "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`.
  `core/hooks/lib/gate-lib.py:159-171` now defines
  `gate_bash_write_targets(command)` as a python mirror of the sh version.
  `docs/handbooks/gate-house-standard.md:60-90` documents the 7-group
  mandatory test harness (`run-gate-lib-tests.sh`), where group 7
  (line 84-86) is new: "`gate-lib.sh` sourced with
  `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no valid
  relative fallback — must assert **deny** (exit 2)". The same handbook's
  Compliance detector section (line ~91-104) states `compliance-check.sh`
  now also "flags a gate that sources `gate-lib.sh` with no `||` guard on
  the same line (issue-75: fail-open on missing core)".
- **on-the-record #182** (`CLAUDE_PLUGIN_ROOT_CORE` injection): PR #183
  (propose) and PR #185 (deliver) both MERGED into `on-the-record` main.
  `spawn.py`'s `spawn_cmd()` sets `env["CLAUDE_PLUGIN_ROOT_CORE"] =
  str(core_dir)` when a `core` plugin directory is present in
  `core_plugins`, confirmed via `WebFetch` on
  `raw.githubusercontent.com/tokenmaxxxer/on-the-record/main/spawn.py`.

## Finding 1 (critical): unguarded `gate-lib.sh` source in all 4 gates —
exactly the issue-75-confirmed fail-open defect

None of this role's 4 gate scripts carry the mandatory `||` guard on their
`gate-lib.sh` source line — each is a bare `. "$path"` with no fallback,
so a `command not found` (exit 127) from a failed/missing source is
misread by the very next `gate_kill_switch_active ... || { exit 0; }` call
as "kill switch off," silently allowing everything through, per
`gate-house-standard.md`'s own description of the bug this repo has not
yet applied the fix for:

- `localization/hooks/record-fields-localization-gate.sh:36`:
  `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` (no `||` guard)
- `localization/plugins/proposal-gate/hooks/methodology-gate.sh:20`:
  `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` (no `||` guard)
- `localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh:28`:
  `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` (no `||` guard)
- `localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh:23`:
  `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` (no `||` guard)

All 4 preceded by an identical `CORE_HOOKS_ROOT` assignment pattern, e.g.
`localization/hooks/record-fields-localization-gate.sh:35`:
`CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname
"${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"` — the
`CLAUDE_PLUGIN_ROOT_CORE`-first, relative-fallback shape is otherwise
correct and matches on-the-record #182's injected variable name; only the
source line itself lacks the guard. This directly matches the issue-13
body's "실측 fail-open 재현됨" (empirically reproduced fail-open) —
in a topology where core is unreachable and no relative fallback resolves
(e.g. a plugin install layout without a `../../core` sibling), all 4 gates
would silently allow every write instead of denying, in this exact repo,
today.

## Finding 2: missing-core mandatory test case (group 7) absent from the
test suite

`tests/run-gate-tests.sh`'s `mandatory_group_cases` function (lines
101-147) implements exactly 6 of the gate-house-standard's now-7 mandatory
groups: Edit `replace_all` (line 118-120), MultiEdit mixed `replace_all`
(122-124), malformed JSON x3 (126-129), kill-switch-unrecognized-value
(131-134), absolute/`./`-prefixed path parity (136-141), Bash-tool write
to same target (143-146). There is no case exercising group 7 — sourcing
`gate-lib.sh` with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path
and no valid relative fallback, asserting exit 2. Grep for
`CLAUDE_PLUGIN_ROOT_CORE`/`nonexistent`/`missing-core` across
`tests/run-gate-tests.sh` and all 3 plugins'
`localization/plugins/*/tests/cases.sh` returns 0 matches for a
missing-core scenario (the only `CLAUDE_PLUGIN_ROOT_CORE` reference is
`tests/run-gate-tests.sh:90`, which sets it to the *valid* core dir for
every other case). This is consistent with the fact that the guard itself
(Finding 1) does not exist yet: a missing-core test against the current
code would either hang on a real `command not found` or exercise the
pre-issue-75 silent-allow bug, not the intended deny path — the two
findings are the same gap, test and implementation halves.

## Finding 3: matcher-code alignment — no defect found

All 4 `hooks.json` files (`localization/hooks/hooks.json:10-17`,
`localization/plugins/proposal-gate/hooks/hooks.json:10-17`,
`localization/plugins/verdict-axis/hooks/hooks.json:10-17`,
`localization/plugins/mqm-tagging/hooks/hooks.json:10-17`) each declare a
single `PreToolUse` entry with `"matcher": ".*"` (all tools) pointing at
the one gate script that actually exists in that plugin's `hooks/`
directory (`record-fields-localization-gate.sh`, `methodology-gate.sh`,
`verdict-axis-gate.sh`, `mqm-tagging-gate.sh` respectively) — script names
in each `hooks.json` command line match the real filenames on disk exactly
(verified by `find localization/plugins -type f` + direct read of all 4
`hooks.json`). Each gate script's own internal `tool_name` branching
(`Write`/`Edit`/`MultiEdit` plus `Bash`, e.g.
`record-fields-localization-gate.sh:63-95`) is reachable given the `.*`
matcher — there is no advertised-but-unreachable branch, and no gate
script referenced by a matcher that does not exist. This axis of the
issue's requirement 2 is already satisfied; the requirement 2 gap that
does exist is Finding 1/2 above (the *source guard* and its *test*, not
matcher/tool coverage).

## Finding 4: README/manifest — no ghost files or stale role names found;
one staleness gap (compliance-check.sh evidence not re-run post-#75)

- `README.md:22-73`'s Layout section names exactly the files present on
  disk: `plugin.json`, `hooks.json`, `directive.sh`,
  `record-fields-localization-gate.sh` (line 25, confirmed present), and
  all 3 issue-7 plugin directories with their real gate script names
  (`methodology-gate.sh`, `verdict-axis-gate.sh`, `mqm-tagging-gate.sh`).
  No reference to the issue-10-era ghost files (`record-fields-gate.sh`,
  `trailer-gate.sh`, `handbook-trigger-gate.sh`, `agents/warrant-hunter.md`)
  remains — those were the issue-10 finding, already fixed in the
  `23fa5c4` delivery.
- `localization/.claude-plugin/plugin.json:2` declares `"name":
  "localization"` (current role name, not a pre-taxonomy alias); all 3
  plugin `.claude-plugin/plugin.json` files use current plugin names
  (`localization-proposal-gate`, `localization-verdict-axis`,
  `localization-mqm-tagging`, cross-checked against `README.md:35-51`'s
  own naming) — no stale 43-role-taxonomy name found anywhere searched.
- Gap: `README.md`/no report file cites a current `compliance-check.sh`
  run. `docs/issue-10/reports/localization.md:118-142` recorded a
  before/after `compliance-check.sh` run as of the issue-10 delivery, but
  that was against the *pre-issue-75* compliance detector, which did not
  yet check for the unguarded-source pattern (Finding 1). No
  `compliance-check.sh` run against the current, issue-75-updated
  detector exists in this repo's docs — so the record that once said
  "clean" no longer reflects what the detector now checks for, per
  `gate-house-standard.md`'s own migration-checklist step 4 ("Re-run
  `compliance-check.sh` clean").

## Scope note

The issue body's opening line ("공통(source 가드)만 — 실측 fail-open
재현됨; 그 외 최고 수준", i.e. "common [source guard] only — fail-open
empirically reproduced; otherwise top-grade") matches this survey's
findings precisely: Finding 1 (+ its test-half Finding 2) is the one
concrete, reproduced defect; Findings 3-4 confirm the other 3 requirement
axes (matcher alignment, README ghost files) are already clean, with one
staleness gap (re-running compliance-check.sh evidence) rather than a new
defect.
