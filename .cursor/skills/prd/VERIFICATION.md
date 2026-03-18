# PRD + Taskmaster 통합 검증

이 문서는 prd 스킬이 taskmaster 시스템과 올바르게 통합되었는지 검증합니다.

## 파일 구조 검증

```bash
# taskmaster 폴더에 필요한 파일들이 존재하는가?
ls -l .cursor/project/taskmaster/prd.*

# 예상 출력:
# prd.schema.json    - JSON 스키마
# prd.template.json  - 빈 템플릿
# prd.example.json   - 사용자 인증 예시
```

## 스키마 검증

```bash
# prd.example.json이 prd.schema.json을 만족하는가?
jq -e 'if .version and .title and .description and .userStories then "VALID" else "INVALID" end' \
  .cursor/project/taskmaster/prd.example.json
```

## 변환 테스트

```bash
# 1. 테스트용 state 폴더 생성
mkdir -p .cursor/project/state/test_prd_integration

# 2. 예시 prd.json 복사
cp .cursor/project/taskmaster/prd.example.json \
   .cursor/project/state/test_prd_integration/prd.json

# 3. tm-parse-prd.sh 실행
bash .cursor/commands/scripts/tm-parse-prd.sh . test_prd_integration

# 4. 결과 확인
ls -l .cursor/project/state/test_prd_integration/

# 예상 출력:
# prd.json   - 원본
# task.json  - 변환된 파일

# 5. task.json 내용 검증
jq '.tasks | length' .cursor/project/state/test_prd_integration/task.json
# 예상: 3 (US-001, US-002, US-003)

jq '.tasks[0] | {id, title, status, priority, testStrategy}' \
  .cursor/project/state/test_prd_integration/task.json
# 예상: id="1", status="pending", testStrategy에 acceptance criteria 포함

# 6. 정리
rm -rf .cursor/project/state/test_prd_integration
```

## prd-to-md 변환 테스트

```bash
# 1. 테스트용 폴더 생성
mkdir -p .cursor/project/state/test_prd_md

# 2. 예시 prd.json 복사
cp .cursor/project/taskmaster/prd.example.json \
   .cursor/project/state/test_prd_md/prd.json

# 3. prd-to-md.sh 실행
bash .cursor/skills/prd/scripts/prd-to-md.sh . test_prd_md

# 4. 결과 확인
ls -l .cursor/project/state/test_prd_md/
cat .cursor/project/state/test_prd_md/prd.md

# 예상: 마크다운 형식으로 user stories, risks, scope 표시

# 5. 정리
rm -rf .cursor/project/state/test_prd_md
```

## 통합 워크플로우 검증

```bash
# 전체 파이프라인 테스트
mkdir -p .cursor/project/state/test_full_pipeline
cp .cursor/project/taskmaster/prd.example.json \
   .cursor/project/state/test_full_pipeline/prd.json

# 단계 1: prd.md 생성
bash .cursor/skills/prd/scripts/prd-to-md.sh . test_full_pipeline

# 단계 2: task.json 생성
bash .cursor/commands/scripts/tm-parse-prd.sh . test_full_pipeline

# 단계 3: 스키마 검증 (tm-validate가 있다면)
# bash .cursor/commands/scripts/tm-validate.sh . test_full_pipeline

# 결과 확인
ls -l .cursor/project/state/test_full_pipeline/
# 예상: prd.json, prd.md, task.json

# 정리
rm -rf .cursor/project/state/test_full_pipeline
```

## 검증 체크리스트

- [x] prd.schema.json 생성
- [x] prd.template.json 생성
- [x] prd.example.json 생성
- [x] prd 스킬 SKILL.md 업데이트 (JSON 우선)
- [x] prd-to-md.sh 스크립트 생성
- [x] prd 스킬 README.md 추가
- [x] tm-parse-prd.sh와 prd.json 호환성 확인
- [ ] 실제 /prd 커맨드 실행 테스트 (사용자가 수행)
- [ ] autonomous-loop 연동 테스트 (사용자가 수행)

## 다음 단계

1. 사용자가 `/prd` 커맨드를 실행하여 실제 prd.json 생성 테스트
2. `/tm-parse-prd` 실행으로 task.json 변환 확인
3. `/tm-start`로 첫 번째 task 시작 확인
4. autonomous-loop와의 연동 검증

## 알려진 제약사항

- tm-parse-prd.sh는 jq가 설치되어 있어야 함
- prd-to-md.sh도 jq 필요
- ISO 8601 날짜 형식 준수 필요 (YYYY-MM-DDTHH:MM:SSZ)
- user story ID는 US-001 형식 (3자리 숫자) 고정
