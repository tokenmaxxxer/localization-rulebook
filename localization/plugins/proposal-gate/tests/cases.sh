#!/usr/bin/env bash
# Test cases for localization-proposal-gate/hooks/methodology-gate.sh.
# Sourced by the root tests/run-gate-tests.sh runner, which supplies run().
# Each function must call: run <name> <expect_exit> <gate_script> <json_payload>

proposal_gate_cases() {
  local gate="$PLUGIN_ROOT/proposal-gate/hooks/methodology-gate.sh"

  local complete='## 조사 근거\n\n내용\n\n## 채택 항목\n\n내용\n\n## 논리적 근거\n\n내용\n\n## 반영 계획\n\n내용'
  local missing='## 조사 근거\n\n내용\n\n## 채택 항목\n\n내용'
  local prose_only='이 제안은 조사 근거, 채택 항목, 논리적 근거, 반영 계획을 모두 언급하지만 헤딩은 하나도 없다.'

  run "proposal-gate: allow (4 sections complete)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/proposals/2026-07-31-x-localization.md" "$complete")"

  run "proposal-gate: deny (missing 논리적 근거/반영 계획 headings)" 2 "$gate" \
    "$(mk_write_payload "docs/issue-7/proposals/2026-07-31-x-localization.md" "$missing")"

  run "proposal-gate: deny (all 4 section names mentioned in prose, no headings)" 2 "$gate" \
    "$(mk_write_payload "docs/issue-7/proposals/2026-07-31-x-localization.md" "$prose_only")"

  run "proposal-gate: no-op (unrelated path)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$missing")"
}
