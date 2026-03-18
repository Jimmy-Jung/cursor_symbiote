# PRD Skill

PRD(Product Requirements Document)를 JSON 형식으로 초기화하고 관리합니다.

## 목적

- 복잡한 Feature의 요구사항을 user stories와 acceptance criteria로 정형화
- taskmaster 시스템과 완전 통합 (prd.json → task.json 자동 변환)
- autonomous-loop 연동으로 자율 완료 기준 제공

## 파일 구조

```
.cursor/project/
├── taskmaster/
│   ├── prd.schema.json      # PRD JSON 스키마
│   ├── prd.template.json    # PRD 템플릿
│   └── prd.example.json     # PRD 예시
└── state/{task-folder}/
    ├── prd.json             # 진실의 원천 (source of truth)
    ├── prd.md               # 가독성용 보조 파일 (선택)
    └── task.json            # taskmaster가 사용하는 실행 파일
```

## 워크플로우

1. `/prd` - 사용자 인터뷰 후 prd.json 생성
2. `bash .cursor/skills/prd/scripts/prd-to-md.sh .` - prd.md 생성 (선택)
3. `/tm-parse-prd` - prd.json → task.json 변환
4. `/tm-validate` - 스키마 검증
5. `/tm-start` - 작업 시작

## JSON 우선 설계

- prd.json이 진실의 원천
- 스키마 검증으로 데이터 무결성 보장
- tm-parse-prd.sh가 자동 변환
- prd.md는 협업과 가독성을 위한 보조 파일

## 사용 예시

```bash
# PRD 초기화
Agent: /prd

# 마크다운 생성 (선택)
bash .cursor/skills/prd/scripts/prd-to-md.sh .

# task.json 변환
bash .cursor/commands/scripts/tm-parse-prd.sh .

# 검증
bash .cursor/commands/scripts/tm-validate.sh .
```

## 스키마 핵심 필드

- userStories[]: as/iWant/soThat 형식
- acceptanceCriteria[]: 검증 기준 배열
- status: pending | in_progress | done | blocked
- priority: high | medium | low
- dependsOn[]: 의존성 (다른 US-XXX ID)
- risks[]: description, impact, mitigation
- scope: inScope[], outOfScope[]
