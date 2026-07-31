# Running the gate test suite

`tests/run-gate-tests.sh` is the repo-root runner for all PreToolUse gate
tests. Run it from the repo root:

```
bash tests/run-gate-tests.sh
```

It builds a tempdir git-init'd sandbox, sources each plugin's
`tests/cases.sh` (`localization/plugins/*/tests/cases.sh`), and runs every
case as a real subprocess against the target gate script with a JSON
tool-call payload on stdin, asserting the gate's exit code (0 = allow,
2 = deny). It also runs the base `localization` plugin's
`record-fields-localization-gate.sh` existence-check cases directly (no
`cases.sh` file for base — cases are inline in the runner).

Exit status is non-zero if any case fails; the summary line
(`gate tests: N passed, M failed`) is printed last.

## Adding a new gate or case

- New plugin gate: add a `tests/cases.sh` under
  `localization/plugins/<name>/tests/`, exposing a `<name>_cases()`
  function that calls `run <label> <expected-exit> <gate-path> <payload>`
  (helpers `run` and `mk_write_payload` are supplied by the runner — do
  not redefine them in `cases.sh`). Source and call the function from
  `tests/run-gate-tests.sh`.
- New case for an existing gate: add another `run ...` line inside that
  plugin's `*_cases()` function.
