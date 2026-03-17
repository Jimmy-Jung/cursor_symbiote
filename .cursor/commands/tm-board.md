state/*/task.json 기준 task graph를 상태별로 요약해 보여줍니다.

# TM Board

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-board`

## 목적

- 현재 backlog와 진행 상황을 빠르게 파악
- `next` 선택 전에 전체 상태를 점검
- `blocked`, `review`, `done`의 비율과 병목 확인

## 입력

- 선택형 `tag`
- 선택형 `status`

## 출력 항목

- 전체 task 수
- 상태별 개수
- 현재 `currentTaskId`
- 현재 `currentTaskId`가 속한 `task-folder`
- `blocked` task 목록
- 실행 가능한 `pending` 후보

## 원칙

- task graph가 없으면 FAIL이 아니라 "not initialized"를 반환합니다.
- 보드 출력은 상태 요약이며, 세부 수정은 각 `/tm-*` command가 담당합니다.
