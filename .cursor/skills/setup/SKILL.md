---
name: setup
description: 프로젝트 부트스트랩. 코드베이스를 분석하여 프로젝트 스택을 감지하고, manifest.json과 context.mdc를 자동 생성합니다. 새 프로젝트에 .cursor를 처음 적용할 때 사용합니다. Use when initializing .cursor configuration for a new project.
disable-model-invocation: true
source: origin
---

# Setup Skill

프로젝트 부트스트랩 Skill. 코드베이스를 분석하여 프로젝트 스택을 감지하고, manifest.json과 context.mdc를 자동 생성합니다. 새 프로젝트에 .cursor를 처음 적용할 때 사용합니다.

## 진입 조건 (Entry Condition)

`.cursor/project/manifest.json`이 존재하지 않을 때만 실행합니다. 이미 존재하면 setup을 건너뛰고 /evolve를 사용하도록 안내합니다.

## 워크플로우

### Step 0: 환경 준비 (Environment Preparation)

- `.cursor/hooks/*.sh` 파일에 실행 권한 부여: `chmod +x .cursor/hooks/*.sh`
- `.cursor/project/usage-data/` 내부 기존 데이터 초기화 (씨앗에서 이전 프로젝트 데이터가 남아있을 수 있음)
- `.cursor/project/usage-data/`에 5개 카테고리 디렉터리 생성: skills, commands, agents, subagents, system-skills
- `.cursor/project/usage-data/.tracked-since`에 현재 ISO8601 타임스탬프 기록

### Step 1: 프로젝트 감지 (Project Detection)

Glob, Grep, Read를 병렬로 실행하여 프로젝트 스택을 종합 분석합니다.

#### Track A — 언어 감지 (Language Detection)

- Glob으로 파일 확장자 검색: `*.swift`, `*.kt`, `*.ts`, `*.tsx`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.rb`, `*.cs`, `*.cpp`, `*.c`, `*.m`, `*.h`
- 확장자별 파일 수 카운트
- primary/secondary 언어 결정 (예: Swift 85%, Objective-C 15%)

#### Track B — 패키지 매니저 감지 (Package Manager Detection)

- SPM: `Package.swift`
- Node: `package.json` (npm/yarn/pnpm)
- Python: `requirements.txt`, `pyproject.toml`
- Gradle: `build.gradle`, `build.gradle.kts`
- Rust: `Cargo.toml`
- Go: `go.mod`
- Ruby: `Gemfile`
- C#: `*.csproj`
- iOS: `Podfile`, `Cartfile`

#### Track C — 프레임워크 감지 (Framework Detection)

- Grep import: `import UIKit`, `import SwiftUI`, `import React`, `from 'react'`, `import django`, `import flask`, `import express` 등
- Grep 프레임워크별 패턴 (예: `@StateObject`, `createStore`, `Flux`, `Redux`)

#### Track D — 아키텍처 감지 (Architecture Detection)

- 아키텍처 패턴 검색: Store/Worker, MVVM, MVC, Redux, Flux, Clean Architecture, VIPER, TCA
- 폴더 구조 힌트: `/features/`, `/domain/`, `/data/`, `/presentation/`, `/components/`, `/views/`, `/models/`

#### Track E — CI/CD 감지

- `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`, `bitrise.yml`, `fastlane/`

#### Track F — 빌드 도구 감지

- Tuist: `Project.swift`
- Xcode: `*.xcodeproj`
- Web: `webpack`, `vite`, `next.config`, `turbo.json`, `nx.json`

### Step 1.5: 이전 버전 감지 (Previous Version Detection)

프로젝트 감지와 병렬로, `.cursor.back` 디렉터리 존재 여부를 확인합니다.

#### 감지

- Glob으로 `.cursor.back/` 디렉터리 존재 여부 확인
- 존재하지 않으면 Step 2로 진행 (클린 설치)

#### 사용자 확인

`.cursor.back`이 존재하면 사용자에게 질문:

```
이전 버전 .cursor.back이 감지되었습니다.
기존 설정을 기반으로 새 환경을 구성할까요?

- "예": 이전 설정을 분석하여 커스텀 파일을 이관합니다
- "아니오": 클린 설치로 진행합니다
```

"아니오" 응답 시 Step 2로 진행합니다.

#### 이전 설정 분석 (Legacy Config Analysis)

"예" 응답 시, `.cursor.back`의 다음 항목을 Read/Glob으로 분석합니다:

| 경로 | 추출 대상 |
|------|-----------|
| `rules/project/context.mdc` | 프로젝트 컨텍스트, 코딩 컨벤션 |
| `project/manifest.json` | 프로젝트 스택, 기본 설정값 |
| `rules/project/*.mdc` | 프로젝트별 커스텀 룰 |
| `rules/kernel/*.mdc` | 커널 룰 |
| `skills/*/SKILL.md` | 스킬 |
| `agents/*.md` | 에이전트 정의 |
| `hooks.json` + `hooks/*.sh` | 훅 설정 |
| `commands/*.md` | 커맨드 |

각 파일을 origin/custom으로 분류합니다.
분류 시 `.cursor.back`의 파일에 `source: origin` 태그가 있는지 확인하고, 새 `.cursor`의 동일 경로 파일과 내용을 비교합니다:

| 기준 | source | 처리 |
|------|--------|------|
| 새 `.cursor`에 동일 경로로 존재 + `source: origin` 태그 + 내용 동일 | `origin` | 새 버전 사용 (이관 스킵) |
| 새 `.cursor`에 동일 경로로 존재 + `source: origin` 태그 + 내용 다름 | `origin (modified)` | 새 버전을 존중하되, 사용자 수정 사항을 보고 |
| 새 `.cursor`에 없는 파일 | `custom` | 이관 대상 |

`origin (modified)` 감지 방법:
- `.cursor.back`의 파일에 `source: origin` 태그가 있음 (원래 번들 파일)
- 새 `.cursor`의 동일 경로 파일과 내용을 비교하여 차이가 있음
- 사용자가 origin 파일을 커스터마이징한 것으로 판단
- 새 버전의 origin을 항상 존중 (사용자 수정은 덮어씀)

분석 결과를 사용자에게 보고합니다:

```
이전 설정 분석 결과:
- 프로젝트: [name] ([type])
- origin (새 버전으로 대체): N개
- origin (사용자 수정 감지, 새 버전으로 대체): N개
  - skills/code-accuracy/SKILL.md (수정됨)
  - rules/kernel/synapse.mdc (수정됨)
  주의: 이전 버전에서 수정한 내용은 새 버전에 반영되지 않습니다.
  수정했던 파일은 .cursor/project/history/modified-origins/ 에 백업됩니다.
  수정 내용을 유지하려면, 이관 후 해당 파일을 직접 수정하세요.
- custom (이관 대상):
  - 룰: N개 (rules/project/ios-conventions.mdc, ...)
  - 스킬: N개 (skills/smartplayer-feature, ...)
  - 에이전트: N개 (agents/ios-explorer.md, ...)
  - 훅: N개
  - 커맨드: N개

이관을 진행할까요?
```

#### 이전 설정 이관 (Legacy Config Migration)

사용자가 이관을 승인하면:

1. `origin (modified)` 파일의 이전 버전(사용자가 수정한 버전)을 `.cursor/project/history/modified-origins/`에 참고용으로 백업 (새 버전의 origin은 그대로 유지)
2. custom 파일을 새 `.cursor`로 복사
3. 이전 `context.mdc`에서 프로젝트 컨텍스트, 코딩 컨벤션을 추출하여 Step 4에서 새 `context.mdc` 생성 시 반영
4. 이전 `manifest.json`에서 `defaults`, `project`, `stack` 정보를 Step 3에서 새 manifest 생성 시 seed로 활용
5. 용어 변경 자동 적용 (예: `ultrawork` → `autopilot`)
6. 호환성 문제가 있는 파일은 경고 출력 후 사용자에게 수동 확인 요청
7. `origin (modified)` 파일이 있었다면, 백업 경로와 수정했던 파일 목록을 안내하여 필요시 수동으로 재적용할 수 있도록 함

이관 완료 후 Step 2로 진행합니다 (추가 스킬팩 첨부 기회 제공).

### Step 2: 플랫폼별 스킬팩 / 참고자료 요청

프로젝트 스택 감지 결과를 사용자에게 보여준 뒤, 다음을 질문합니다:

```
감지된 프로젝트 스택: [언어], [프레임워크], [아키텍처]

이 프로젝트에 적용할 플랫폼별 스킬팩이나 참고할 코딩 가이드/룰 파일이 있으면 첨부해주세요.
(예: 기존 .cursor/rules 파일, 코딩 컨벤션 문서, 아키텍처 가이드 등)

첨부 없이 진행하면 범용 스킬만으로 구성합니다.
```

사용자 응답에 따른 분기:

| 응답 | 처리 |
|-----|------|
| 파일 첨부됨 | 첨부된 파일을 분석하여 `.cursor/skills/` 하위에 프로젝트 특화 스킬 생성, context.mdc에 해당 스킬 경로 등록 |
| 참고 자료 URL 제공 | WebFetch/Scrape로 내용을 수집하여 스킬 생성 |
| "없음" 또는 스킵 | 범용 스킬만으로 진행 (추후 /evolve로 추가 가능) |

첨부 파일 기반 스킬 생성 시:
- 첨부 파일의 내용을 분석하여 핵심 규칙, 패턴, 체크리스트 추출
- `.cursor/skills/{project-name}/SKILL.md` 형태로 프로젝트 특화 스킬 생성
- YAML frontmatter에 name, description 포함
- 500줄 이하로 유지
- context.mdc의 활성 스킬 목록에 추가

### Step 3: manifest.json 생성

`.cursor/project/manifest.json`에 다음 구조로 작성:

```json
{
  "version": "1.0.0",
  "kernelVersion": "1.0.0",
  "created": "ISO8601",
  "lastEvolved": "ISO8601",
  "moltCount": 0,
  "defaults": {
    "completionLevel": 2,
    "maxRalphIterations": 10,
    "enableSecurityReview": false,
    "enableQA": true
  },
  "project": {
    "name": "auto-detected",
    "type": "mobile-app|web-app|library|cli|monorepo|backend",
    "languages": ["detected..."],
    "platforms": ["detected..."]
  },
  "stack": {
    "packageManager": "detected",
    "buildTool": "detected",
    "frameworks": ["detected..."],
    "libraries": ["detected..."],
    "architecture": "detected",
    "testFramework": "detected",
    "cicd": "detected"
  },
  "activated": {
    "rules": [
      {"path": "rules/kernel/synapse.mdc", "source": "origin"}
    ],
    "skills": [
      {"path": "skills/code-accuracy", "source": "origin"}
    ],
    "agents": [
      {"path": "agents/implementer.md", "source": "origin"}
    ],
    "commands": [
      {"path": "commands/ralph.md", "source": "origin"}
    ],
    "hooks": [
      {"path": "hooks/setup-check.sh", "source": "origin"}
    ]
  },
  "evolution": {
    "history": [
      {"version": "1.0.0", "date": "...", "type": "initial-setup", "description": "Initial project setup"}
    ]
  }
}
```

- `project.type`: mobile-app, web-app, library, cli, monorepo, backend 중 감지 결과에 맞게 설정
- `platforms`: iOS, Android, Web, macOS 등

#### source 태그 부여 규칙

`activated` 섹션의 모든 항목에 `source` 필드를 부여합니다:

| source 값 | 의미 | 대상 |
|-----------|------|------|
| `origin` | 새 `.cursor`에 기본 포함된 번들 파일 | 커널 룰, 기본 스킬, 기본 에이전트, 기본 커맨드, 기본 훅 |
| `custom` | 사용자가 생성했거나 `.cursor.back`에서 이관한 파일 | 프로젝트별 룰, 프로젝트 특화 스킬, 커스텀 에이전트/커맨드/훅 |

setup이 프로젝트 감지로 자동 생성하는 파일도 `custom`으로 태그합니다:
- `rules/project/context.mdc` → `custom`
- `rules/project/platform.mdc` → `custom`
- `skills/{project-name}/SKILL.md` → `custom`

활용:
- `/help`: 목록에서 `[origin]`/`[custom]` 레이블 표시
- `/evolve`: `origin` 파일만 안전하게 업그레이드, `custom`은 보존
- `/doctor`: `origin` 파일 누락 감지, `custom` 파일 호환성 검사

### Step 4: context.mdc 생성

`.cursor/rules/project/context.mdc` 작성 (frontmatter `alwaysApply: true`):

- 프로젝트 스택 요약
- 활성화된 rule 경로
- 에이전트 커스터마이즈 정보
- 기존 코드에서 추출한 코딩 컨벤션
- 파일 네이밍 패턴
- 모든 에이전트가 최우선으로 읽는 프로젝트 컨텍스트 파일

### Step 5: 프로젝트별 규칙 생성 (선택)

감지된 스택에 따라 `.cursor/rules/project/`에 추가 규칙 생성:

- `platform.mdc` — 언어/플랫폼 컨벤션 (파일 확장자별 glob 적용)
- `framework.mdc` — 프레임워크별 패턴 (해당 시)
- `architecture.mdc` — 아키텍처 패턴 (감지 시)

감지된 스택과 기존 코드베이스 컨벤션을 기반으로 AI가 생성합니다.

### Step 6: VERSION 파일

`.cursor/project/VERSION`에 `1.0.0` 기록

### Step 7: 초기 히스토리

`.cursor/project/history/v1.0-initial-setup.md` 작성:

- 감지된 항목
- 생성된 파일 목록
- evolve 권장 시점 및 후속 조치

### Step 8: 리포트

사용자에게 setup 요약 출력:

- 감지된 스택 (언어, 프레임워크, 아키텍처, CI/CD 등)
- 생성된 파일 경로
- 다음 단계 권장 (/evolve, /deep-index 등)

## deep-index 연동

- setup 완료 후 deep-index Skill 실행 권장
- codebase-index.md 생성 시 context.mdc 보강에 활용

## evolve 연동

- setup 완료 후 manifest.json이 존재하므로, 이후 프로젝트 변경 시 /evolve 사용
