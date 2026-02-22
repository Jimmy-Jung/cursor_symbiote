<!-- source: origin -->

# Plan

analyst + planner 에이전트로 기획 세션을 시작합니다:

0. 사용 기록: `bash .cursor/hooks/usage-tracker.sh commands plan`
1. `.cursor/rules/project/context.mdc`를 먼저 읽어 프로젝트 컨텍스트를 파악하세요.
2. Task-Folder 초기화:
   - 현재 시각을 ISO8601 basic 형식으로 생성 (예: `20260222T1430`)
   - 사용자 요청에서 task-name을 kebab-case로 추출 (예: `feature-planning`)
   - task-folder 생성: `mkdir -p .cursor/project/state/{timestamp}_{task-name}`
   - plan-state.md 초기화 (Write tool 사용):
     ```markdown
     # Plan State

     - active: true
     - phase: analyze
     - taskDescription: [사용자 요청 요약]
     - startedAt: [ISO 8601 timestamp]
     - prdPath: none

     ## 작업 범위

     (사용자 요청 내용)

     ## 실행 이력
     ```
3. Phase: Analyze
   - analyst 에이전트를 호출하여 요구사항을 분석하고 정제합니다.
   - 분석 완료 후 plan-state.md 업데이트 (StrReplace tool 사용):
     - `phase: analyze` 유지
     - 실행 이력에 추가: `- [1] phase: analyze | agent: analyst | result: [요약] | action: plan`
4. Phase: Plan
   - planner 에이전트를 호출하여 구현 계획서를 작성합니다.
   - 계획 완료 후 plan-state.md 업데이트:
     - `phase: plan`으로 변경
     - 실행 이력에 추가: `- [2] phase: plan | agent: planner | result: [요약] | action: review`
5. Phase: Review
   - critic 에이전트를 호출하여 계획을 검토합니다.
   - 검토 완료 후 plan-state.md 업데이트:
     - `phase: review`로 변경
     - 실행 이력에 추가: `- [3] phase: review | agent: critic | result: [승인/거부] | action: [complete/revise]`
6. Complete
   - 검토 결과를 사용자에게 제시합니다.
   - plan-state.md 최종 업데이트:
     - `active: false`로 변경
     - `phase: complete`로 변경

note 스킬을 활용하여 추가 메모가 필요하면 같은 task-folder 내 notepad.md를 사용할 수 있습니다.
