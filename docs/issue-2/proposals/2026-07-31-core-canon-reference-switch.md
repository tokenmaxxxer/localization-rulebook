---
status: proposed
issue: issue-2
files:
  - localization/agents/warrant-hunter.md
  - localization/hooks/hooks.json
  - localization/hooks/trailer-gate.sh
  - localization/hooks/record-fields-gate.sh
  - localization/hooks/handbook-trigger-gate.sh
  - localization/hooks/directive.sh
---

# core canon 참조 전환 (core #63/#66 롤아웃)

## 요청 (원문)

> 1. warrant-hunter 복사본 제거 → core canon 참조로 교체
> 2. trailer/record-fields/handbook-trigger 게이트 복사본과 훅 등록 제거
> 3. directive.sh를 스텁 형식으로 교체 — 역할 고유부만 보존
> 4. 역할별 실차이 있으면 RECORD_FIELDS_TERMINAL_STATES로 명시 보존
> 5. stub-check.sh 통과 확인을 record에 기록

근거: `docs/issue-2/reports/implementation/survey.md` (core canon을
`gh api`/raw.githubusercontent.com으로 직접 읽어 로컬 5개 파일과 대조).

## 제약

- 순서 제약(이슈 본문): 이 전환이 이 레포 '룰북 성숙화' phase 2보다 먼저
  완료돼야 한다 — 이 PR은 phase 1(조사·제안)까지만, 실제 파일 변경은
  Approve 이후 phase 2에서.
- 역할 고유부(다른 로케일에서도 산출물이 성립하는가 / i18n 트리거 /
  locale-fitness produces / content-design 핸드오프)는 보존.

## 무엇을 할 것인가 (phase 2 실행 계획, 승인 후)

1. `localization/agents/warrant-hunter.md` 삭제. hunt cadence 관련 지시는
   이 레포 어디에도 별도로 없음(agents 파일 하나가 전부) — 파일 삭제로 충분.
   `warrant` 플러그인 자체는 오케스트레이터(on-the-record) 레벨에서
   `claude plugin install warrant@tokenmaxxxer-core`로 설치되며, 이 역할
   전용 stance는 core 쪽이 더 이상 지원하지 않음(core canon은 role-blind,
   dispatch마다 stance 주입) — 룰북 쪽에 대체 파일을 두지 않는다.
2. `localization/hooks/`에서 `trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh` 3개 파일 삭제. `localization/hooks/hooks.json`에서
   이 3개를 가리키는 `PreToolUse` 항목(현재 `record-fields-gate.sh` 1건,
   `handbook-trigger-gate.sh`+`trailer-gate.sh` 1건, 총 2개 매처 블록)
   제거 — `SessionStart`의 `directive.sh` 등록만 남긴다. core의
   `core/hooks/hooks.json`이 이미 이 3개를 `matcher: ".*"`로 전역
   등록하므로 중복 제거가 아니라 더 강한 검증(특히
   `handbook-trigger-gate.sh`는 로컬이 현재 `exit 0` 플레이스홀더 —
   core 버전은 실제 판정 로직)으로 교체되는 것.
3. `localization/hooks/directive.sh`를 stub-check.sh가 요구하는 구조로
   재작성:

   ```bash
   #!/usr/bin/env bash
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
   core_role_directive \
     "YOU DECIDE: 다른 로케일에서도 산출물이 성립하는가" \
     "USE WHEN: i18n 대상 표면이 걸릴 때" \
     "PRODUCES: locale-fitness verdict per target locale, string-external issue list" \
     "HAND-OFF: 카피 원문 자체를 다시 써야 하면 → content-design"
   ```

   `WRITE_SCOPE: []`와 `BOUNDARY CASE` 문단은 `core_role_directive`
   시그니처에 자리가 없다(core 스텁은 4개 인자 + 고정 `RECORD:` 줄만
   출력). 처리안: `WRITE_SCOPE: []`는 이 역할이 실제로 아무 파일도
   소유하지 않는다는 뜻이고, board-gate.sh/approval-gate.sh가 이미
   범위 집행을 담당하므로 stub 자체에는 넣지 않는다(정보 손실 없음 —
   비어있는 스코프는 게이트 동작에 아무것도 추가하지 않았음). `BOUNDARY
   CASE` 문단은 일반 원칙(핸드오프 화살표 밖으로 나가면 멈추고
   핸드오프)이라 core stub 헤더의 고정 문구와 사실상 중복 — 삭제.
   **열린 질문 아님, 실행 결정**: 두 필드 모두 정보 손실이 스텁 구조상
   불가피하고 기능적으로 무해하므로 phase 2에서 그대로 드롭한다. 이견
   있으면 Approve 코멘트에서 지적.
4. `RECORD_FIELDS_TERMINAL_STATES`: survey에서 확인된 대로 이 룰북에
   role-specific terminal `loop_state`가 문서화된 곳이 없음(core 기본값
   `landed` 하나뿐). **phase 2에서는 이 env var를 설정하지 않는다** —
   core 기본값을 그대로 쓴다. 사람 승인자가 다른 terminal state를
   알고 있다면 Approve 코멘트/리뷰에서 지적해 phase 2 전에 반영.
5. phase 2 완료 후 `core/hooks/tests/stub-check.sh`를
   `localization/hooks/`에 대해 실행(`bash core/hooks/tests/stub-check.sh
   localization/hooks`, 오케스트레이터의 core 체크아웃 경로 기준)하고
   결과(PASS/FAIL, 각 CANON_GATES 항목 + directive.sh 구조 체크 통과 여부)를
   `docs/issue-2/reports/implementation.md`에 기록.

## 성공 기준

- `localization/hooks/`에 `trailer-gate.sh`/`record-fields-gate.sh`/
  `handbook-trigger-gate.sh`/구버전 `directive.sh` 흔적 없음.
- `stub-check.sh localization/hooks` PASS (5개 검사 전부: 3개 CANON_GATES
  부재 확인 + directive.sh 구조 확인 — `parse-check.sh`는애초 로컬에 없었으므로 해당 없음).
- `localization/hooks/hooks.json`에 `SessionStart`(directive.sh)만 남음.
- 역할 고유 4값(다른 로케일에서도 산출물이 성립하는가 / i18n 트리거 /
  produces / content-design 핸드오프)이 SessionStart 출력에 그대로 노출.

## 명시적 범위 밖

- `localization/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  — 이번 이슈 대상 아님, 미변경.
- warrant 플러그인 자체 설치 여부/오케스트레이터 설정 — 이 룰북 repo의
  책임 범위 밖.
- 이 레포의 '룰북 성숙화' phase 2 이슈 — 순서 제약상 이 이슈 완료 후 진행.

## 어떻게 검증할 것인가

`stub-check.sh` 실행 결과(위 성공 기준) + `directive.sh`를
`CLAUDE_ROLE=localization`로 수동 실행해 4값이 그대로 출력되는지 확인.
