<!-- source: origin -->

# TM Start

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-start`

선택한 task를 현재 작업으로 시작합니다.

## 목적

- `state.json.currentTaskId` 설정
- 대응하는 `task-folder` 생성
- `autonomous-loop` 또는 수동 작업의 실행 컨텍스트 시작

## 입력

- 필수 `taskId`
- 선택형 `mode` (`ralph` | `autopilot` | `manual`)

## 동작

1. `state/*/task.json`에서 대상 task 존재 여부를 확인합니다.
2. `state.json.currentTaskId`를 설정합니다.
3. task title 기반으로 `task-folder`를 생성합니다.
4. 필요 시 `ralph-state.md`, `notepad.md`, `prd.json`을 연결합니다.
5. 대상 `task.json`의 task metadata에 `taskFolder`를 기록합니다.

## 원칙

- task 선택 책임과 실행 책임을 분리합니다.
- `/tm-start`는 어떤 작업을 시작할지만 결정하고, 실제 반복 제어는 `autonomous-loop`가 담당합니다.
