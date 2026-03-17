---
name: ribs-ios
description: Uber RIBs-iOS 공식 패턴에 맞춰 iOS RIB 모듈을 설계, 구현, 리팩터링, 코드리뷰할 때 사용합니다. Use when Root/Child RIB 구조를 점검하거나 Builder/Router/Interactor/View/Dependency/Component 경계를 정렬해야 할 때, LaunchRouter 부트스트랩과 listener 기반 통신을 적용해야 할 때, 또는 기존 MVVM/Coordinator 코드를 RIBs 패턴으로 이관할 때.
source: origin
---

# RIBs iOS

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills ribs-ios`

## 목표

RIB 트리 구조, 책임 분리, 계층 DI를 Uber RIBs-iOS 권장 패턴과 일치시킵니다.

## 워크플로우

1. 기준 확보
- 먼저 관련 공식 문서를 확인합니다.
- 공식 자료가 부족하면 `uber/RIBs-iOS`의 `README`, `tutorials`, `RIBs/Classes`를 기준으로 사용합니다.

2. 코드베이스 매핑
- `Root*`, `*Builder`, `*Router`, `*Interactor`, `*ViewController`, `*ViewModel` 파일을 빠르게 수집합니다.
- 각 RIB별로 `Dependency`, `Component`, `Buildable`, `Routing`, `Listener` 존재 여부를 표로 정리합니다.

3. 아키텍처 점검
- [references/official-checklist.md](references/official-checklist.md) 체크리스트로 위반 지점을 탐지합니다.
- 위반 항목을 `높음/중간/낮음`으로 분류하고 파일/라인 근거를 남깁니다.

4. 구현
- 가장 큰 구조 리스크부터 최소 변경 단위로 수정합니다.
- 우선순위: Root launch 경로 -> Router/Interactor 책임 분리 -> DI 정렬 -> View 경계 정리
- 기존 기능 동작을 유지하면서 wiring만 바꾸고, 불필요한 대규모 포맷팅/리네임은 피합니다.

5. 검증
- 빌드와 테스트를 가능한 범위에서 실행합니다.
- 테스트 스킴이 없으면 없음을 명시합니다.
- 빠른 구조 점검이 필요하면 `scripts/ribs_audit.sh <project-root>`를 먼저 실행합니다.

## 구현 규칙

- Interactor에서 child builder를 직접 소유하거나 생성하지 않습니다.
- Router에서 child builder를 소유하고 `attachChild`/`detachChild`로 트리 제어를 담당합니다.
- Root는 가능하면 `LaunchRouter`로 시작하고 앱 진입점에서 `launch(from:)`을 호출합니다.
- Builder는 `Builder<Dependency>` 형태를 우선 사용합니다.
- View -> Interactor 이벤트는 `PresentableListener` 경계를 우선 사용합니다.
- RIB lifecycle은 `attachChild`/`detachChild`에 맡기고 수동 activate/deactivate 호출을 피합니다.

## 스크립트

`scripts/ribs_audit.sh`

- 목적: Root launch 경로, Router/Interactor 책임 경계, DI 패턴, listener 경계, 수동 lifecycle 호출 여부를 빠르게 검사
- 실행:

```bash
./.cursor/skills/ribs-ios/scripts/ribs_audit.sh .
```
