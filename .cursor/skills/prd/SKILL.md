---
name: prd
description: PRD(Product Requirements Document) 초기화 및 관리. 복잡한 Feature의 요구사항을 user stories와 acceptance criteria로 정형화하고 진행 상황을 추적합니다. Use when planning complex features that need formal requirements tracking.
disable-model-invocation: true
source: origin
---

# PRD Skill

PRD(Product Requirements Document)를 초기화하고 관리합니다. 복잡한 Feature의 요구사항을 user stories와 acceptance criteria로 정형화하고 진행 상황을 추적합니다.

## 사용 시점

- 여러 user story가 필요한 복잡한 Feature 기획
- 정형화된 요구사항 추적이 필요한 작업
- acceptance criteria 기반 검증이 필요한 작업
- autonomous-loop와 연동하여 자율 완료 기준을 정의할 때

## 초기화 워크플로우

### Step 1: Interview

- Analyst 에이전트가 사용자와 대화하여 요구사항 수집
- 핵심 기능, 제약사항, 우선순위 파악

### Step 2: prd.md 생성

- 경로: `.cursor/project/state/{task-folder}/prd.md`
- 현재 활성 task-folder가 없으면 새로 생성: `mkdir -p .cursor/project/state/{ISO8601-basic}_{task-name}`
- 제목, 설명, completionLevel 설정

### Step 3: user stories 정의

- as/iWant/soThat 형식의 user story 작성
- 각 story에 acceptance criteria를 체크박스 목록으로 추가
- id는 US-001, US-002 형식

### Step 4: 리스크 평가

- Risks 섹션에 테이블로 description, impact(high|medium|low), mitigation 기록

### Step 5: 범위 정의

- In Scope: 이번 작업에 포함되는 항목
- Out of Scope: 제외되는 항목 명시

## prd.md 템플릿

```markdown
# PRD: {Feature Name}

- description: ...
- completionLevel: 3
- createdAt: 2026-02-17T14:30:00Z
- updatedAt: 2026-02-17T14:30:00Z

## User Stories

### US-001: {story title}

- as: 사용자
- iWant: ...
- soThat: ...
- status: pending
- implementedIn: (none)

Acceptance Criteria:

- [ ] AC-1: ...
- [ ] AC-2: ...

### US-002: {story title}

- as: 사용자
- iWant: ...
- soThat: ...
- status: pending
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
- 완료 시 status를 done으로 변경, implementedIn에 관련 파일 경로 추가
- acceptance criteria 체크박스를 `[x]`로 체크
- blocked 시 원인 기록

## autonomous-loop 연동

- autonomous-loop 실행 시 prd.md가 있으면 자동 로드
- User Stories의 Acceptance Criteria 체크박스를 verify 단계의 검증 항목으로 사용
- completionLevel을 ralph-state.md에 반영

## PRD 상태 보고 형식

```
[PRD 상태] {title}
- 완료: N / 총 M user stories
- 진행 중: [US-xxx, ...]
- 대기: [US-xxx, ...]
- Blocked: [US-xxx - 사유]
```
