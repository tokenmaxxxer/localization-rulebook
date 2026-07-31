---
status: draft
issue: issue-7
mode: batched-sequential direct reads of the two exemplars named by the issue itself (implementation-rulebook, pricing-rulebook), local checkouts under /home/jwjung/tokenmaxxxer/rulebooks/ — parallel subagent dispatch skipped because this is a 1-round exhaustive read of two small, already-identified plugin trees, not open-ended search; falling back to sequential per the sweep-mode disclosure rule. 4 angles, 1 stage, saturated (a second pass would not change which files are the reference).
---

# Scout brief: plugin enforcement machinery, comparable rulebooks

## Angles run

1. Cross-role blocking gate shape — `implementation-rulebook/coding/hooks/coding-progress-gate.sh`
2. Dispatch/order state tracking — `implementation-rulebook/coding/hooks/hunt-guard.sh` + `hunt-state.sh`
3. Dual-surface (proposal + record) domain methodology gate — `pricing-rulebook/pricing/hooks/methodology-gate.sh`
4. Repo-committed gate test harness — `implementation-rulebook/tests/run-gate-tests.sh`

## Must-bes (what the exemplars all assume)

- Every gate installs a **fail-closed trap-at-top** (`trap __fc EXIT` that
  remaps any non-0/non-2 exit to 2) as its first executable statement,
  before any `set`/`source` — a PreToolUse hook treats non-2 exit as
  fail-OPEN, so anything else is a silent bypass. Present in
  `coding-progress-gate.sh`, `hunt-guard.sh`.
- Every gate resolves its own project root independently
  (`CLAUDE_PROJECT_DIR` if plausible, else `git rev-parse
  --show-toplevel`, else deny) rather than trusting a passed-in path —
  same helper block, copy-pasted across `record-fields-localization-gate.sh`
  and `pricing/hooks/methodology-gate.sh` (both already in this family).
- A role-specific gate is explicitly framed in its own header comment as
  **additive on top of core, never a replacement** — `pricing/hooks/
  methodology-gate.sh`'s header and `coding-progress-gate.sh`'s header
  both say this in nearly identical words.
- A domain methodology gate checks **both** write surfaces the domain's
  norms proposal actually defined requirements for — pricing's gate
  matches `docs/issue-<n>/proposals/*pricing*.md` (regex on filename)
  *and* `docs/issue-<n>/reports/pricing.md`, deriving its required-element
  list straight from that role's own adopted-norms proposal section
  numbers (cited by path in the gate's header comment).
- A state machine for an order/count constraint lives in **two files**:
  a guard (reads state, denies) and a state-writer (SessionStart/
  SubagentStop hooks that reset/release) — never a single file doing
  both, because the guard must stay a pure PreToolUse read+deny and the
  reset must fire on lifecycle events the guard is never invoked on.
- A gate test harness runs the **gate as a real subprocess** against a
  throwaway `git init` tempdir with fabricated tool-call JSON on stdin,
  asserting exit code 0 (allow) vs 2 (deny) — never a mocked/stubbed
  gate function. `run-gate-tests.sh`'s `run()`/`progress()`/`trailergate()`
  helpers are three thin wrappers around this one shape.

## Performance axes

1. **Fail-closed completeness** — does every malformed-input branch deny
   rather than silently allow (pricing's gate denies on unparseable JSON,
   missing tool_input, unresolvable content — never falls through).
2. **Surface precision** — does the gate fire only on its own role's
   write surfaces (regex-anchored path match) and no-op instantly on
   everything else, so it never becomes a hidden global slowdown.
3. **Grounding the required-element list in the adopted-norms document**
   — pricing's gate comment cites `docs/issue-1/proposals/methodology-
   norms.md (a)/(b)` element-by-element; nothing in the check list is
   invented at gate-write time.

## Adopt / skip

- **Adopt**: fail-closed trap-at-top, independent root resolution,
  "additive not replacement" framing, dual-surface (proposal+record)
  regex matching, subprocess-based gate tests with tempdir git repos.
- **Adopt, scaled down**: hunt-guard/hunt-state's two-file state-machine
  *shape* is noted but not instantiated — see the survey's order-
  constraint question; localization's methodology has no cross-call
  order today, so building a lock/counter pair here would be enforcement
  machinery with nothing to enforce. If a future norms revision adds a
  real sequence (e.g., a required checklist-pass-before-tag-pass split
  across separate tool calls), this pattern is the one to reach for then.
- **Skip**: coding-progress-gate.sh's cross-role finding lookup (verify.md
  → coding.md) — localization has no analogous "another role blocks my
  commit" relationship defined anywhere in this repo's contract; nothing
  to model it on.

## Gap line (what current state already meets vs. what's missing)

- Already met: fail-closed shape and root-resolution helper — the
  existing `record-fields-localization-gate.sh` already copies this
  correctly from the same family (issue-1 wrote it against the same
  pattern).
- Missing: proposal-surface check (gate only touches
  `reports/localization.md`, never `proposals/*localization*.md`);
  per-issue-tagged verification (current check is bag-of-words presence,
  not "every issue entry carries a tag"); N/A-rule and locale-verdict
  enumeration checks (issue-1 (b) requires them, nothing checks them);
  any committed test file (nothing in this repo tests the one gate that
  exists); any directive content beyond one line per facet.

## Sources

- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-guard.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-state.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`
- `docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md` (this
  repo's own adopted norms — the source the new gate's checks must trace
  to, per the must-be above)
