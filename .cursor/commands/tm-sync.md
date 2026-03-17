<!-- source: origin -->

# TM Sync

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-sync`

세션 실행 상태를 task-folder의 `task.json`에 동기화합니다.

## 목적

- `ralph-state.md`, `notepad.md`, `verify` 결과를 `task.json`에 반영
- 현재 작업의 추천 상태를 `review`, `blocked`, `done` 등으로 제안
- 세션 상태와 task-folder 상태의 드리프트를 줄임

## 입력

- 선택형 `task-folder`
- 선택형 `taskId`

## 동작

1. `state.json.currentTaskId` 또는 명시된 `taskId`를 확인합니다.
2. 대응하는 `task-folder`를 찾습니다.
3. `ralph-state.md`, `notepad.md`, `prd.json`을 읽습니다.
4. `verify-loop`의 요약 형식에 맞춰 추천 상태를 계산합니다.
5. `state/{task-folder}/task.json`의 `status`, `metadata.taskFolder`, `details` 보조 정보를 갱신합니다.

## 원칙

- `notepad.md`는 보조 입력으로만 사용합니다.
- `state/{task-folder}/task.json`이 해당 세션 작업의 진실 원천이며, 세션 메모는 이를 보완할 뿐입니다.
- 자동 동기화 전후의 상태 차이를 요약해 남깁니다.
