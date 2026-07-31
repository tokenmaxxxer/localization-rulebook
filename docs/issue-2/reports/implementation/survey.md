# issue-2 survey — current state vs. core canon

Scope: this rulebook's own `localization/` plugin tree (5 files named in the
issue) vs. `tokenmaxxxer/tokenmaxxxer-core` (issue-63 `warrant/`, issue-66
`core/hooks/` + `core/hooks/lib/role-directive.sh`), read live from GitHub
(`gh api` / raw.githubusercontent.com) since no local clone exists.

Scouting note: this is a rulebook-conformity task, not a product build — the
"field" to scout is the core canon itself, which the survey below reads
directly rather than via a separate sweep/brief. No product-shaped
exemplars apply; skip condition: task is a direct spec-conformance diff
against one named upstream, not an open design choice.

## 1. `localization/agents/warrant-hunter.md` (task 1)

Local copy is a role-specialized adaptation: fixed mandate text
("다른 로케일에서도 산출물이 성립하는가"), skeleton note to "enumerate this
role's own stance set before shipping."

Core canon (`warrant/agents/warrant-hunter.md`, part of the `warrant`
plugin, promoted per core issue-63) is **role-blind by design**: stance is
supplied per-dispatch by the warrant hooks (`hunt-guard.sh`/`hunt-state.sh`),
not baked into the agent file. It also carries machinery the local copy
never had: size-proportional wall-clock budget tiers, 3-consecutive-miss
tier step-down, mandatory hunt-record frontmatter
(`cap_seconds`/`tier`/`diff_stat_lines`/timestamps), and a hard "read code,
never `docs/decisions|specs|handbooks`" anchoring rule.

The whole `warrant` plugin (agent + `directive.sh`/`hooks.json`/
`hunt-guard.sh`/`hunt-state.sh`/`scope-gate.sh`/`state.sh`) is installed at
the orchestrator level (`claude plugin install warrant@tokenmaxxxer-core`,
per core's own README: "on-the-record enables them per role"), not vendored
into each rulebook. Nothing in `localization/` should re-implement any part
of it.

## 2. Role-agnostic gates: trailer / record-fields / handbook-trigger (task 2)

All three exist in `core/hooks/` today and are already registered
globally in `core/hooks/hooks.json` (`PreToolUse`, matcher `.*`):
`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`
(alongside `board-gate.sh`, `approval-gate.sh`, `gh-guard.sh`, which the
local rulebook never copied).

Diff from the local copies:

- **trailer-gate.sh** — core derives role/prefix from `CLAUDE_ROLE` at
  runtime (was hardcoded per-rulebook copy-paste, issue-66's "38/40 unique
  hashes" finding); adds multi-issue-in-one-commit refusal, `-F`/editor
  message detection, root-detection via `docs/specs/role-handoff-contract.md`
  fallback. Local copy is an early/simpler ancestor of the same logic.
- **record-fields-gate.sh** — **not a superset of the local file**, a
  replacement of its whole field model. Local checks role-specific
  `PRODUCES` fields (`locale-fitness-verdict`, `string-external-issue-list`)
  lifted from `roles/localization.json`. Core instead enforces contract
  §20's five generic fields (what-was-done / why / upstream-basis /
  `loop_state` / open-findings), plus a conditional next-steps +
  resolution-path pair when `loop_state` is non-terminal. Terminal-state set
  is configurable via `RECORD_FIELDS_TERMINAL_STATES` (task 4) — core
  documents this env var explicitly as "issue-66 found this file NOT pure
  role-token substitution."
- **handbook-trigger-gate.sh** — core has a real verdict (regex-matches
  dependency manifests / Dockerfiles / `.env*` / migrations / CI workflows /
  deploy scripts against the staged set, requires a `docs/handbooks/**`
  touch alongside). Local copy is `exit 0 # placeholder verdict — TODO`,
  i.e. currently a no-op. Removing it is a strict functional upgrade, not
  just de-duplication.

`core/hooks/hooks.json` already fires all three globally — `localization/hooks/hooks.json`'s
own registration of these three matchers is now redundant, and the
now-stronger core versions supersede correctness, not just line count.

## 3. `directive.sh` boilerplate (task 3)

`core/hooks/lib/role-directive.sh` factors the SessionStart preamble/
kill-switch/`CLAUDE_ROLE` guard/opening-closing lines into one sourceable
function, `core_role_directive(you_decide, use_when, produces, hand_off)`.
`core/hooks/tests/stub-check.sh` enforces the stub shape *structurally*: a
conforming `directive.sh` must (a) source `role-directive.sh`, (b) call
`core_role_directive`, and (c) contain **no other non-blank/non-comment
line** — no local `case`, no `trap`, no `cat <<EOF`, no raw echo. The local
`directive.sh` fails this check outright today: its trap/case/heredoc body
is exactly the regrown boilerplate the stub-check is built to catch.

Local's four directive values map cleanly onto the four
`core_role_directive` args:

| local field | value | -> arg |
|---|---|---|
| YOU DECIDE | `다른 로케일에서도 산출물이 성립하는가` | `you_decide` |
| USE_WHEN | `i18n 대상 표면이 걸릴 때` | `use_when` |
| PRODUCES | `locale-fitness verdict per target locale, string-external issue list` | `produces` |
| HAND-OFF | `카피 원문 자체를 다시 써야 하면 → content-design` | `hand_off` |

Two fields in the local directive have **no home in
`core_role_directive`'s signature**: `WRITE_SCOPE: []` and the `BOUNDARY
CASE` paragraph. Core's generic stub emits only the four args plus a fixed
closing `RECORD:` line — it does not template a write-scope or a
boundary-case block at all. These are role-unique content the stub cannot
carry structurally; the proposal below folds them into `produces`/`use_when`
prose or drops them if redundant with the (empty) `WRITE_SCOPE`, since an
empty scope conveys nothing gate-relevant here (role-agnostic gates already
own scope enforcement via `board-gate.sh`, not this rulebook's `directive.sh`).

## 4. Role-unique terminal states (task 4)

`RECORD_FIELDS_TERMINAL_STATES` (space-separated `loop_state` values,
default `landed`) is core's documented seam for exactly this: "a
proposal-shaped role may treat `scope-proposed` as its own terminal state
... configuration injected via `RECORD_FIELDS_TERMINAL_STATES` ... rather
than silently collapsed to one hardcoded set."

The local rulebook currently has **no** `loop_state` vocabulary documented
anywhere (`roles/localization.json` does not exist in this tree; only
`plugin.json`, `directive.sh`, and the three gate scripts do), so there is
no evidenced local terminal state to preserve beyond the core default
(`landed`). Nothing in the five files under review states a role-specific
terminal `loop_state`. Flagged as an open question in the proposal rather
than guessed.

## 5. `core/hooks/tests/stub-check.sh` (task 5)

Present in core (`core/hooks/tests/stub-check.sh`), distributed "the way
`parse-check.sh` already is" per its own header — i.e. each rulebook is
expected to vendor stub-check.sh itself (or reference it) and run it
against its own `hooks/` tree. Today `localization/hooks/` contains no test
harness at all (`find` shows no `tests/` subdir). Running it now (pre-fix)
would fail on all three CANON_GATES filenames still vendored plus the
non-stub `directive.sh`.

## Write surfaces touched by this issue

`localization/agents/warrant-hunter.md` (delete),
`localization/hooks/hooks.json` (edit: drop 3 gate matchers + trailer
matcher line dupe),
`localization/hooks/trailer-gate.sh`,
`localization/hooks/record-fields-gate.sh`,
`localization/hooks/handbook-trigger-gate.sh` (delete all three),
`localization/hooks/directive.sh` (rewrite to stub form).

No `src/`/`test/` surface — this issue is entirely `localization/` plugin
config, which per contract v3 sits outside the standard `docs/`
layout rule (plugin source, not board content) and is not gated by
`approval-gate.sh`'s execution-surface definition the way `src/`/`test/`
would be. Confirmed against core's own board-gate description: the
execution surface is `src/`, `test/`, and the issue tree outside the two
phase-1 homes — `localization/` is plugin source, same bucket code lives in
for this repo's purpose (a rulebook whose product *is* the plugin), and
Phase 2 will still touch it only after Approve.

loop_state: scope-proposed

## Open findings

- No local `loop_state` vocabulary is documented for the `localization`
  role beyond the core default `landed` — task 4's
  `RECORD_FIELDS_TERMINAL_STATES` may end up unnecessary (core default
  suffices) unless a human confirms a role-specific terminal state exists.
  Resolution path: ask in the PR description; phase 2 sets the env var only
  if an approver confirms a divergent terminal state, otherwise phase 2
  omits it and relies on the core default.
