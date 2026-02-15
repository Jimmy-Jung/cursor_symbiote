# cursor_symbiote 문서

> 이 문서는 2026-02-16에 생성되었습니다.
> 저자: jimmy
> 프로젝트 버전: 1.0.0

## 이 문서의 목적

cursor_symbiote를 처음 접하는 개발자가 시스템의 구조와 동작 원리를 빠르게 이해할 수 있도록 돕습니다. Cursor IDE의 AI Agent를 전문가 팀처럼 운영하기 위한 자기진화(Self-Evolving) 설정 시스템의 전체 그림을 제공합니다.

## 문서 목록

| 번호 | 문서명 | 설명 | 난이도 |
|-----|-------|------|-------|
| 01 | [프로젝트 개요](./01-project-overview.md) | 프로젝트 목적, 기술 스택, 핵심 개념 | 1 |
| 02 | [아키텍처](./02-architecture.md) | Orchestrator 패턴, 계층 구조, 적용 시점 | 2 |
| 03 | [폴더 구조](./03-folder-structure.md) | 디렉터리별 역할과 파일 설명 | 1 |
| 04-01 | [오케스트레이션](./04-core-features/04-01-orchestration.md) | 4-Phase Workflow, 복잡도별 워크플로우 | 3 |
| 04-02 | [자율 실행 루프](./04-core-features/04-02-autonomous-loop.md) | Ralph Mode, Autopilot Mode, 에스컬레이션 | 3 |
| 04-03 | [자기 진화 메커니즘](./04-core-features/04-03-self-evolution.md) | setup, evolve, doctor, stats 생명주기 | 2 |
| 04-04 | [안전장치와 훅](./04-core-features/04-04-safety-hooks.md) | 6개 훅의 동작 원리와 이벤트 타이밍 | 2 |
| 05 | [데이터 흐름](./05-data-flow.md) | 메시지 처리 흐름, 상태 관리, 에이전트 간 통신 | 2 |
| 06 | [구성 요소 관계](./06-dependencies.md) | Rules-Skills-Agents-Commands-Hooks 관계, 외부 도구 | 2 |
| 07 | [설치 및 적용](./07-build-deploy.md) | 설치, 설정, 테스트, 업그레이드 가이드 | 2 |
| 08 | [온보딩 가이드](./08-onboarding.md) | 신규 사용자 시작 가이드, FAQ | 1 |

## 추천 읽기 순서

1. 첫날: 01 → 03 → 08
2. 첫주: 02 → 05 → 06
3. 심화: 04-01 → 04-02 → 04-03 → 04-04
4. 커스터마이징 시: 07

## 프로젝트 요약

- 타입: AI Agent Configuration System (Self-Evolving)
- 플랫폼: Cursor IDE
- 언어: Markdown, YAML frontmatter, Shell (bash)
- 아키텍처: Orchestrator Pattern (Synapse)
- 구성: Rules 4개 / Commands 9개 / Skills 34개 / Agents 6개+빌트인 / Hooks 6개
- 테스트: 3-Layer (bats 60 tests + validate.sh + manual scenarios)
