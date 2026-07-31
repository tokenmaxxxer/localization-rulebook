#!/usr/bin/env bash
# SessionStart directive for localization-proposal-gate — no core_role_directive
# call here (this plugin sits beside base `localization`, it does not own the
# role's identity block; base's SessionStart hook still fires separately).
# Kill switch: export LOCALIZATION_PROPOSAL_GATE_DIRECTIVE_OFF=1
set -uo pipefail

case "${LOCALIZATION_PROPOSAL_GATE_DIRECTIVE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "${CLAUDE_ROLE:-}" = "localization" ] || exit 0

cat <<'EOF'
[localization-proposal-gate] issue-1 (a) phase-1 제안서 구조 규범:

REQUIRES: docs/issue-<n>/proposals/*localization*.md 는 다음 4개 섹션을
모두 포함해야 한다 — 조사 근거 / 채택 항목 / 논리적 근거 / 반영 계획.
누락된 섹션이 하나라도 있으면 이 플러그인의 PreToolUse 게이트
(methodology-gate.sh)가 그 write 자체를 거부한다.

JUDGE: 각 채택 주장(채택 항목 섹션의 각 항목)은 조사 근거 섹션의 구체
관찰(survey.md/scout-brief.md 파일·행 또는 승인된 상위 proposal의 절)을
인용해야 한다 — 인용 없는 채택 주장은 "가정"으로 격하 표기하라
(단정하지 않는다).

FORBIDS: 조사를 생략하고 채택 항목만 나열하는 것. 조사를 생략했다면
그 생략 근거를 survey.md에 명시적으로 기록해야 하며, proposal 본문에서
"조사 없이 채택했다"는 사실을 숨기지 않는다.
EOF
