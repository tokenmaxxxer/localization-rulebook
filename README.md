# localization-rulebook

Rulebook for the `localization` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 다른 로케일에서도 산출물이 성립하는가
- **use_when**: i18n 대상 표면이 걸릴 때
- **produces**: locale-fitness verdict per target locale, string-external issue list
- **write_scope**: []
- **hand-off**: 카피 원문 자체를 다시 써야 하면 → content-design

## Install

```
claude plugin marketplace add tokenmaxxxer/localization-rulebook
claude plugin install localization
```

## Layout

- `localization/.claude-plugin/plugin.json` — base plugin manifest
- `localization/hooks/hooks.json` — SessionStart + PreToolUse wiring
- `localization/hooks/directive.sh` — SessionStart role directive
- `localization/hooks/record-fields-localization-gate.sh` — this role's
  record required-field gate (target-locale + MQM-tag field presence on a
  terminal `docs/issue-<n>/reports/localization.md`).
  Kill switch: `RECORD_FIELDS_LOCALIZATION_GATE_OFF=1`.
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

3 issue-7 plugins, each an independent `.claude-plugin` under
`localization/plugins/`, composed additively (all 3 + the base gate run
on the same PreToolUse matcher; none knows about the others):

- `localization/plugins/proposal-gate/` (`localization-proposal-gate`) —
  `hooks/methodology-gate.sh` denies a `docs/issue-<n>/proposals/*localization*.md`
  write unless all 4 required sections (조사 근거 / 채택 항목 / 논리적 근거 /
  반영 계획) appear as markdown headings.
  Kill switch: `LOCALIZATION_PROPOSAL_GATE_OFF=1`.
- `localization/plugins/verdict-axis/` (`localization-verdict-axis`) —
  `hooks/verdict-axis-gate.sh` requires a two-axis
  (checklist/style-guide) verdict line per declared target locale on a
  terminal record, denying any declared locale with neither a verdict nor
  a `verdict-less locales:` exclusion entry.
  `checklists/locale-fitness-checklist.md` is the checklist-axis basis.
  Kill switch: `LOCALIZATION_VERDICT_AXIS_GATE_OFF=1`.
- `localization/plugins/mqm-tagging/` (`localization-mqm-tagging`) —
  `hooks/mqm-tagging-gate.sh` requires every `- issue:` bullet on a
  terminal record to carry an adjacent MQM 8-dimension tag
  (`[Dimension]` or `(tag: Dimension)`, same or next line).
  Kill switch: `LOCALIZATION_MQM_TAGGING_GATE_OFF=1`.

All 4 gates (base + 3 plugins) source `core/hooks/lib/gate-lib.sh` /
load `core/hooks/lib/gate-lib.py` (the gate-house standard, core issue
#72) for the fail-closed EXIT trap, kill-switch convention, JSON parsing,
path normalization, and `Write`/`Edit`/`MultiEdit` content reconstruction
— referenced only, never vendored. Each also matches a `Bash`-tool write
reaching the same target path (fail-closed denied, since a shell
command's resulting content cannot be reconstructed).

## Tests

`tests/run-gate-tests.sh` runs all 4 gates' allow/deny/no-op cases plus
the gate-house standard's 6 mandatory case groups (`Edit` `replace_all`,
mixed-`replace_all` `MultiEdit`, malformed JSON, kill-switch-unrecognized-
value, absolute/`./`-prefixed path parity, `Bash`-tool write) as real
subprocesses against a git-init'd sandbox. Requires a checked-out
`tokenmaxxxer-core` sibling (or `CORE_REF_DIR=/path/to/core` env override)
so the migrated gates can resolve `gate-lib.sh`/`gate-lib.py`.

This is a working rulebook (issue-1/issue-7/issue-10 landed): the plugin
set, gate-lib migration, and section/adjacency-anchored semantic checks
above are load-bearing, not scaffolding.
