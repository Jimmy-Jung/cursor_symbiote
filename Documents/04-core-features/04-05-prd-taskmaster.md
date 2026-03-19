# PRD와 Taskmaster 워크플로우

> 저자: jimmy | 날짜: 2026-03-18

## 개요

PRD(Product Requirements Document) 스킬과 Taskmaster 시스템은 복잡한 Feature를 user stories와 acceptance criteria로 정형화하고, 실행 가능한 task graph로 변환하여 자율 실행 루프와 연동합니다.

## PRD 워크플로우

### /prd 사용법

PRD Mode는 다음 방식으로 활성화됩니다:

- 자연어: "요구사항 정리", "PRD" 키워드 포함
- 스킬 호출: `@prd` 멘션 또는 `/prd` (prd 스킬 연동)

prd 스킬이 로드되면 Analyst 에이전트가 사용자와 인터뷰하여 요구사항을 수집하고, `state/{task-folder}/prd.json`을 생성합니다.

### prd.json 구조

- `userStories[]`: as/iWant/soThat 형식, acceptanceCriteria, dependsOn 포함
- `scope`: inScope, outOfScope
- `risks[]`: 리스크 평가
- 경로: `.cursor/project/state/{task-folder}/prd.json`

## Taskmaster 커맨드

| 커맨드 | 용도 |
|--------|------|
| `/tm-parse-prd` | prd.json을 task graph(task.json)로 변환 |
| `/tm-start <taskId>` | 선택한 task를 현재 작업으로 시작 |
| `/tm-next` | 다음 실행 가능한 task 선택 |
| `/tm-done` | 완료된 task 반영 |
| `/tm-validate` | task.json 스키마 검증 |
| `/tm-board` | task graph 요약 보드 |

### tm-parse-prd

- 입력: prd.json (선택형 task-folder, append, tag)
- 출력: `state/{task-folder}/task.json`
- 변환: userStories → tasks, acceptanceCriteria → testStrategy, dependsOn → dependencies

### tm-start

- 입력: 필수 taskId, 선택형 mode (ralph | autopilot | manual)
- 동작: state.json.currentTaskId 설정, task-folder 생성, autonomous-loop 컨텍스트 시작
- `/tm-start`는 작업 선택만 담당하고, 실제 반복 제어는 autonomous-loop가 수행합니다.

## 전체 파이프라인

```
1. /prd (또는 "요구사항 정리") → prd.json 생성
2. prd-to-md.sh (선택) → prd.md 가독성 보조 파일
3. /tm-parse-prd → prd.json → task.json 변환
4. /tm-validate → 스키마 검증
5. /tm-start <taskId> → task 시작
6. /ralph 또는 /autopilot → 자율 실행 (prd.json의 acceptance criteria로 검증)
```

## autonomous-loop 연동

- task-folder 내 prd.json이 있으면 자동 로드
- userStories[].acceptanceCriteria를 verify 단계의 검증 항목으로 사용
- 모든 AC가 완료될 때까지 루프 진행

## 관련 문서

- [04-02 자율 실행 루프](./04-02-autonomous-loop.md) — Ralph/Autopilot 상세
- [05-데이터 흐름](../05-data-flow.md) — prd.json, task.json 데이터 흐름
- [02-아키텍처](../02-architecture.md) — PRD Mode 트리거
