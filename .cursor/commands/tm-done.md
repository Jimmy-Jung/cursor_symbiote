작업 완료를 대응 task.json에 반영합니다.

# TM Done

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-done`

## 목적

- task status를 `done`으로 변경
- `currentTaskId`를 해제
- 후속 dependency 후보를 다시 계산할 수 있게 함

## 입력

- 필수 `taskId`
- 선택형 `summary`

## 동작

1. 대상 task 존재 여부를 확인합니다.
2. verify 결과나 완료 근거 요약을 수집합니다.
3. 대응 `state/{task-folder}/task.json`의 task status를 `done`으로 변경합니다.
4. `state.json.currentTaskId`가 동일하면 null로 변경합니다.
5. 필요 시 `notepad.md`와 `ralph-state.md` 종료 상태를 함께 기록합니다.

## 원칙

- 검증 근거 없이 기계적으로 완료 처리하지 않습니다.
- 가능하면 `verify-loop`의 Level 또는 요약을 함께 남깁니다.
