---
name: prd
description: PRD(Product Requirements Document) 초기화 및 관리. 복잡한 Feature의 요구사항을 user stories와 acceptance criteria로 정형화하고 진행 상황을 추적합니다. Use when planning complex features that need formal requirements tracking.
disable-model-invocation: true
source: origin
---

# PRD Skill

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills prd`

PRD(Product Requirements Document)를 초기화하고 관리합니다. 복잡한 Feature의 요구사항을 user stories와 acceptance criteria로 정형화하고 진행 상황을 추적합니다.

Taskmaster 시스템과 완전 통합되어 prd.json이 자동으로 task.json으로 변환됩니다.

## 사용 시점

- 여러 user story가 필요한 복잡한 Feature 기획
- 정형화된 요구사항 추적이 필요한 작업
- acceptance criteria 기반 검증이 필요한 작업
- autonomous-loop와 연동하여 자율 완료 기준을 정의할 때
- taskmaster 시스템과 연동하여 전역 task graph 관리가 필요할 때

## 초기화 워크플로우

### Step 1: Interview

- Analyst 에이전트가 사용자와 대화하여 요구사항 수집
- 핵심 기능, 제약사항, 우선순위 파악

### Step 2: task-folder 생성

- 현재 활성 task-folder가 없으면 새로 생성: `mkdir -p .cursor/project/state/{ISO8601-basic}_{task-name}`
- 형식: `20260318T1000_feature-name`

### Step 3: prd.json 생성

- 경로: `.cursor/project/state/{task-folder}/prd.json`
- 템플릿 기반: `.cursor/project/taskmaster/prd.template.json`
- 스키마 검증: `.cursor/project/taskmaster/prd.schema.json`
- 필수 필드: version, title, description, userStories
- 제목, 설명, completionLevel 설정
- createdAt, updatedAt를 ISO 8601 형식으로 기록

### Step 4: user stories 정의

- as/iWant/soThat 형식의 user story 작성
- 각 story에 acceptanceCriteria를 문자열 배열로 추가
- id는 US-001, US-002 형식 (패턴: `^US-[0-9]{3}$`)
- status: pending | in_progress | done | blocked
- priority: high | medium | low
- dependsOn: 다른 user story ID 배열 (선택)
- implementedIn: 구현된 파일 경로 배열 (선택)

### Step 5: 리스크 평가

- risks 배열에 객체로 기록
- description: 리스크 설명
- impact: high | medium | low
- mitigation: 완화 방안

### Step 6: 범위 정의

- scope.inScope: 이번 작업에 포함되는 항목 배열
- scope.outOfScope: 제외되는 항목 배열

### Step 7: prd.md 생성 (선택)

- 경로: `.cursor/project/state/{task-folder}/prd.md`
- prd.json을 사람이 읽기 쉬운 마크다운으로 변환
- 가독성과 협업을 위한 보조 파일
- prd.json이 진실의 원천(source of truth)

## prd.json 템플릿

```json
{
  "version": "1.0.0",
  "title": "Feature 제목",
  "description": "Feature 설명",
  "completionLevel": 3,
  "createdAt": "2026-03-18T10:00:00Z",
  "updatedAt": "2026-03-18T10:00:00Z",
  "userStories": [
    {
      "id": "US-001",
      "title": "스토리 제목 (선택)",
      "as": "사용자",
      "iWant": "하고 싶은 것",
      "soThat": "얻고자 하는 가치",
      "status": "pending",
      "priority": "high",
      "dependsOn": [],
      "acceptanceCriteria": [
        "AC-1: 검증 기준 1",
        "AC-2: 검증 기준 2"
      ],
      "implementedIn": [],
      "blockedReason": null
    }
  ],
  "risks": [
    {
      "description": "리스크 설명",
      "impact": "high",
      "mitigation": "완화 방안"
    }
  ],
  "scope": {
    "inScope": [
      "포함 항목 1",
      "포함 항목 2"
    ],
    "outOfScope": [
      "제외 항목 1",
      "제외 항목 2"
    ]
  },
  "metadata": {
    "taskFolder": "20260318T1000_feature-name",
    "tag": "master"
  }
}
```

예시 파일: `.cursor/project/taskmaster/prd.example.json`

## prd.md 템플릿 (선택적 보조 파일)

```markdown
# PRD: {Feature Name}

- description: ...
- completionLevel: 3
- createdAt: 2026-03-18T10:00:00Z
- updatedAt: 2026-03-18T10:00:00Z

## User Stories

### US-001: {story title}

- as: 사용자
- iWant: ...
- soThat: ...
- status: pending
- priority: high
- implementedIn: (none)

Acceptance Criteria:

- [ ] AC-1: ...
- [ ] AC-2: ...

### US-002: {story title}

- as: 사용자
- iWant: ...
- soThat: ...
- status: pending
- priority: medium
- implementedIn: (none)

Acceptance Criteria:

- [ ] AC-1: ...

## Risks

| 설명 | 영향도 | 완화 방안 |
|------|--------|----------|
| ... | high | ... |
| ... | medium | ... |

## Scope

### In Scope

- ...

### Out of Scope

- ...
```

## 진행 추적

- 구현 시작 시 user story의 status를 in_progress로 변경
- 완료 시 status를 done으로 변경, implementedIn 배열에 관련 파일 경로 추가
- blocked 시 blockedReason 필드에 원인 기록
- updatedAt 필드를 현재 시각으로 갱신

## taskmaster 연동

### prd.json → task.json 변환

prd.json을 생성한 후 `/tm-parse-prd` 커맨드로 task.json을 생성합니다:

```bash
bash .cursor/commands/scripts/tm-parse-prd.sh . {task-folder}
```

변환 규칙:
- userStories[] → tasks[]
- US-001 → task.id: "1"
- acceptanceCriteria[] → task.testStrategy (줄바꿈 결합)
- dependsOn[] → task.dependencies[]
- status, priority 그대로 매핑
- metadata.source: "prd"로 표시

### prd.json → prd.md 변환 (선택)

가독성을 위해 마크다운 버전을 생성할 수 있습니다:

```bash
bash .cursor/skills/prd/scripts/prd-to-md.sh . {task-folder}
```

### 전체 워크플로우

1. `/prd` - PRD 초기화, prd.json 생성
2. `bash .cursor/skills/prd/scripts/prd-to-md.sh .` - prd.md 생성 (선택)
3. `/tm-parse-prd` - prd.json → task.json 변환
4. `/tm-validate` - task.json 스키마 검증
5. `/tm-start` - 첫 번째 task 시작
6. `/tm-next` - 다음 task로 이동
7. `/tm-done` - task 완료 처리

## autonomous-loop 연동

- autonomous-loop 실행 시 prd.json이 있으면 자동 로드
- userStories[].acceptanceCriteria를 verify 단계의 검증 항목으로 사용
- completionLevel을 ralph-state.md에 반영

## PRD 상태 보고 형식

```
[PRD 상태] {title}
- 완료: N / 총 M user stories
- 진행 중: [US-xxx, ...]
- 대기: [US-xxx, ...]
- Blocked: [US-xxx - 사유]
- task.json 생성: 완료 | 미완료
- 다음 액션: /tm-parse-prd | /tm-start
```
