# localization-verdict-axis

담당 방법론(단일): issue-1 (b)-1 — 두 축 판정 방법론(ISO 17100/LSO 축소
채용). phase-2 규범의 절반을 이루며, `localization-mqm-tagging`과 같은
표면(`docs/issue-<n>/reports/localization.md` terminal write)에 각자
독립적으로 PreToolUse 훅을 걸어 AND 합성을 이룬다(어느 한쪽이 상대의
존재를 몰라도 성립).

## 구성

- `hooks/directive.sh` — SessionStart, 두 축 판단 기준 + 유창성 재작성
  금지(content-design 핸드오프) + N/A 규칙 + 체크리스트 경로 출력.
- `hooks/verdict-axis-gate.sh` — PreToolUse, terminal 레코드에서 locale별
  `checklist=/style=` 두 축 verdict 존재 + N/A 사유 존재를 검사.
- `checklists/locale-fitness-checklist.md` — 체크리스트 축의 4개 기계적
  항목 + N/A 규칙.
- `tests/cases.sh` — 루트 `tests/run-gate-tests.sh`가 실행하는 allow/deny/
  N/A/no-op 케이스.

## Kill switch

- `LOCALIZATION_VERDICT_AXIS_DIRECTIVE_OFF=1` — directive 출력만 끈다.
- `LOCALIZATION_VERDICT_AXIS_GATE_OFF=1` — 게이트 검사를 끈다(fail-open,
  디버깅 용도).

## 참조

pricing-rulebook `methodology-gate.sh`의 구조를 참조했다 — 코드를
복사하지 않고 이 표면(locale verdict 파싱)에 맞춰 새로 작성했다. 기존
base `record-fields-localization-gate.sh`의 locale-관련 절반(단순
"locale" 단어 존재 확인)을 이 플러그인이 정밀화해 이어받는다 — base
게이트는 그대로 남아 중복 방어로 동작한다(fail-closed 원칙상 중복
deny는 안전 쪽으로만 작동).
