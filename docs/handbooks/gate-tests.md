# Running the gate test suite

`tests/run-gate-tests.sh` is the repo-root runner for all PreToolUse gate
tests. All 4 gates it exercises (base `record-fields-localization-gate.sh`
plus the 3 issue-7 plugin gates) source core issue #72's
`core/hooks/lib/gate-lib.sh`/`gate-lib.py` — with the mandatory `||` guard
on the source line (core issue #75: an unguarded source is fail-open when
core is unreachable) — so the runner needs a `tokenmaxxxer-core` checkout
to resolve against. Run it from the repo root:

```
CORE_REF_DIR=/path/to/tokenmaxxxer-core/core bash tests/run-gate-tests.sh
```

(`CORE_REF_DIR` defaults to `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core`;
override it if the core checkout lives elsewhere. The runner exits 2
immediately if `$CORE_REF_DIR/hooks/lib` is missing.)

It builds a tempdir git-init'd sandbox, sources each plugin's
`tests/cases.sh` (`localization/plugins/*/tests/cases.sh`), and runs every
case as a real subprocess against the target gate script with a JSON
tool-call payload on stdin, asserting the gate's exit code (0 = allow,
2 = deny). It also runs the base `localization` plugin's
`record-fields-localization-gate.sh` semantic cases directly (no
`cases.sh` file for base — cases are inline in the runner).

For all 4 gates, the runner additionally calls
`mandatory_group_cases <prefix> <gate> <off-var> <target> <passing-content> [deny-content]`,
which runs the gate-house standard's 7 mandatory case groups (`Edit`
`replace_all`, mixed-`replace_all` `MultiEdit`, malformed JSON x3,
kill-switch-unrecognized-value, absolute/`./`-prefixed path parity,
`Bash`-tool write to the same target, and missing-core — a nonexistent
`CLAUDE_PLUGIN_ROOT_CORE` with no valid relative fallback, must deny)
against that one gate.

Exit status is non-zero if any case fails; the summary line
(`gate tests: N passed, M failed`) is printed last.

## Adding a new gate or case

- New plugin gate: add a `tests/cases.sh` under
  `localization/plugins/<name>/tests/`, exposing a `<name>_cases()`
  function that calls `run <label> <expected-exit> <gate-path> <payload>`
  (helpers `run`, `mk_write_payload`, `mk_edit_payload`,
  `mk_multiedit_payload`, `mk_bash_payload` are supplied by the runner —
  do not redefine them in `cases.sh`). Source and call the function from
  `tests/run-gate-tests.sh`, and add a `mandatory_group_cases` call for
  the new gate so it gets the 7 mandatory groups too.
- New case for an existing gate: add another `run ...` line inside that
  plugin's `*_cases()` function, or (for the base gate) directly in
  `tests/run-gate-tests.sh`.
