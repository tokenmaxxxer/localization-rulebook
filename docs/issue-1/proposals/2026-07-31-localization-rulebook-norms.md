---
status: proposed
issue: issue-1
files:
  - localization/hooks/directive.sh
  - localization/hooks/hooks.json
  - localization/hooks/record-fields-localization-gate.sh (new)
---

# Localization 룰북 규범: phase 1 제안서 / phase 2 산출물 방법론 확정

## 조사 근거

`docs/issue-1/reports/localization/survey.md` (현재 상태 — 이 룰북엔
카테고리 체계·per-locale 판정 방법론·플러그인 강제가 전무함) +
`docs/issue-1/reports/localization/scout-brief.md` (MQM, ISO 17100/TEP,
i18n 리뷰 체크리스트·pseudo-localization, LSO 조사, 4개 앵글 병렬 스윕,
1스테이지로 포화 판단 — 자세한 근거·출처는 두 파일 참조).

## (a) 제안서(phase 1) 규범

**방법론**: 이 문서 자체가 그 예시이자 강제 대상이다 — scout-directive의
현재상태서베이 → 스카우트 → 브리프 → 제안 순서를 따른다(생략 시 생략
근거를 survey에 기록해야 함, 이번엔 생략하지 않았음).

**필수 섹션** (§20 record-fields 최소 요건 위에 이 역할 전용으로 추가):

1. 조사 근거 절 — survey.md/scout-brief.md 인용 (또는 스카우트 생략
   기록에 대한 인용).
2. 채택 항목 절 — (b)의 각 방법론 요소를 무엇을 근거로 채택했는지.
3. 각 채택의 논리적 근거 절 — (c), 아래.
4. 플러그인 반영 계획 절 — (d), directive/record-fields/게이트에
   구체적으로 무엇을 어떻게 반영할지.

**근거 형식**: 채택 주장 하나마다 최소 한 개의 외부 출처(URL) 또는
"survey.md의 어느 관찰"을 인용해야 한다 — 근거 없는 채택 주장은 가정으로
격하 표기.

## (b) 산출물(phase 2) 규범

**방법론**: 이 역할의 산출물은 "locale-fitness verdict per target
locale" + "string-external issue list" (directive에 이미 명시). 이를
아래 두 방법론으로 생산한다:

1. **판정 방법론 (ISO 17100/LSO 계열에서 축소 채용)**: 대상 로케일별
   판정은 (i) 기계적 i18n 체크리스트 통과 여부(문자열 외부화/인코딩/
   plural 규칙/로케일별 키 완전성 — 코드·문자열 리소스가 대상일 때만
   해당, 산출물이 순수 텍스트/문서일 때는 해당 항목을 "N/A" 명시)와
   (ii) 스타일 가이드·기존 로케일 관례 대비 위반 여부, 두 축으로만
   내려진다 — 언어 자체의 유창성 재작성은 하지 않는다(그건 directive의
   content-design 핸드오프 영역).
2. **분류 방법론 (MQM 8-dimension 축소 채용)**: string-external issue
   list의 각 항목은 MQM 8대 분류(Accuracy, Fluency, Terminology, Locale
   convention, Style, Verity, Design, Internationalization) 중 하나로
   태깅한다. 100+ 세부 issue type 전체는 채택하지 않는다(scout-brief의
   adopt/skip 참조) — 이 역할이 실제로 판단할 수 있는 굵은 단위로 축소.

**필수 구성요소** (phase-2 record, §20 위에 추가):

- 대상 locale 목록과 각각의 verdict(pass/fail/N/A) — 최소 표 또는 목록.
- verdict 없는 locale이 있으면 왜 없는지(범위 밖/입력 불충분) 명시.
- string-external issue 각각에 MQM 카테고리 태그 + 근거(체크리스트
  항목 또는 스타일 가이드 인용).
- content-design 핸드오프가 발생했다면 그 트리거(어떤 이슈가 카피
  재작성을 요구했는지) 명시.

## (c) 각 채택의 논리적 근거

- **MQM 축소 채용**: 이 역할의 산출물이 이미 "list"로 정의돼 있다 —
  목록의 각 항목이 비교 가능한 카테고리 없이 자유서술이면, 이 역할이
  같은 이슈를 반복 판단할 때도, 다른 세션이 이어받을 때도 같은 종류의
  결함을 다른 말로 다시 발견하는 낭비가 생긴다. MQM은 정확히 이 문제
  ("두 리뷰어가 비교 가능한 점수를 내게 하는 것")를 풀도록 설계된
  업계 표준이고, 8-dimension 최상위 레벨만 쓰는 것도 MQM 자신의
  "customized subset" 권장 관행이다 — 룰북이 다 쓸 필요 없는 100+
  세부항목을 억지로 채용해 무게를 지우지 않는다.
- **ISO 17100/LSO 축소 채용, 전체 인증 체계는 skip**: 이 역할은 번역
  벤더가 아니라 다른 역할의 산출물을 검토하는 게이트 역할이다(계약서·
  번역가 자격 인증 같은 ISO 17100의 나머지는 이 역할의 권한/책임
  범위 밖). 그러나 "제작 국면과 검증 국면을 분리하고, 최종 통합된
  형태에서만 sign-off한다"는 원칙은 그대로 유효하다 — 이건 이미
  contract v3의 phase 1(제안)/phase 2(산출물, human Approve 게이트)
  구조가 구현하고 있으므로, 새 국면을 발명하지 않고 기존 구조에
  얹는다(스카우트 브리프의 gap line: 이 부분은 이미 충족된 필드).
- **i18n 체크리스트 항목을 판정 축의 하나로**: locale-fitness라는
  directive 문구 자체가 "다른 로케일에서도 산출물이 성립하는가"이고,
  업계 조사가 공통으로 보여준 것은 이 질문에 대한 답이 사람의 감이
  아니라 기계적으로 확인 가능한 체크 항목(인코딩/외부화/복수형/키
  완전성)으로 상당 부분 환원된다는 점이다 — 이 축을 넣지 않으면
  "성립하는가"의 절반을 감으로 판단하게 된다. 산출물이 코드/문자열
  리소스가 아닐 때는 N/A로 빠지게 해 오탐을 막는다.
- **왜 phase 1/phase 2 규범을 별개로 나눴는가**: 이슈 본문이 이미
  (a)/(b)를 분리해 요구했고, 두 산출물의 검증 대상이 다르다(제안서는
  근거의 질, 산출물은 판정의 질) — 하나의 규범으로 뭉치면 §20이 이미
  강제하는 것과 새로 강제해야 하는 것의 경계가 흐려진다.

## (d) 플러그인 반영 계획 (phase 2에서 실행 — 이번 PR은 계획만)

1. **directive.sh**: `PRODUCES` 값을 현재의 "locale-fitness verdict per
   target locale, string-external issue list"에서, 위 방법론을 반영해
   "locale-fitness verdict (checklist+style-guide basis) per target
   locale, MQM-tagged string-external issue list"로 갱신 (core stub
   4-인자 구조 유지, `core_role_directive` 호출부만 문자열 교체 — 구조
   자체는 안 건드림).
2. **신규 게이트 `localization/hooks/record-fields-localization-gate.sh`**:
   `core/hooks/record-fields-gate.sh`와 같은 PreToolUse 훅 지점에서,
   대상이 `docs/issue-<n>/reports/localization.md`이고 `loop_state`가
   §20 상 terminal일 때만 추가로 검사 — (i) locale 목록 존재, (ii) 각
   string-external issue에 MQM 8-dimension 중 하나의 태그 문자열 존재,
   없으면 거부(§20 위에 얹는 role-specific 확장이지 §20 자체의 대체가
   아님 — core 게이트를 절대 복제하지 않는다, core canon 참조 원칙
   유지). `localization/hooks/hooks.json`의 `PreToolUse`에 이 게이트
   하나만 신규 등록.
3. **RECORD_FIELDS_TERMINAL_STATES**: 이번 조사에서 이 룰북 전용
   terminal state가 필요하다는 근거를 찾지 못함 — core 기본값
   (`landed`)을 그대로 사용, 새로 설정하지 않는다.
4. **검증 방법 (phase 2 완료 후)**: (i) 신규 게이트를 unit-shell 테스트로
   — 태그 누락 payload는 거부(exit 2), 태그 포함 payload는 통과(exit 0)
   확인; (ii) `directive.sh`를 `CLAUDE_ROLE=localization`로 수동 실행해
   갱신된 PRODUCES 문구 노출 확인; (iii) 결과를
   `docs/issue-1/reports/localization.md`에 기록.

## 명시적 범위 밖

- 실제 파일 변경(directive.sh 갱신, 신규 게이트 작성, hooks.json 등록)
  — phase 2, Approve 이후.
- warrant-hunter/트레일러/handbook-trigger 게이트 — issue-2 범위, 이미
  core canon 참조로 전환 완료(#4), 재론하지 않음.
- ISO 17100 인증·번역가 자격·클라이언트 계약 체계 전체 도입 — 이 역할의
  권한 범위 밖(스카우트 브리프 skip 항목).

## 어떻게 검증할 것인가 (phase 1 자체에 대해)

이 문서가 (a)~(d) 4개 섹션을 모두 포함하고, 각 채택 주장이
survey.md/scout-brief.md의 관찰 또는 외부 출처를 인용하는지로 self-check
가능 — 위 각 절이 그 인용을 담고 있음.
