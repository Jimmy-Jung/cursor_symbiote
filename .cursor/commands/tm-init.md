Task Master형 전역 task graph 상태를 초기화합니다.

# TM Init

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-init`

## 목적

- `.cursor/project/taskmaster/` 초기 상태 생성
- `state.json`, `config.json`을 기본 구조로 준비
- 기존 Symbiote 세션 상태와 분리된 전역 계획 계층 시작

## 입력

- 선택형 `tag`
- 선택형 `completionLevel`
- 선택형 `defaultPriority`
- 선택형 `defaultSubtasks`

## 동작

1. `.cursor/project/taskmaster/` 디렉터리 존재 여부를 확인합니다.
2. 없으면 디렉터리를 생성합니다.
3. schema 파일 존재 여부를 확인합니다.
4. `state.template.json`, `config.template.json`을 기준으로 `state.json`, `config.json`을 생성합니다.
5. 이미 있으면 덮어쓰기 대신 현재 상태를 보여주고 재초기화 여부를 확인합니다.

## 실행 스크립트

```bash
bash .cursor/commands/scripts/tm-init.sh
```

```bash
bash .cursor/commands/scripts/tm-init.sh /path/to/project
```

권한 제약으로 스크립트 실행이 막히면 수동 절차를 사용합니다.

- 수동 절차 문서: `.cursor/commands/tm-init-manual.md`

## 원칙

- schema 파일을 진실 기준으로 사용합니다.
- 템플릿 파일(`*.template.json`)을 초기 상태 복제 원본으로 사용합니다.
- 세션 상태 폴더(`.cursor/project/state/*`)는 건드리지 않습니다.
- 기존 파일이 있으면 파괴적 덮어쓰기를 피합니다.
