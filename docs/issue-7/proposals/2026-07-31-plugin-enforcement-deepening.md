---
status: proposed
issue: issue-7
files:
  - localization/hooks/directive.sh
  - localization/hooks/methodology-gate.sh (new)
  - localization/hooks/record-fields-localization-gate.sh
  - localization/hooks/hooks.json
  - tests/run-gate-tests.sh (new, repo root)
  - localization/checklists/locale-fitness-checklist.md (new)
---

# Plugin 심화: 채택 방법론(issue-1)을 implementation-rulebook 수준 강제 장치로

## 조사 근거

`docs/issue-7/reports/localization/survey.md` (현재 상태 — 스텁 directive
1줄/facet, phase-2 record 표면만 단어-존재 검사하는 게이트 1개, 게이트
테스트 0개, 상태추적 0개, 체크리스트 0개) +
`docs/issue-7/reports/localization/scout-brief.md` (implementation-rulebook
coding gates + pricing-rulebook methodology-gate.sh 대조, 4앵글
batched-sequential, 1스테이지 포화 — 근거·출처는 두 파일 참조).

## 채택 항목

1. **directive 심화**: `core_role_directive`의 4개 인자(구조 불변)는 issue-1
   그대로 유지하고, 그 호출 뒤에 phase-1/phase-2 각각을 위한 심화 블록을
   heredoc으로 추가 출력 — `no-footgun/hooks/directive.sh`가 core 호출
   없이도 자신의 heredoc을 추가로 찍는 것과 같은 자리(SessionStart 훅
   본문의 core 호출 이후)를 재사용, 새 훅 지점을 만들지 않는다.
   (scout-brief 근거: "core stub 뒤에 role 고유 블록을 추가하는 자리가
   이미 이 저장소 계열에 있다" — no-footgun 사례.)
2. **방법론 게이트 이중화**: 기존 `record-fields-localization-gate.sh`(
   phase-2 record 표면)는 유지·강화하고, `pricing/hooks/methodology-gate.sh`를
   참조해 새 `methodology-gate.sh`를 만들어 phase-1 제안서 표면
   (`docs/issue-<n>/proposals/*localization*.md`)에 issue-1 (a)의 4필수
   섹션 존재를 검사한다. (scout-brief must-be: "도메인 게이트는 그 도메인
   norms가 요구사항을 정의한 두 표면을 모두 검사한다".)
3. **record 게이트 정밀화**: 현재의 "단어 하나라도 있으면 통과" 방식을
   버리고, terminal record에서 (i) locale별 verdict 목록/표, (ii)
   verdict-less locale의 사유, (iii) string-external issue 각 항목의 MQM
   태그, (iv) content-design 핸드오프 트리거 유무를 issue-1 (b)의 4항목
   그대로 확인하도록 검사 로직을 넓힌다. (survey gap: 현재는 bag-of-words
   존재 확인일 뿐 항목별 확인이 아님.)
4. **상태추적: 도입하지 않는다** — 아래 "논리적 근거" 참조. 이건 열린
   질문이 아니라 이번 제안의 실행 결정이다.
5. **게이트 테스트**: 레포 루트 `tests/run-gate-tests.sh`를
   implementation-rulebook의 `tests/run-gate-tests.sh` 패턴(tempdir git
   init + stdin JSON + subprocess 실행 + exit 0/2 판정)을 **참조**해
   신규 작성 — 3개 게이트(`record-fields-localization-gate.sh`,
   신규 `methodology-gate.sh`, core의 `record-fields-gate.sh`는 core canon
   테스트 영역이므로 이 레포에서 재작성하지 않음) 각각 allow/deny 케이스.
6. **체크리스트**: `localization/checklists/locale-fitness-checklist.md` —
   issue-1 (b)-1의 기계적 i18n 축(문자열 외부화/인코딩/plural 규칙/
   로케일별 키 완전성 + 코드/문자열 리소스가 아닐 때의 N/A 규칙)을 실제
   체크 가능한 항목 목록으로 문서화. 반복 절차이지만 세션 간 상태를 갖지
   않고 사람이 읽고 체크하는 정적 목록이면 충분해 agents/는 신설하지
   않는다 — 아래 근거 참조.

## 각 채택의 논리적 근거

- **directive 심화를 core 호출 뒤 추가 블록으로**: issue-2에서 이미
  "core stub은 4개 인자 + 고정 RECORD: 줄만 출력한다"를 구조 불변으로
  확정했다(`docs/issue-2/proposals/2026-07-31-core-canon-reference-switch.md`
  §3). 이 구조를 다시 여는 건 캐논 참조 원칙 위반 방향이므로, 심화
  내용은 같은 `directive.sh` 파일 안에서 core 호출 **뒤에** heredoc으로
  추가한다 — `no-footgun/hooks/directive.sh`가 이미 이 레포 계열
  (implementation-rulebook)에서 "core/스텁 호출 없이도 자기 heredoc을
  더 찍는다"는 패턴을 보여준다(scout Sources). 캐논 스크립트 자체는 한
  글자도 복사하지 않는다 — `role-directive.sh` 소스 라인은 그대로,
  추가 텍스트는 이 저장소 파일에만 존재.
- **phase-1 게이트를 pricing 패턴으로**: 이슈 본문이 명시적으로
  "produces 규범의 필수 구성요소를 기계 검증"을 요구했고, 그 규범은
  이미 phase-1 제안서에 4필수 섹션((a) 조사근거/채택항목/논리적근거/
  반영계획)을 정의해뒀다(issue-1 norms) — pricing의 게이트가 정확히
  이 형태(자기 role의 이미 채택된 norms 문서를 인용해 그 항목만
  검사)를 이미 구현해 보였으므로 새 설계를 발명하지 않고 그 형태를
  따른다.
- **record 게이트를 항목별로 정밀화**: 현재 게이트가 "locale"이라는
  단어 하나, MQM 8개 중 아무 단어 하나만 있어도 통과시킨다 — 이는
  "verdict 없는 locale의 사유 명시" 같은 issue-1 (b)의 나머지 요구를
  전혀 검증하지 못한다. 게이트가 존재한다는 사실과 게이트가 규범을
  실제로 강제한다는 사실은 다르다 — 이 간극이 이슈 #7이 지적하는
  "directive 한 줄 + 문서로만 남았다"는 문제의 정확한 사례.
- **상태추적을 도입하지 않는 이유**: implementation-rulebook의 hunt-guard/
  hunt-state가 존재하는 이유는 "단일 세션 내 여러 Agent/Task/Workflow
  dispatch가 서로 순서를 어길 수 있는 프로세스 사실"(동시 실행되는
  hunter 수)을 카운트하는 것이지, 문서 안의 필드 순서를 강제하는 게
  아니다. localization의 방법론(체크리스트 축 → 스타일가이드 축 →
  MQM 태깅)은 전부 **한 번의 terminal record 쓰기 안에 존재하는 필드들**
  이고, 그 쓰기 자체가 이미 게이트로 걸려 있다(채택 항목 3) — 필드가
  다 채워졌는지 확인하는 것과, 채워진 순서를 프로세스 수준에서 강제하는
  것은 다른 문제이고 전자만 이 역할에 실제로 필요하다. 스텁 lock/count
  파일을 도입하면 강제할 대상이 없는 상태 기계를 하나 더 유지 부담으로
  얹는 것 — survey의 "Order-constraint question" 절 결론 재확인.
- **agents/ 대신 정적 체크리스트**: 반복 절차(기계적 i18n 4항목 확인)가
  존재하긴 하지만, hunt-guard가 다루는 "여러 세션에 걸쳐 실행 횟수를
  세야 하는 에이전트 dispatch"류의 문제가 아니라 "매번 같은 4개 항목을
  사람이 훑는" 정적 절차다. 정적 절차에 agent 프레임을 씌우면 실행
  오버헤드(별도 dispatch)만 추가되고 강제력은 늘지 않는다 — 체크리스트
  파일 하나로 같은 목적(항목 누락 방지)을 달성.

## 플러그인 반영 계획 (phase 2에서 실행 — 이번 PR은 계획만)

1. `localization/hooks/directive.sh`: 기존 `core_role_directive` 호출은
   1글자도 안 건드리고, 그 아래 새 heredoc 블록 추가:
   - PHASE 1 심화: 4필수 섹션 이름 나열 + "근거 없는 채택 주장은 가정으로
     격하 표기" 금지사항 + "조사 생략 시 생략 근거를 survey에 기록"
     판단 기준.
   - PHASE 2 심화: 두 축(체크리스트/스타일가이드) 판단 기준 + "언어
     자체의 유창성 재작성은 하지 않는다(content-design 핸드오프)" 금지
     + "코드/문자열 리소스가 아니면 체크리스트 축은 N/A" 판단 기준 +
     MQM 8종 태깅 의무.
   - 두 블록 모두 `<localization-methodology-directive>` 같은 태그로
     감싸 세션 컨텍스트에서 core 블록과 구분 가능하게.
2. 신규 `localization/hooks/methodology-gate.sh`: `pricing/hooks/
   methodology-gate.sh`의 구조(트랩-앳-탑, 루트 해석, Write/Edit/
   MultiEdit 콘텐츠 재구성, 실패-닫힘)를 참조해 작성. 대상 정규식
   `^docs/issue-[0-9]+/proposals/.*localization.*\.md$`. 검사 4항목:
   조사근거 절 존재(파일명 또는 "survey"/"scout-brief" 인용), 채택항목
   절 존재, 논리적근거 절 존재, 반영계획 절 존재 — 4개 중 하나라도
   없으면 거부, 메시지에 issue-1 norms (a) 인용.
3. `record-fields-localization-gate.sh` 수정: 기존 두 개(locale
   presence, MQM presence) 검사를 유지하되 강화 — locale 목록을
   불릿/표 패턴으로 파싱해 각 locale에 verdict 토큰(pass/fail/n/a)이
   붙어있는지, verdict-less locale에 사유 문구가 있는지, 최소 1개의
   MQM 태그가 "이슈 항목 근처"에 있는지(현재는 문서 전체 아무 곳)로
   범위를 좁힌다. 세부 정규식은 phase 2에서 확정.
4. `localization/hooks/hooks.json`: `PreToolUse`에 신규
   `methodology-gate.sh` 항목 1개 추가(matcher `.*`, 기존 항목 옆).
5. `tests/run-gate-tests.sh` (레포 루트, 신규): implementation-rulebook의
   `run()` 헬퍼(tempdir git init + stdin JSON + subprocess + exit 코드
   판정)를 참조해 재작성 — 복사 아님, 이 레포의 두 게이트 대상 fixture로
   새로 만든다. 최소 케이스: methodology-gate 4섹션-완전 allow / 1섹션
   누락 deny / 무관 경로 no-op(allow); record-fields-localization-gate
   기존 2케이스 유지 + 신규 verdict-사유-누락 deny 케이스 추가.
6. `localization/checklists/locale-fitness-checklist.md` (신규): 4개
   기계적 i18n 항목(문자열 외부화, 인코딩, plural 규칙, 로케일별 키
   완전성) + 코드/문자열 리소스가 아닐 때의 N/A 처리 규칙을 체크박스
   형태로. directive.sh의 PHASE 2 심화 블록에서 이 파일 경로를 인용.
7. **검증 방법 (phase 2 완료 후)**: (i) `tests/run-gate-tests.sh` 실행
   결과 all-pass를 기록; (ii) `directive.sh`를
   `CLAUDE_ROLE=localization`로 수동 실행해 심화 블록 노출 확인; (iii)
   결과를 `docs/issue-7/reports/localization.md`에 기록.

## 명시적 범위 밖

- 실제 파일 변경(directive.sh 심화, 신규 게이트/테스트/체크리스트 작성,
  hooks.json 등록) — phase 2, Approve 이후.
- 상태추적 기계(lock/count 파일) 신설 — 위 근거대로 이번 방법론에는
  강제할 순서 사실이 없어 도입하지 않음. 향후 norms 개정으로 진짜 순서
  제약이 생기면 그때 hunt-guard/hunt-state 패턴을 참조.
- `localization/agents/` 신설 — 정적 체크리스트로 충분, 위 근거 참조.
- core canon 게이트(`record-fields-gate.sh` 등) 자체 수정/재작성 — 참조만.

## 어떻게 검증할 것인가 (phase 1 자체에 대해)

이 문서가 조사 근거/채택 항목/논리적 근거/반영 계획 4절을 모두 포함하고
(자기 자신도 issue-1이 정의한 phase-1 규범 대상이므로 self-conformant),
각 채택 주장이 survey.md/scout-brief.md의 관찰 또는 이 레포/
implementation-rulebook/pricing-rulebook의 실제 경로를 인용하는지로
self-check 가능 — 위 각 절이 그 인용을 담고 있음.
