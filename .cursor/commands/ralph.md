<!-- source: origin -->

# Ralph Loop

완료까지 멈추지 않는 자기참조 자율 실행 루프를 시작합니다:

1. `.cursor/rules/project/context.mdc`를 먼저 읽어 프로젝트 컨텍스트를 파악하세요.
2. `.cursor/skills/autonomous-loop/SKILL.md`를 읽어 Ralph 모드 워크플로우를 적용하세요.
3. task-folder를 생성합니다: `mkdir -p .cursor/project/state/{ISO8601-basic}_{task-name}`
4. task-folder 내에 상태 파일을 초기화합니다.
5. Analyze: analyst 에이전트로 요구사항을 분석합니다.
6. Plan: planner + critic 에이전트로 계획을 수립하고 검증합니다.
7. Execute: implementer 에이전트로 구현합니다.
8. Verify: 완료 레벨에 따라 검증합니다 (verify-loop 4-Level 기준).
9. Loop: 미충족 시 수정 후 Execute로 복귀합니다. maxIterations까지 반복합니다.
10. 완료 시 ralph-state.md의 active를 false로 변경하고 로그를 작성합니다.

취소하려면 cancel 스킬을 호출하세요.
완료 후 `/clean` 커맨드로 task-folder를 정리할 수 있습니다.
