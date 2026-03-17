Task Master형 상태의 구조와 정합성을 검사합니다.

# TM Validate

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-validate`

## 목적

- schema 기준 구조 오류 탐지
- dependency cycle, missing reference, orphan 상태 탐지
- task graph와 세션 상태 연결 이상 확인

## 검사 대상

- `.cursor/project/taskmaster/state.json`
- `.cursor/project/taskmaster/config.json`
- `.cursor/project/state/*/task.json`
- 선택형 `.cursor/project/state/*/ralph-state.md`
- 선택형 `.cursor/project/state/*/notepad.md`

## 주요 체크

1. 필수 파일 존재 여부
2. schema 기준 필수 키 존재 여부
3. 각 `task.json`의 필수 키/배열 구조 유효성
4. dependency가 같은 `task.json` 내 실제 task를 가리키는지
5. `currentTaskId`가 `state/*/task.json` 중 하나의 task와 일치하는지
6. task metadata의 `taskFolder`가 실제 세션 폴더와 연결되는지

## 실행 스크립트

```bash
bash .cursor/commands/scripts/tm-validate.sh
```

```bash
bash .cursor/commands/scripts/tm-validate.sh /path/to/project
```

## 원칙

- task graph가 비활성 상태면 FAIL이 아니라 "not initialized"로 보고합니다.
- setup 전 상태와 optional extension 비활성 상태를 구분해 출력합니다.
- JSON 문법, 필수 키, dependency 참조, `currentTaskId` 정합성을 최소 검사합니다.
- 전역 `tasks.json`이 있으면 legacy runtime으로 WARN을 출력합니다.
