샌드박스 또는 권한 제약으로 tm-init.sh를 실행할 수 없을 때 사용하는 수동 초기화 절차입니다.

# TM Init Manual

> tracking: `bash .cursor/hooks/usage-tracker.sh commands tm-init-manual`

## 목적

- 스크립트 실행 없이 runtime `state.json`, `config.json`을 준비
- template 기반 초기 상태를 수동으로 확정
- `doctor`의 optional-runtime 경고를 해소

## 절차

1. `.cursor/project/taskmaster/state.template.json`을 기준으로 `state.json` 생성
2. `.cursor/project/taskmaster/config.template.json`을 기준으로 `config.json` 생성
3. 필요 시 `state.json.currentTag`, `config.json.defaults` 값을 프로젝트 상황에 맞게 수정
4. `bash .cursor/skills/doctor/scripts/validate.sh`로 runtime 파일 존재 여부 확인

## 생성 대상

- `.cursor/project/taskmaster/state.json`
- `.cursor/project/taskmaster/config.json`

## 원칙

- template 파일은 초기값의 기준입니다.
- runtime 파일만 수정하고 template 파일은 유지합니다.
- task 파일은 전역 `tasks.json`이 아니라 `.cursor/project/state/{task-folder}/task.json`을 사용합니다.
- 세션 상태 폴더(`.cursor/project/state/*`)는 여기서 생성하지 않습니다.
