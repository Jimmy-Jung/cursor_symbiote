prd.json을 읽어 작업별 task.json 초안을 생성하거나 갱신합니다.

# TM Parse PRD

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-parse-prd`

## 목적

- 요구사항 문서를 실행 가능한 task graph로 정규화
- `userStories`, `acceptanceCriteria`, `dependsOn`를 task 구조로 변환
- `prd.json`과 `task.json`의 연결 키를 유지

## 입력

- 선택형 `task-folder`
- 선택형 `append`
- 선택형 `tag`

## 동작

1. 대상 `prd.json` 위치를 확인합니다.
2. `.cursor/project/taskmaster/tasks.template.json` 기반으로 `state/{task-folder}/task.json`을 준비합니다.
3. `userStories[]`를 top-level task 또는 subtask 후보로 해석합니다.
4. `dependsOn[]`를 `dependencies[]`로 변환합니다.
5. `acceptanceCriteria[]`를 `testStrategy` 또는 subtask 검증 항목으로 변환합니다.
6. `taskIds[]`를 역참조 키로 기록합니다.

## 실행 스크립트

```bash
bash .cursor/commands/scripts/tm-parse-prd.sh .
```

```bash
bash .cursor/commands/scripts/tm-parse-prd.sh . 2026-03-13T1200_feature
```

```bash
bash .cursor/commands/scripts/tm-parse-prd.sh . 2026-03-13T1200_feature --append
```

## 원칙

- `prd.json`은 원본 요구사항으로 유지합니다.
- `task.json`은 실행용 정규화 결과입니다.
- 변환 과정에서 `taskIds`와 `userStories` 연결을 잃지 않습니다.
