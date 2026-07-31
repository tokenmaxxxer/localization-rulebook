#!/usr/bin/env bash
# SessionStart directive for localization-verdict-axis.
# Kill switch: export LOCALIZATION_VERDICT_AXIS_DIRECTIVE_OFF=1
set -uo pipefail

case "${LOCALIZATION_VERDICT_AXIS_DIRECTIVE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "${CLAUDE_ROLE:-}" = "localization" ] || exit 0

cat <<'EOF'
[localization-verdict-axis] issue-1 (b)-1 두 축 판정 방법론
(ISO 17100/LSO 축소 채용):

JUDGE — 대상 locale마다 두 축을 각각 판정한다:
  (i) 체크리스트 축 — 문자열 외부화 / 인코딩 / plural 규칙 / 키 완전성.
      코드·문자열 리소스가 대상이 아니면 N/A(해당 없음 사유를 명시).
  (ii) 스타일가이드·로케일 관례 축 — 대상 로케일의 표기 관례·스타일가이드
      부합 여부.

FORBIDS: 유창성(fluency) 재작성 — 카피 원문 자체를 다시 쓰는 일은 이
방법론의 범위 밖이며 content-design 핸드오프 영역이다. 이 축의 판정은
"원문을 그대로 두고 로케일에 맞는가"만 본다.

체크리스트: ${CLAUDE_PLUGIN_ROOT}/checklists/locale-fitness-checklist.md

RECORD 요구: docs/issue-<n>/reports/localization.md의 terminal 쓰기는
locale별로 두 축 verdict를 모두 갖거나, verdict가 없는 locale에 대해
그 사유(N/A 등)를 명시해야 한다 — PreToolUse 게이트
(verdict-axis-gate.sh)가 이를 검사한다.
EOF
