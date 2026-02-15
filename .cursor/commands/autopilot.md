<!-- source: origin -->

# Autopilot

4-Phase 워크플로우를 병렬 최대 성능으로 자동 실행합니다.
각 단계의 입출력이 명확하게 정의된 파이프라인이며, 독립 작업은 병렬 에이전트로 동시 처리합니다.

1. `.cursor/rules/project/context.mdc`를 먼저 읽어 프로젝트 컨텍스트를 파악하세요.
2. `.cursor/skills/note/SKILL.md`를 읽어 상태 관리를 준비하세요.

## Task-Folder 초기화

Pipeline 시작 전 작업별 state 폴더를 생성합니다:
- 폴더: `.cursor/project/state/{ISO8601-basic}_{task-name}/`
- 예시: `mkdir -p .cursor/project/state/2026-02-13T1430_login-feature`
- 시각은 현재 시각, task-name은 작업 설명에서 kebab-case로 추출

## Pipeline

### Phase 0: Analyze (입력: 사용자 요구사항 → 출력: 정제된 요구사항)
- analyst 에이전트로 요구사항을 분석합니다.
- 병렬로 deep-search 스킬로 코드베이스를 탐색합니다.
- 출력: 누락 정보, 범위 리스크, 가정, 엣지 케이스 리스트
- task-folder의 notepad.md에 분석 결과를 기록합니다.

### Phase 1: Plan (입력: 정제된 요구사항 → 출력: 검증된 구현 계획)
- planner 에이전트로 계획을 수립합니다.
- critic 에이전트로 계획을 검증합니다.
- 필요 시 architect subagent로 아키텍처를 결정합니다.
- 출력: 단계별 구현 계획, 의존성, 검증 기준, 리스크
- task-folder의 notepad.md에 계획을 기록합니다.

### Phase 2: Execute (입력: 검증된 계획 → 출력: 구현된 코드)
- implementer 에이전트로 계획을 구현합니다.
- 독립 작업은 병렬로 실행합니다 (최대 4 에이전트).
- UI 작업은 designer subagent에 위임합니다.
- 빌드 오류 발생 시 build-fixer subagent로 즉시 수정합니다.
- 단계 완료 시마다 TODO를 업데이트합니다.

### Phase 3: Verify (입력: 구현된 코드 → 출력: 검증 리포트)
- reviewer와 qa-tester subagent를 병렬 실행하여 검증합니다.
- verify-loop 4-Level 기준에 따라 검증합니다.
- 보안 요구사항이 있으면 security-reviewer subagent도 병렬 실행합니다.

### Loop (실패 시)
- 검증 실패 시 Phase 2로 회귀합니다 (최대 3회).
- 동일 오류 2회 연속 시 접근 방식을 변경합니다.
- 3회 후 미해결 시 사용자에게 에스컬레이션합니다.

### Post-Pipeline (선택)
- "문서화까지" 키워드 시: doc-writer subagent로 문서 생성
- "커밋까지" 키워드 시: git-commit 스킬로 커밋 생성
- 알림 채널이 있으면 완료 알림 전송
- 완료 후 `/clean` 커맨드로 task-folder 정리 가능
