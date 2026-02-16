<!-- source: origin -->

# Stats — 사용 통계 조회

스킬, 커맨드, 에이전트, 빌트인 서브에이전트, 시스템 스킬의 사용 빈도를 분석하여 미사용 항목 제거 및 개선 판단을 지원합니다.

## 워크플로우

### Step 1: 사용 데이터 수집

`.cursor/project/usage-data/` 디렉터리에서 추적 데이터를 읽습니다.

데이터 형식: 각 파일은 `{count}|{ISO8601 timestamp}` 형태입니다.

```
.cursor/project/usage-data/
  .tracked-since          # 추적 시작일
  skills/{name}           # 스킬별 카운터
  commands/{name}         # 커맨드별 카운터
  agents/{name}           # 에이전트별 카운터
  subagents/{name}        # 빌트인 서브에이전트별 카운터
  system-skills/{name}    # 시스템 스킬별 카운터
```

추적 데이터가 없으면 "`usage-tracker` 훅이 아직 데이터를 수집하지 않았습니다. 세션을 사용하면 자동으로 수집됩니다." 안내.

### Step 2: 전체 항목 스캔

실제 존재하는 모든 항목을 디렉터리에서 수집합니다:

- 스킬: `.cursor/skills/*/SKILL.md` — Glob으로 검색, 디렉터리명 추출
- 커맨드: `.cursor/commands/*.md` — Glob으로 검색, 파일명(확장자 제외) 추출
  - `stats.md` 자체는 목록에서 제외
- 에이전트: `.cursor/agents/*.md` — Glob으로 검색, 파일명(확장자 제외) 추출
- 서브에이전트: `usage-data/subagents/` — 추적된 타입 목록 (subagentStart hook으로 수집)
- 시스템 스킬: `usage-data/system-skills/` — 추적된 시스템 스킬 목록

### Step 3: 데이터 병합 및 정렬

각 항목에 대해:
1. usage-data에 카운터 파일이 있으면 count와 lastUsed 읽기
2. 없으면 count=0, lastUsed=없음으로 처리
3. 카테고리별로 count 내림차순 정렬

### Step 4: 통계 출력

아래 형식으로 출력합니다. 숫자와 날짜는 실제 데이터 기반입니다.

```
[사용 통계] 추적 기간: {시작일} ~ 현재 ({N}일)

스킬 ({전체}개, 활성 {1회 이상}개):
  #1  {name}          {count}회  (최근: {상대시간})
  #2  {name}          {count}회  (최근: {상대시간})
  ...
  --- 미사용 (0회) ---
  {name}              0회
  {name}              0회

커맨드 ({전체}개, 활성 {1회 이상}개):
  #1  {name}          {count}회  (최근: {상대시간})
  ...
  --- 미사용 (0회) ---
  ...

에이전트 ({전체}개, 활성 {1회 이상}개):
  #1  {name}          {count}회  (최근: {상대시간})
  ...
  --- 미사용 (0회) ---
  ...
```

상대시간 계산:
- 1시간 미만: "N분 전"
- 24시간 미만: "N시간 전"
- 7일 미만: "N일 전"
- 30일 미만: "N주 전"
- 그 이상: "N개월 전"

### Step 5: 제거 추천

미사용 항목(count=0) 중에서 다음 조건에 해당하면 "제거 추천"으로 표시:

1. 추적 기간이 7일 이상이고 count=0인 항목
2. synapse.mdc에서 참조되지 않는 항목 (Grep으로 확인)
3. 다른 스킬/커맨드에서도 참조되지 않는 항목

출력:
```
제거 추천 ({N}개):
  스킬: {name1}, {name2}, ...
  커맨드: {name1}, ...
  에이전트: {name1}, ...

제거하려면 삭제할 항목을 알려주세요.
예: "evolve, lsp 스킬을 제거해줘"
```

### Step 6: 사용 추세 분석 (확장)

추적 기간이 14일 이상이면 추가 분석:

- 가장 많이 사용된 Top 5 (전체 카테고리 통합)
- 최근 7일간 사용된 항목 vs 미사용 항목 비교
- 핵심 워크플로우 패턴 (자주 함께 사용되는 조합 추정)

### Step 7: usage-stats.json 생성 (선택)

사용자가 요청하면 `.cursor/project/usage-stats.json`에 스냅샷을 생성합니다:

```json
{
  "version": 1,
  "generatedAt": "{ISO8601}",
  "trackedSince": "{ISO8601}",
  "totalDays": N,
  "skills": {
    "{name}": {"count": N, "lastUsed": "{ISO8601}"},
    ...
  },
  "commands": { ... },
  "agents": { ... },
  "recommendations": {
    "remove": ["{name}", ...],
    "topUsed": ["{name}", ...]
  }
}
```

### Step 8: 제거 실행

사용자가 특정 항목 제거를 요청하면:

1. 해당 항목이 다른 파일에서 참조되는지 Grep으로 확인
2. 참조가 있으면 경고 후 확인 요청
3. 확인되면:
   - 스킬: `.cursor/skills/{name}/` 디렉터리 삭제
   - 커맨드: `.cursor/commands/{name}.md` 파일 삭제
   - 에이전트: `.cursor/agents/{name}.md` 파일 삭제
   - synapse.mdc에서 해당 참조 정리 (있는 경우)
   - usage-data에서 카운터 파일 삭제
4. 삭제 결과 보고

### Step 9: 추적 초기화 (--reset)

사용자가 "추적 초기화", "카운터 리셋", "stats reset", "stats --reset" 등을 요청하면 추적 데이터를 초기화합니다.

초기화 옵션:

- 전체 초기화: 모든 카테고리의 카운터를 0으로 리셋
- 카테고리별 초기화: 스킬/커맨드/에이전트 중 선택한 카테고리만 리셋
- 특정 항목 초기화: 지정한 항목의 카운터만 리셋

워크플로우:

1. 초기화 범위를 사용자에게 확인 (전체/카테고리/특정 항목)
2. 현재 통계를 요약 표시하여 삭제될 데이터를 보여줌
3. 사용자 확인 후 실행:
   - 전체 초기화 시:
     - `.cursor/project/usage-data/skills/*` 모든 파일 삭제
     - `.cursor/project/usage-data/commands/*` 모든 파일 삭제
     - `.cursor/project/usage-data/agents/*` 모든 파일 삭제
     - `.cursor/project/usage-data/.tracked-since` 삭제
     - 다음 Read 추적 시 .tracked-since가 새로 생성되어 추적 재시작
   - 카테고리 초기화 시: 해당 카테고리 하위 파일만 삭제
   - 특정 항목 초기화 시: 해당 카운터 파일만 삭제
4. 초기화 결과 보고

출력:
```
[추적 초기화 완료]
  삭제된 카운터: {N}개
  범위: {전체 / 스킬 / 커맨드 / 에이전트 / 특정 항목}
  이전 추적 기간: {시작일} ~ {현재} ({N}일)
  새 추적은 다음 세션 사용 시 자동 시작됩니다.
```
