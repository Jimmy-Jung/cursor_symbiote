<!-- source: origin -->

# Plan

analyst + planner 에이전트로 기획 후 Cursor Plan 도구로 최종 계획을 생성합니다:

0. 사용 기록: `bash .cursor/hooks/usage-tracker.sh commands plan`
1. 모드 전환:
   - SwitchMode 도구를 호출하여 Plan 모드로 자동 전환
   - target_mode_id: "plan"
   - explanation: "structured planning workflow with CreatePlan tool"
2. 컨텍스트 로드:
   - `.cursor/rules/project/context.mdc`를 읽어서 프로젝트 컨텍스트 파악
3. Analyze Phase:
   - analyst 에이전트(Task tool, subagent_type: analyst)를 호출하여 요구사항 분석
   - 프롬프트: "사용자 요청: [사용자 입력]. 요구사항을 분석하고 누락된 정보, 범위 리스크, 미검증 가정, 엣지 케이스를 식별하세요."
   - 분석 결과는 메모리에 유지 (파일 저장 X)
4. Plan Phase:
   - planner 에이전트(Task tool, subagent_type: planner)를 호출하여 구현 계획 수립
   - 프롬프트: "사용자 요청: [사용자 입력]. 이전 분석 결과: [analyst 결과]. 구현 계획을 수립하세요."
   - 계획 결과는 메모리에 유지 (파일 저장 X)
5. CreatePlan:
   - analyst + planner 결과를 종합하여 Cursor CreatePlan 도구 호출
   - 파라미터:
     - name: 작업명 (kebab-case)
     - overview: 계획 요약 (1-2 문장)
     - plan: 상세 구현 계획 (마크다운 형식)
     - todos: 실행 가능한 작업 목록 (id, content, status)
6. 완료:
   - 생성된 plan URI를 사용자에게 반환
   - "계획을 확인하고 실행을 승인해주세요."

주의사항:
- task-folder를 생성하지 않습니다 (.cursor/project/state/)
- 중간 md 파일을 저장하지 않습니다 (analysis-report.md, implementation-plan.md, critic-review.md 등)
- 모든 분석과 계획 결과는 메모리에서 처리하고 최종적으로 CreatePlan 도구로만 출력합니다
- Documents/ 폴더에 임시 문서를 저장하지 않습니다
