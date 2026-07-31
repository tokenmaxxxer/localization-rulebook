#!/usr/bin/env bash
# Test cases for localization-verdict-axis/hooks/verdict-axis-gate.sh.
# Sourced by the root tests/run-gate-tests.sh runner, which supplies run()
# and mk_write_payload().

verdict_axis_cases() {
  local gate="$PLUGIN_ROOT/verdict-axis/hooks/verdict-axis-gate.sh"

  local complete='loop_state: landed\n\n- ko-KR: checklist=pass, style=pass\n- ja-JP: checklist=N/A(no string resources), style=pass'
  local missing_reason='loop_state: landed\n\n- ko-KR: checklist=pass, style=pass\n- ja-JP: checklist=N/A, style=pass'
  local no_verdicts='loop_state: landed\n\nsome other content, no locale lines'
  local nonterminal='loop_state: exploring\n\nno verdicts yet'

  run "verdict-axis: allow (two-axis verdicts complete, N/A with reason)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$complete")"

  run "verdict-axis: deny (N/A verdict missing reason)" 2 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$missing_reason")"

  run "verdict-axis: deny (terminal record, no verdict line at all)" 2 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$no_verdicts")"

  run "verdict-axis: no-op (non-terminal loop_state)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$nonterminal")"
}
