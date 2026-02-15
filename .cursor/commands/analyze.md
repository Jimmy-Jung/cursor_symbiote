<!-- source: origin -->

# Analyze

analyst 에이전트로 대상에 대해 심층 분석을 수행합니다:

1. `.cursor/rules/project/context.mdc`를 먼저 읽어 프로젝트 컨텍스트를 파악하세요.
2. analyst 에이전트를 호출하여 분석 대상의 요구사항과 제약사항을 분석합니다.
3. deep-search 스킬을 적용하여 코드베이스를 심층 탐색합니다.
4. 분석 결과를 구조화하여 제시합니다:
   - 누락된 정보 (Missing Questions)
   - 범위 리스크 (Scope Risks)
   - 미검증 가정 (Unvalidated Assumptions)
   - 엣지 케이스 (Edge Cases)
   - 권장 사항 (Recommendations)
5. 필요 시 planner 에이전트로 핸드오프합니다.
