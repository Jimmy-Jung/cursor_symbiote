# cursor_symbiote — 5분 가이드

Cursor IDE의 AI Agent를 전문가 팀처럼 운영하는 자기진화(Self-Evolving) 설정 시스템입니다.
`.cursor/` 폴더 하나로 16개 에이전트, 35개 스킬, 10개 커맨드가 자동 조율됩니다.

## 설치

```bash
# 1. .cursor/ 폴더를 프로젝트 루트에 복사 후:
chmod +x .cursor/hooks/*.sh

# 2. Cursor 채팅에서:
/setup
```

코드베이스를 자동 분석하여 프로젝트 스택을 감지하고 `manifest.json`과 `context.mdc`를 생성합니다.

## 핵심 커맨드

| 커맨드 | 용도 |
|--------|------|
| `/autopilot {작업}` | 분석→기획→구현→검증 자동 파이프라인 (병렬 최대 성능) |
| `/ralph {작업}` | 완료까지 자율 반복 (최대 10회) |
| `/plan {작업}` | 계획 세션 (분석→기획→검증) |
| `/review` | 코드 리뷰 |
| `/pr` | PR 생성 |
| `/solid-review` | SOLID 원칙 분석 및 리팩토링 제안 |
| `/stats` | 사용 빈도 분석, 미사용 항목 추천 |

## 자연어로도 동작합니다

```
"로그인 화면을 만들어줘"         → 적절한 에이전트 자동 조율
"끝까지 결제 모듈 완성해"        → Ralph Mode (자율 완료)
"autopilot 대규모 리팩토링"      → 병렬 에이전트 자율 파이프라인
"심층 분석해줘 인증 로직"        → deep-search 자동 활성화
"보안 포함해서 API 리팩토링"     → 보안 리뷰 자동 포함
"eco 모드로 버그 수정해줘"       → 토큰 절약 모드
도움말                          → 전체 기능 목록
```

## 자동으로 동작하는 안전장치

직접 호출하지 않아도 자동 적용됩니다:

- 코드 작성 시 → 심볼 검증, import 확인, 환각 방지
- Shell 명령 전 → `git push --force` 등 위험 명령 차단
- 파일 편집 후 → 불필요한 AI 주석 감지
- Git 커밋 시 → Conventional Commits 메시지 자동 생성

## 유지 관리

| 시점 | 명령 |
|------|------|
| 최초 1회 | `/setup` |
| 의존성/구조 변경 후 | `/evolve` |
| 뭔가 이상할 때 | `/doctor` |
| 사용 통계 확인 | `/stats` |

## 문서

- 상세 문서: [README.md](README.md)
- 아키텍처/기능별 문서: [Documents/](Documents/00-TOC.md)
