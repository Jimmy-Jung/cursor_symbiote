# .cursor 설정 검증 테스트

> 저자: jimmy
> 날짜: 2026-02-12

.cursor 디렉터리의 훅 스크립트, 구조 무결성, 에이전트/스킬 행동을 검증하는 테스트 모음입니다.

## 구조

```
tests/
├── README.md                  # 이 파일
├── run-all.sh                 # 통합 테스트 러너
├── scenarios.md               # Layer 3: 수동 검증 시나리오
├── hooks/                     # Layer 1: 훅 스크립트 단위 테스트
│   ├── setup-check.bats
│   ├── guard-shell.bats
│   ├── recovery.bats
│   ├── todo-continuation.bats
│   └── comment-checker.bats
└── fixtures/                  # 테스트 데이터
    ├── ralph-state-active.md
    ├── ralph-state-inactive.md
    ├── sample-code-many-comments.swift
    └── sample-code-clean.swift
```

## 의존성

- [bats-core](https://github.com/bats-core/bats-core): 쉘 스크립트 테스트 프레임워크
- jq (선택): JSON 파싱 보조

```bash
brew install bats-core jq
```

## 실행 방법

### 전체 테스트 실행

프로젝트 루트에서:

```bash
bash .cursor/tests/run-all.sh
```

### 개별 훅 테스트 실행

```bash
# 프로젝트 루트에서 실행
bats .cursor/tests/hooks/guard-shell.bats
bats .cursor/tests/hooks/setup-check.bats
```

### Layer 2: 구조 검증만 실행

```bash
bash .cursor/skills/doctor/scripts/validate.sh
```

## 3-Layer 검증 체계

| Layer | 유형 | 자동화 | 설명 |
|-------|------|--------|------|
| Layer 1 | 훅 스크립트 단위 테스트 | 자동 (bats) | 5개 훅의 입출력을 60개 케이스로 검증 |
| Layer 2 | 구조 검증 스크립트 | 자동 (validate.sh) | frontmatter, 경로 참조, 스키마 유효성 검사 |
| Layer 3 | 시나리오 체크리스트 | 수동 | 에이전트/스킬 행동 24개 시나리오 수동 확인 |

## 테스트 케이스 요약

### Layer 1: 훅 스크립트 (60 tests)

| 훅 | 테스트 수 | 검증 내용 |
|----|-----------|-----------|
| setup-check.sh | 6 | manifest.json/ralph-state.md 상태별 출력 |
| guard-shell.sh | 23 | 위험 명령 차단, 안전 명령 허용, 엣지 케이스 |
| recovery.sh | 10 | 도구별 에러 복구 메시지, 비매칭 도구 무시 |
| todo-continuation.sh | 10 | Ralph Loop 활성 시 TODO 연속 알림 |
| comment-checker.sh | 11 | 파일 타입 필터링, 주석 패턴 탐지 |

### Layer 2: 구조 검증

- hooks.json 구조 및 스크립트 참조
- 에이전트 frontmatter (name, description, model)
- 스킬 frontmatter (name, description, 폴더명 일치)
- 커맨드 형식 (frontmatter 없음 확인)
- manifest.json 스키마 (존재 시)
- 경로 참조 무결성

### Layer 3: 시나리오 체크리스트

scenarios.md 참조. 에이전트 초기화, 스킬 활성화, 훅 트리거, 모드 감지, 워크플로우 등 24개 시나리오.
