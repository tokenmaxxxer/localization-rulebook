---
status: proposed
issue: issue-7
files:
  - localization/plugins/proposal-gate/.claude-plugin/plugin.json (new)
  - localization/plugins/proposal-gate/hooks/hooks.json (new)
  - localization/plugins/proposal-gate/hooks/directive.sh (new)
  - localization/plugins/proposal-gate/hooks/methodology-gate.sh (new)
  - localization/plugins/proposal-gate/tests/ (new)
  - localization/plugins/verdict-axis/.claude-plugin/plugin.json (new)
  - localization/plugins/verdict-axis/hooks/hooks.json (new)
  - localization/plugins/verdict-axis/hooks/directive.sh (new)
  - localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh (new)
  - localization/plugins/verdict-axis/checklists/locale-fitness-checklist.md (new)
  - localization/plugins/verdict-axis/tests/ (new)
  - localization/plugins/mqm-tagging/.claude-plugin/plugin.json (new)
  - localization/plugins/mqm-tagging/hooks/hooks.json (new)
  - localization/plugins/mqm-tagging/hooks/directive.sh (new)
  - localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh (new)
  - localization/plugins/mqm-tagging/tests/ (new)
  - .claude-plugin/marketplace.json (edit, repo root — 3 new entries)
  - tests/run-gate-tests.sh (new, repo root)
---

# Plugin 심화 (개정): 채택 방법론(issue-1) 3개를 독립 플러그인 세트로

## 조사 근거

`docs/issue-7/reports/localization/survey.md` (현재 상태 — 스텁
directive 1줄/facet, phase-2 record 표면만 단어-존재 검사하는 게이트 1개,
phase-1 표면 게이트 0개, 게이트 테스트 0개, 상태추적 0개, 체크리스트
0개; "order-constraint question" 절 — 채택 방법론들은 한 번의 terminal
record 쓰기 안에 존재하는 독립 필드들이지 tool-call 사이 순서 제약이
아니라는 결론) + `docs/issue-7/reports/localization/scout-brief.md`
(implementation-rulebook coding gates + pricing-rulebook
`methodology-gate.sh` 대조, 4앵글 batched-sequential, 1스테이지 포화) +
`docs/issue-1/proposals/2026-07-31-localization-rulebook-norms.md`
((a)/(b) — 이 저장소가 실제로 채택한 세 방법론이 정의된 원본).

**이번 개정의 구속 조건**: 승인자(JiwonJung94)가 issue #7에 남긴 요구
정정 코멘트가 이 문서의 구조를 강제한다 —

> 단일 게이트/디렉티브 심화가 아니라 **플러그인 세트**로 체계화한다:
> 채택 방법론 각각을 독립 플러그인으로(core의 freelunch/scout처럼),
> 기획서(phase 1) 규범과 산출물(phase 2) 규범도 각각을 플러그인 조합으로
> 풀어낸다, 각 플러그인 = 자기 완결 + marketplace.json 등록 + 명확한
> 단일 방법론 담당, proposal에는 플러그인 목록이 필수.

이전 버전(현재 커밋 32efe77, 이 문서가 대체하는 버전)은 단일 심화
directive + 단일 `methodology-gate.sh` + 단일 강화 record 게이트로
설계했었다 — 이는 위 정정이 명시적으로 거부한 아키텍처다. 이 문서는
그 아키텍처를 폐기하고 아래로 다시 설계한다. 이전 버전이 인용한
survey/scout-brief 근거(특히 fail-closed trap-at-top, 독립 root 해석,
"additive not replacement" 프레이밍, dual-surface 매칭, subprocess 기반
게이트 테스트)는 그대로 유효하므로 재인용해 이어간다.

## 플러그인 목록

issue-1 (a)/(b)가 정의한 세 방법론은 정확히 분리 가능한 세 개의
"YOU DECIDE" 단위다 — 병합하지도, 더 쪼개지도 않는다.

| 이름 | 담당 방법론(단일) | 구성요소 | 조합 관계 |
|---|---|---|---|
| `localization-proposal-gate` | issue-1 (a) phase-1 제안서 구조 규범 (4필수 섹션 + per-claim 인용 요구) | directive(SessionStart heredoc), 게이트(PreToolUse `methodology-gate.sh`), 테스트 | **phase-1 규범 = 이 플러그인 단독** |
| `localization-verdict-axis` | issue-1 (b)-1 두 축 판정 방법론(ISO 17100/LSO 축소 채용: 체크리스트 축 + 스타일가이드 축, 유창성 재작성 제외, N/A 규칙) | directive(SessionStart heredoc), 게이트(PreToolUse `verdict-axis-gate.sh`), `locale-fitness-checklist.md`, 테스트 | **phase-2 규범의 절반** — mqm-tagging과 병렬 조합 |
| `localization-mqm-tagging` | issue-1 (b)-2 MQM 8-dimension 축소 채용 분류 방법론 | directive(SessionStart heredoc), 게이트(PreToolUse `mqm-tagging-gate.sh`), 테스트 | **phase-2 규범의 절반** — verdict-axis와 병렬 조합 |

기존 base `localization` 플러그인(루트 `.claude-plugin/plugin.json` +
`localization/hooks/directive.sh`의 `core_role_directive` 4-인자 호출,
issue-2에서 구조 동결 — `docs/issue-2/proposals/
2026-07-31-core-canon-reference-switch.md` §3)은 그대로 둔다. 위 3개는
그 옆에 **추가**되는 신규 플러그인이지, base를 대체하거나 그 호출부를
다시 여는 게 아니다.

## 채택 항목 (이번엔 "어떤 플러그인이 담당하는가"로)

1. **phase-1 제안서 구조 규범** → `localization-proposal-gate`가 전담.
   directive 블록: 4필수 섹션 이름(조사근거/채택항목/논리적근거/반영계획)
   + "근거 없는 채택 주장은 가정으로 격하 표기" 금지 + "조사 생략 시
   생략 근거를 survey에 기록" 판단 기준. 게이트: `docs/issue-<n>/
   proposals/*localization*.md` 쓰기에서 4섹션 존재 확인(pricing의
   `methodology-gate.sh` 패턴 참조, scout-brief must-be).
2. **두 축 판정 방법론(ISO 17100/LSO 축소 채용)** →
   `localization-verdict-axis`가 전담. directive 블록: (i) 체크리스트
   축(문자열 외부화/인코딩/plural/키 완전성, 코드·문자열 리소스가 아니면
   N/A) (ii) 스타일가이드·로케일 관례 축, "유창성 재작성은
   content-design 핸드오프 영역" 금지. 게이트: `docs/issue-<n>/
   reports/localization.md` terminal 쓰기에서 locale별 두 축 verdict
   존재 확인(단순 "locale" 토큰 존재가 아니라 verdict-less locale의
   사유까지).
3. **MQM 8-dimension 축소 채용 분류** → `localization-mqm-tagging`이
   전담. directive 블록: 8대 카테고리 나열(Accuracy/Fluency/
   Terminology/Locale convention/Style/Verity/Design/
   Internationalization) + "100+ 세부 issue type은 채택하지 않음" 범위
   한정. 게이트: 같은 record 표면에서 각 string-external issue 항목
   **근처**에 8종 중 하나의 태그가 붙어 있는지(문서 전체 아무 곳 아님).

## 각 채택의 논리적 근거

- **왜 3개로 쪼갰나(병합이 아니라)**: 위 승인자 정정이 구조 요구이기도
  하지만, 근거도 있다 — 세 방법론은 서로 다른 write 표면(phase-1
  proposal vs phase-2 record)과 서로 다른 검증 축(제안서 구조 vs 판정
  두 축 vs 분류)을 갖는다. 하나의 파일/게이트에 셋을 다 넣으면
  "이 게이트가 지금 무슨 규범을 검사 중인가"를 코드를 읽어야만 알 수
  있게 된다 — 반대로 플러그인 하나 = 방법론 하나면 `plugin.json`의
  description 한 줄이 곧 그 답이다(core `freelunch`/`scout`이 이미
  이 패턴 — 룰북당 여러 개의 자기완결 플러그인).
- **조합(composition)이 실제로 어떻게 동작하는가 — 이게 이 설계의
  핵심**: phase-2 규범("두 축 판정 AND MQM 태깅 모두 만족해야 terminal
  record 통과")은 `localization-verdict-axis`와
  `localization-mqm-tagging`이 **각자 독립적으로** 같은 write 표면
  (`docs/issue-<n>/reports/localization.md` at terminal state)에
  PreToolUse 훅을 등록하는 것만으로 자동 성립한다. Claude Code는 한
  이벤트에 매칭되는 모든 훅을 실행하고, 그중 하나라도 deny(exit 2)하면
  그 write 자체가 막힌다 — 따라서 "verdict-axis 통과 AND mqm-tagging
  통과"라는 AND 합성은 두 스크립트 중 어느 쪽도 상대방의 존재를 몰라도
  된다. 이는 단일 병합 게이트 스크립트 안에 `if axis_ok && mqm_ok`를
  손으로 쓰는 것보다 오히려 **더 기계적으로 견고**하다 — 병합 게이트는
  한쪽 로직을 고치다 다른 쪽 조건을 실수로 깨뜨릴 수 있지만, 분리된
  두 훅은 서로의 실패 모드에 영향을 주지 않는다(한쪽이 버그로 항상
  allow해도 다른 쪽이 여전히 독립적으로 deny할 수 있음). 방법론별
  플러그인 분리가 "조직 취향"이 아니라 이 조합 방식의 전제 조건이라는
  뜻이다.
- **phase-1은 왜 단독 플러그인 하나인가(조합이 아니라)**: issue-1의
  (a)/(b) 분리 자체가 이미 "제안서 규범은 하나, 산출물 규범은 두
  방법론의 결합"이라는 비대칭 구조를 갖고 있다 — phase-1엔 애초에 결합할
  두 번째 방법론이 없다(제안서 구조 규범 하나뿐). 그러므로
  `localization-proposal-gate`는 조합 없이 `docs/issue-<n>/
  proposals/*localization*.md` 표면 하나에 단독으로 건다.
- **상태추적은 여전히 도입하지 않는다** — survey의 "Order-constraint
  question" 결론 재확인: 세 방법론(제안서 구조, 두 축 판정, MQM 태깅)은
  모두 각자의 표면에 대한 **단일 terminal 쓰기 안의 필드 완전성**
  문제이지, tool-call 사이의 순서/카운트를 프로세스 수준에서 강제해야
  하는 문제(hunt-guard/hunt-state류)가 아니다. 플러그인을 셋으로
  쪼갰다고 해서 이 결론이 바뀌지 않는다 — 오히려 "각 플러그인이 자기
  표면에 자기 완결 게이트 하나만 갖는다"는 구조가 순서 제약이 없다는
  사실과 정합적이다. lock/count 파일은 세 플러그인 어디에도 없다.
- **`locale-fitness-checklist.md`가 왜 `agents/`가 아니라 static
  파일이고, 왜 `verdict-axis` 플러그인 소유인가**: 체크리스트가 다루는
  4항목(외부화/인코딩/plural/키 완전성)은 매번 같은 항목을 사람이
  훑는 정적 절차이지, 세션 간 dispatch 횟수를 세야 하는 문제가 아니다
  (agent 프레임을 씌우면 실행 오버헤드만 늘고 강제력은 늘지 않음 —
  이전 버전과 동일 근거, 유지). 소유권은 verdict-axis에 두는데, 이
  체크리스트가 검증하는 게 정확히 그 플러그인이 전담하는 두 축 중
  체크리스트 축이기 때문이다 — mqm-tagging이나 proposal-gate가 이
  파일을 참조할 이유가 없다(자기 완결 원칙).
- **base `localization` 플러그인을 안 건드리는 이유**: issue-2 §3이
  이미 `core_role_directive` 4-인자 호출을 구조 동결했다. 이 구조를
  다시 여는 건 canon 참조 원칙 위반 방향이다. 3개의 신규 플러그인은
  각자 별도 SessionStart 훅으로 자기 heredoc 블록을 출력하고, base의
  호출부는 한 글자도 안 건드린다.

## 플러그인 반영 계획 (phase 2에서 실행 — 이번 PR은 계획만)

각 플러그인은 core `localization`과 같은 골격
(`.claude-plugin/plugin.json` + `hooks/hooks.json` + `hooks/*.sh`)을
따르되 서로 다른 디렉토리에 완전히 독립적으로 놓인다.

1. **`localization/plugins/proposal-gate/`**
   - `.claude-plugin/plugin.json`: name `localization-proposal-gate`,
     description에 "phase-1 제안서 구조 규범 전담" 명시.
   - `hooks/hooks.json`: SessionStart → `hooks/directive.sh`; PreToolUse
     (matcher `.*`) → `hooks/methodology-gate.sh`.
   - `hooks/directive.sh`: core 호출 없이(이 플러그인은 base 옆의 추가
     플러그인이므로 자체 heredoc만 출력 — no-footgun 계열 패턴 참조) 4
     필수 섹션 + 인용 요구 + 생략-근거 판단 기준 출력.
   - `hooks/methodology-gate.sh`: pricing `methodology-gate.sh` 구조를
     **참조**(트랩-앳-탑, 독립 root 해석, Write/Edit/MultiEdit 콘텐츠
     재구성, fail-closed) 해 새로 작성. 대상 정규식
     `^docs/issue-[0-9]+/proposals/.*localization.*\.md$`. 4섹션(조사
     근거/채택 항목/논리적 근거/반영 계획) 중 하나라도 없으면 거부,
     메시지에 issue-1 (a) 인용.
   - `tests/`: allow(4섹션 완전) / deny(1섹션 누락) / no-op(무관 경로)
     케이스.

2. **`localization/plugins/verdict-axis/`**
   - `.claude-plugin/plugin.json`: name `localization-verdict-axis`,
     description에 "phase-2 두 축 판정 방법론 전담" 명시.
   - `hooks/hooks.json`: SessionStart → `hooks/directive.sh`; PreToolUse
     (matcher `.*`) → `hooks/verdict-axis-gate.sh`.
   - `hooks/directive.sh`: 두 축 판단 기준 + 유창성 재작성 금지(
     content-design 핸드오프) + N/A 규칙 + `checklists/
     locale-fitness-checklist.md` 경로 인용 출력.
   - `hooks/verdict-axis-gate.sh`: 대상 `docs/issue-<n>/
     reports/localization.md`, terminal `loop_state`(core 기본값
     `landed` 사용, role-specific terminal state 불필요 — survey 결론
     유지)일 때만 검사 — locale별 두 축 verdict 존재 + verdict-less
     locale의 사유 존재. 기존 `record-fields-localization-gate.sh`의
     locale-관련 절반을 이 플러그인으로 이관하고 세부 정규식을 정밀화
     (기존: 단어 존재 → 신규: locale별 verdict 파싱).
   - `checklists/locale-fitness-checklist.md`: 4개 기계적 i18n 항목 +
     N/A 처리 규칙, 체크박스 형태.
   - `tests/`: allow(두 축 verdict 완전) / deny(verdict-less locale
     사유 누락) / N/A 케이스 / no-op.

3. **`localization/plugins/mqm-tagging/`**
   - `.claude-plugin/plugin.json`: name `localization-mqm-tagging`,
     description에 "phase-2 MQM 8-dim 분류 방법론 전담" 명시.
   - `hooks/hooks.json`: SessionStart → `hooks/directive.sh`; PreToolUse
     (matcher `.*`) → `hooks/mqm-tagging-gate.sh`.
   - `hooks/directive.sh`: MQM 8대 카테고리 나열 + "100+ 세부 미채택"
     범위 한정 출력.
   - `hooks/mqm-tagging-gate.sh`: 같은 record 표면·terminal 조건에서
     각 string-external issue 항목 **근처**(같은 불릿/줄 또는 바로
     다음 줄)에 8종 중 하나의 태그 문자열이 있는지 검사 — 기존
     `record-fields-localization-gate.sh`의 MQM-관련 절반을 이관하고
     "문서 전체 아무 곳" 검사를 "항목별 인접" 검사로 정밀화.
   - `tests/`: allow(모든 issue 태깅) / deny(태그 없는 issue 존재) /
     no-op.

4. **기존 `localization/hooks/record-fields-localization-gate.sh` 및
   `localization/hooks/directive.sh`**: base 플러그인 소유로 그대로
   유지 — issue-1 최초 채택분의 최소 게이트 자리이며, 위 3개 신규
   플러그인이 각자의 표면에서 더 정밀한 검사를 추가로 건다. 중복
   deny는 문제가 아니다(fail-closed 원칙상 여러 게이트가 같은 결함을
   각자 잡아도 안전 쪽으로만 작동).

5. **루트 `.claude-plugin/marketplace.json`**: 기존 `"localization"`
   항목 옆에 3개 신규 항목 추가 —
   ```json
   { "name": "localization-proposal-gate", "source": "./localization/plugins/proposal-gate", "description": "..." },
   { "name": "localization-verdict-axis", "source": "./localization/plugins/verdict-axis", "description": "..." },
   { "name": "localization-mqm-tagging", "source": "./localization/plugins/mqm-tagging", "description": "..." }
   ```
   각 description은 "담당 방법론 1개"만 진술(위 플러그인 목록 표의
   문구 재사용).

6. **루트 `tests/run-gate-tests.sh`** (신규, 레포 최초): implementation-
   rulebook의 `run()` 헬퍼(tempdir git init + stdin JSON + subprocess +
   exit 코드 판정, scout-brief must-be)를 **참조**해 새로 작성 — 3개
   신규 게이트(`methodology-gate.sh`, `verdict-axis-gate.sh`,
   `mqm-tagging-gate.sh`) 각각의 allow/deny/no-op 케이스를 하나의
   러너에서 순차 실행. 기존 `record-fields-localization-gate.sh`는
   base 플러그인 소관이므로 이 러너에 포함하되 케이스는 이관 후 축소된
   범위(단순 존재 확인만, verdict/MQM 세부는 신규 게이트가 담당)로
   유지.

7. **검증 방법 (phase 2 완료 후)**: (i) `tests/run-gate-tests.sh`
   실행 결과 all-pass 기록; (ii) 3개 신규 `directive.sh`를 각각
   `CLAUDE_ROLE=localization`로 수동 실행해 heredoc 블록 노출 확인
   (base 블록과 함께 3개 블록이 모두 세션에 나타나는지는 phase 2
   실측 — 아래 검증 미해결 항목 참조); (iii) marketplace.json에 4개
   localization 계열 항목(base 1 + 신규 3)이 모두 유효 JSON으로
   파싱되는지 확인; (iv) 결과를 `docs/issue-7/reports/localization.md`
   에 기록.

**phase-2 검증 미해결 항목(사실로 단정하지 않음)**: Claude Code가 같은
role 세션에서 여러 플러그인의 SessionStart 훅을 **모두 병합 실행**
하는지, 아니면 마지막에 등록된 것만 실행하는지는 이번 조사에서
확인하지 못했다 — phase 2에서 반드시 실측 확인해야 하는 open
verification point로 남긴다. PreToolUse 훅의 "매칭되는 모든 훅 실행,
하나라도 deny하면 차단" 동작은 core `localization` 플러그인과 기존
`record-fields-localization-gate.sh`가 같은 `matcher: ".*"` 아래 이미
동작 중인 사실로 뒷받침되지만(현재도 PreToolUse에 훅 1개가 정상
동작), 여러 **플러그인**에 걸쳐서도 동일하게 병합되는지는 3개 신규
플러그인을 실제로 설치·실행해봐야 확정된다.

## 명시적 범위 밖

- 실제 파일 생성(3개 플러그인 디렉토리, marketplace.json 편집,
  hooks/게이트/체크리스트/테스트 작성) — phase 2, Approve 이후. 이번
  PR은 설계 문서만 바꾼다.
- core canon 스크립트(`role-directive.sh`, `record-fields-gate.sh` 등)
  자체 수정/복사 — 참조만, 한 글자도 vendoring하지 않는다(core
  canon-scripts.md 원칙).
- base `localization` 플러그인의 `core_role_directive` 4-인자 호출부
  재구조화 — issue-2 §3 동결 유지, 재론하지 않음.
- 상태추적 기계(lock/count 파일) 신설 — 위 근거대로 이번 방법론
  어디에도 강제할 순서 사실이 없어 3개 플러그인 어디에도 도입하지
  않음.
- ISO 17100 전체 인증 체계·번역가 자격·클라이언트 계약 — issue-1이
  이미 skip한 범위, 재론하지 않음.

## 어떻게 검증할 것인가

이 문서 자신이 `localization-proposal-gate`가 앞으로 강제할 4필수
섹션(조사 근거/채택 항목/논리적 근거/반영 계획 — 여기서는 "플러그인
반영 계획"으로 명명하되 동일 절)을 포함하는지로 self-check 가능하고,
추가로 승인자 정정이 요구한 "플러그인 목록" 절을 포함하는지로도
self-conformant해야 한다(위 표 절 존재). 각 채택 주장이
survey.md/scout-brief.md/issue-1 proposal의 구체 관찰 또는
implementation-rulebook/pricing-rulebook의 실제 경로를 인용하는지로도
확인 가능 — 위 각 절이 그 인용을 담고 있음.
