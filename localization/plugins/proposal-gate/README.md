# localization-proposal-gate

담당 방법론(단일): issue-1 (a) — phase-1 제안서 구조 규범.

`docs/issue-<n>/proposals/*localization*.md`에 대한 Write/Edit/MultiEdit는
결과 콘텐츠가 4필수 섹션(조사 근거 / 채택 항목 / 논리적 근거 / 반영 계획)을
모두 포함할 때만 통과한다. base `localization` 플러그인 옆에 추가되는
플러그인이며, `core_role_directive` 4-인자 호출부는 건드리지 않는다
(issue-2 §3 동결 유지).

## 구성

- `hooks/directive.sh` — SessionStart, 4섹션 요구 + 인용 요구 + 생략-근거
  판단 기준을 출력.
- `hooks/methodology-gate.sh` — PreToolUse, 대상 경로에 대해 4섹션 존재를
  검사, 하나라도 없으면 거부(fail-closed).
- `tests/cases.sh` — 루트 `tests/run-gate-tests.sh`가 실행하는 allow/deny/
  no-op 케이스.

## Kill switch

- `LOCALIZATION_PROPOSAL_GATE_DIRECTIVE_OFF=1` — directive 출력만 끈다.
- `LOCALIZATION_PROPOSAL_GATE_OFF=1` — 게이트 검사를 끈다(fail-open으로
  전환하므로 디버깅 용도로만 사용).

## 참조

pricing-rulebook `methodology-gate.sh`의 구조(trap-at-top, 독립 root 해석,
Write/Edit/MultiEdit 콘텐츠 재구성, fail-closed)를 참조했다 — 코드를
복사하지 않고 이 표면에 맞춰 새로 작성했다.
