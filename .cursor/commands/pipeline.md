<!-- source: origin -->

# Pipeline

에이전트를 순차적으로 체이닝하여 작업을 실행합니다.
사용자가 지정한 에이전트들을 순서대로 호출하며, 이전 에이전트의 결과를 다음 에이전트에 전달합니다.

예시: /pipeline analyst → planner → implementer → reviewer

1. `.cursor/rules/project/context.mdc`를 먼저 읽어 프로젝트 컨텍스트를 파악하세요.
2. 각 에이전트를 순서대로 Task tool로 호출합니다.
3. 이전 에이전트의 출력을 다음 에이전트의 입력으로 전달합니다.
4. Critical 이슈 발생 시 중단하고 사용자에게 보고합니다.
