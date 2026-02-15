<!-- source: origin -->

# Review

현재 변경사항에 대해 코드 리뷰를 실행합니다:

1. `.cursor/rules/project/context.mdc`를 읽어 프로젝트 컨벤션을 파악합니다.
2. reviewer 에이전트를 호출하여 코드 품질과 패턴 준수를 분석합니다.
3. manifest.json의 enableSecurityReview가 true이면 security-reviewer subagent도 호출합니다.
4. 결과를 Critical / Warning / Suggestion으로 분류하여 보고합니다.
