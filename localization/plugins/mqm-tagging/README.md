# localization-mqm-tagging

담당 방법론(단일): issue-1 (b)-2 — MQM 8-dimension 축소 채용 분류.
phase-2 규범의 절반을 이루며, `localization-verdict-axis`와 같은 표면
(`docs/issue-<n>/reports/localization.md` terminal write)에 각자
독립적으로 PreToolUse 훅을 걸어 AND 합성을 이룬다.

## 구성

- `hooks/directive.sh` — SessionStart, 8대 카테고리 나열 + 100+ 세부
  미채택 범위 한정 출력.
- `hooks/mqm-tagging-gate.sh` — PreToolUse, terminal 레코드에서 각
  `- issue:` 항목 인접(같은 줄/다음 줄)에 8종 중 하나의 태그가 있는지
  검사.
- `tests/cases.sh` — 루트 `tests/run-gate-tests.sh`가 실행하는 allow/deny/
  no-op 케이스.

## Kill switch

- `LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF=1` — directive 출력만 끈다.
- `LOCALIZATION_MQM_TAGGING_GATE_OFF=1` — 게이트 검사를 끈다(fail-open,
  디버깅 용도).

## 참조

pricing-rulebook `methodology-gate.sh`의 구조를 참조했다 — 코드를
복사하지 않고 이 표면(이슈 항목 인접 태그 파싱)에 맞춰 새로 작성했다.
기존 base `record-fields-localization-gate.sh`의 MQM-관련 절반("문서
전체 아무 곳" 태그 존재 확인)을 이 플러그인이 정밀화(항목별 인접
검사)해 이어받는다 — base 게이트는 그대로 남아 중복 방어로 동작한다.
