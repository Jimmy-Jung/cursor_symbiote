<!-- source: origin -->

# TM Next

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-next`

현재 실행 가능한 다음 task를 선택합니다.

## 목적

- dependency가 충족된 task 후보를 찾음
- priority와 status를 반영해 다음 작업 제안
- `autonomous-loop` 또는 수동 실행의 시작점 제공

## 입력

- 선택형 `tag`
- 선택형 `status filter`

## 선택 규칙

1. `pending` 또는 `in_progress` 상태만 후보로 봅니다.
2. 모든 dependency가 `done`인 task만 선택 가능합니다.
3. priority 순으로 정렬합니다.
4. 동률이면 dependency 수와 task ID를 기준으로 정렬합니다.

## 원칙

- 탐색 대상의 `state/*/task.json`이 진실 원천입니다.
- `notepad.md`는 선택 사유 보조 입력으로만 사용합니다.
- 선택 결과는 `state.json.lastSelectedTaskId`에 반영할 수 있습니다.
