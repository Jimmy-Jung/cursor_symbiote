---
name: xcodebuildmcp
description: XcodeBuildMCP 기반 iOS/macOS/watchOS/tvOS/visionOS 작업 가이드입니다. Use when doing Apple platform work with XcodeBuildMCP for build, test, run, debug, log, or UI automation.
source: origin
---

# XcodeBuildMCP

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills xcodebuildmcp`

XcodeBuildMCP 도구가 있을 때는 raw `xcodebuild`, `xcrun`, `simctl`보다 우선 사용합니다.

## Capabilities

- 세션 기본값 설정: 프로젝트, 스킴, 시뮬레이터, 디바이스 기본값 지정
- 프로젝트 탐색: 프로젝트/워크스페이스 탐색, 스킴 조회, 빌드 설정 확인
- 시뮬레이터 워크플로우: 빌드, 실행, 테스트, 설치, 앱 실행, 시뮬레이터 상태 관리
- 디바이스 워크플로우: 물리 디바이스 빌드, 테스트, 설치, 실행
- macOS 워크플로우: macOS 앱 빌드, 실행, 테스트
- 로그 캡처: 시뮬레이터/디바이스 로그 스트리밍
- LLDB 디버깅: 브레이크포인트, 스택, 변수, LLDB 명령
- UI 자동화: 스크린샷, 뷰 계층, 탭/스와이프/입력
- SwiftPM: Swift Package Manager 프로젝트 빌드, 실행, 테스트

## Step 1: Establish Session Context

- 세션 첫 빌드/실행/테스트 전에 기본값을 먼저 확인합니다.
- 기본값이 비어 있거나 잘못되었을 때만 프로젝트 탐색을 수행합니다.
- 시뮬레이터 실행 의도면 빌드 후 실행보다 결합된 실행 흐름을 우선합니다.

## Step 2: Understand Workflow-Scoped Tool Availability

- 모든 도구가 기본 활성화되는 것은 아닙니다.
- 기대한 도구가 없으면 활성화된 workflow를 먼저 확인합니다.
- workflow 변경 후에는 세션 재시작 또는 reload가 필요할 수 있습니다.

## Step 3: Report Context Clearly

- 실행에 사용한 기본값 컨텍스트를 함께 보고합니다.
- 실패 시 정확히 어느 단계에서 실패했는지와 다음 액션을 제시합니다.
