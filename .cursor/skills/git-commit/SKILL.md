---
name: git-commit
description: 프로젝트 커밋 컨벤션에 맞는 커밋 메시지 자동 생성. git diff 분석 후 Conventional Commits 형식으로 생성합니다. Use when committing changes or when the user asks to commit.
compatibility:
  - tool: git
    check: command -v git
source: origin
---

# Git Commit

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills git-commit`

프로젝트 커밋 컨벤션에 맞는 커밋 메시지를 자동 생성합니다.

## 참조 룰

Read tool로 읽어 적용: `rules/project/context.mdc` — 프로젝트별 커밋 형식 (있을 경우)

---

## 커밋 타입 표

| 타입 | 설명 | 예시 |
|-----|------|------|
| feat | 새로운 기능 | feat(auth): OAuth2 로그인 플로우 추가 |
| fix | 버그 수정 | fix(parser): null 입력 처리 개선 |
| refactor | 동작 변경 없는 코드 변경 | refactor(api): 에러 핸들러 분리 |
| docs | 문서 변경 | docs: API 레퍼런스 업데이트 |
| test | 테스트 추가/수정 | test(auth): 로그인 단위 테스트 추가 |
| chore | 빌드, 툴링 변경 | chore: 의존성 업그레이드 |
| style | 포맷팅, 공백 (로직 변경 없음) | style: 들여쓰기 수정 |
| perf | 성능 개선 | perf(query): user_id 인덱스 추가 |
| ci | CI 설정 변경 | ci: lint 워크플로우 추가 |
| build | 빌드 시스템 변경 | build: 새 번들러로 마이그레이션 |
| revert | 이전 커밋 되돌리기 | revert: feat(auth) 되돌리기 |

---

## Subject 규칙

- type(scope)는 영어로, subject는 한글로 작성
- 명령형/선언형 어조 (한글: "추가", "수정", "개선" / 영어: add, fix, improve)
- 마침표 없음
- 50자 이내 권장, 72자 절대 한도
- 간결하되 충분히 설명적

예시 형식:
```
feat(auth): 소셜 로그인 기능 추가
fix(parser): 빈 문자열 처리 개선
refactor(api): 응답 변환 로직 분리
```

---

## Body 규칙

- Subject와 본문 사이 빈 줄 필수
- 한글로 작성
- WHY를 설명 (WHAT은 코드가 보여줌)
- 72자마다 줄바꿈 (한글은 36자 정도)
- 관련 이슈/티켓 번호 참조

예시:
```
feat(auth): OAuth2 로그인 플로우 추가

기존 이메일 로그인만으로는 사용자 진입 장벽이 높아
소셜 로그인 옵션을 추가했습니다.

구현 내용:
- Google, GitHub OAuth2 연동
- 기존 계정과 소셜 계정 연결 기능
- JWT 토큰 발급 통합

Closes #123
```

---

## Footer 규칙

- BREAKING CHANGE: 호환성 깨짐 설명
- Closes #issue-number
- Co-authored-by: Name <email>

---

## Scope 컨벤션

- 선택 사항, 모듈/기능명 사용 시 권장
- 예: feat(auth), fix(api), refactor(parser)

---

## Pre-commit 체크

- [ ] 스테이징된 변경 내역 검토 (git diff --cached)
- [ ] 의도치 않은 파일 스테이징 여부 확인
- [ ] 시크릿/자격증명 노출 없음
- [ ] Lint 통과
- [ ] 관련 테스트 통과

---

## 6단계 커밋 워크플로우

1. 스테이징된 변경 검토 (git diff --cached)
2. 변경 내용에서 타입 결정
3. scope 식별 (해당 시)
4. Subject 작성 (명령형, 간결)
5. 필요 시 Body 작성 (복잡한 변경)
6. 필요 시 Footer 추가 (breaking change, 이슈 참조)

---

## 원자적 커밋 원칙

- 하나의 논리적 변경당 하나의 커밋
- 커밋 단위로 독립적으로 이해 가능해야 함
- PR 전 불필요한 커밋은 squash

---

## 메시지 예시 비교

| 나쁜 예시 | 좋은 예시 |
|---------|----------|
| fixed bug | fix(auth): 토큰 만료 처리 개선 |
| Updated stuff. | chore: 의존성 v2.0으로 업데이트 |
| WIP | (WIP 커밋은 PR 전 squash) |
| add | feat(api): 페이지네이션 지원 추가 |
| 수정함 | fix(parser): 빈 입력 처리 개선 |
| feat(auth): 로그인 추가함 | feat(auth): 로그인 기능 추가 |
| fix: fixed the bug | fix(parser): null 참조 오류 수정 |

---

## 워크플로우 (에이전트)

### Step 1: 변경 사항 수집

Shell로 `git status`, `git diff --staged` 실행하여 변경 내용 파악

### Step 2: 변경 분석

무엇이, 왜 변경되었는지, 영향 범위 파악

### Step 3: 컨벤션 확인

프로젝트 context.mdc에 커밋 컨벤션이 있으면 적용. 없으면 위 기본 컨벤션 적용.

### Step 4: 메시지 생성

컨벤션에 맞는 커밋 메시지 생성:
- type(scope)는 영어로 작성
- subject는 한글로 작성 (명령형/선언형)
- body는 한글로 작성 (WHY 중심)
- footer는 영어/한글 혼용 가능

### Step 5: 사전 검사 (선택)

프로젝트에 pre-commit hook(lint, format)이 있으면 실행

### Step 6: 커밋 실행

`git commit` 수행

---

## 안전 사항

- `.env`, `.env.*`, `credentials`, `secrets`, `*.key` 등 민감 정보는 커밋하지 않음
- 경고 패턴 감지 시 사용자에게 확인 요청
