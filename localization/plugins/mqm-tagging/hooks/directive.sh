#!/usr/bin/env bash
# SessionStart directive for localization-mqm-tagging.
# Kill switch: export LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF=1
set -uo pipefail

case "${LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "${CLAUDE_ROLE:-}" = "localization" ] || exit 0

cat <<'EOF'
[localization-mqm-tagging] issue-1 (b)-2 MQM 8-dimension 축소 채용 분류:

REQUIRES: docs/issue-<n>/reports/localization.md의 terminal 쓰기에서
string-external 문제로 지목한 각 항목은 아래 8대 카테고리 중 하나로
태깅되어야 한다(태그는 해당 불릿/항목에 인접 — 문서 전체 아무 곳이
아니다):
  Accuracy / Fluency / Terminology / Locale convention / Style /
  Verity / Design / Internationalization

SCOPE 한정: MQM의 100+ 세부 issue type 체계는 채택하지 않는다 — 위 8개
top-level 카테고리까지만 채택 범위다. 세부 하위분류를 요구하지 않는다.
EOF
