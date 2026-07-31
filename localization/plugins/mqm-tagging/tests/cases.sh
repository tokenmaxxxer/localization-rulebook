#!/usr/bin/env bash
# Test cases for localization-mqm-tagging/hooks/mqm-tagging-gate.sh.
# Sourced by the root tests/run-gate-tests.sh runner, which supplies run()
# and mk_write_payload().

mqm_tagging_cases() {
  local gate="$PLUGIN_ROOT/mqm-tagging/hooks/mqm-tagging-gate.sh"

  local tagged='loop_state: landed\n\n- issue: hardcoded string in login form [Internationalization]\n- issue: date format mismatch (tag: Locale convention)'
  local untagged='loop_state: landed\n\n- issue: hardcoded string in login form\n- issue: date format mismatch (tag: Locale convention)'
  local no_issues='loop_state: landed\n\nno string-external issues found this round.'
  local nonterminal='loop_state: exploring\n\n- issue: hardcoded string in login form'

  run "mqm-tagging: allow (all issues tagged)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$tagged")"

  run "mqm-tagging: deny (one issue untagged)" 2 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$untagged")"

  run "mqm-tagging: allow (no issue items at all)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$no_issues")"

  run "mqm-tagging: no-op (non-terminal loop_state)" 0 "$gate" \
    "$(mk_write_payload "docs/issue-7/reports/localization.md" "$nonterminal")"
}
