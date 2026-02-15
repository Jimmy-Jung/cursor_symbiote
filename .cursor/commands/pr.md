<!-- source: origin -->

# PR

현재 브랜치의 변경사항을 분석하고 Pull Request를 생성합니다:

1. `.cursor/rules/project/context.mdc`를 읽어 프로젝트 컨벤션을 파악합니다.
2. `git status`, `git diff`, `git log`으로 변경사항을 분석합니다.
3. `.cursor/skills/merge-request/SKILL.md`를 읽어 PR 컨벤션을 확인합니다.
4. PR 제목과 본문을 생성합니다 (Summary + Test Plan).
5. 브랜치를 push하고 `gh pr create`로 PR을 생성합니다.
