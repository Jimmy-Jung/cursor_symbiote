---
name: oop-design
description: 범용 OOP 설계, 아키텍처 계획, 클래스 다이어그램 생성 시 적용. Use when designing object-oriented architecture across languages and producing class diagrams before implementation.
source: origin
---

# OOP Design

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills oop-design`

## 목표

객체의 역할, 책임, 협력을 명확히 하고 정적/동적 설계를 합의한 뒤 구현으로 전환합니다.

## 워크플로우

1. 기준 확보
- 관련 언어/프레임워크 문서를 먼저 확인합니다.
- 코드베이스에서 유사 패턴, 레이어, 네이밍, DI 방식을 수집합니다.

2. 요구사항 정리
- `What`, `Why`, `How`, `Success Criteria`를 짧게 정리합니다.
- 누락된 핵심 질문 3~7개를 도출합니다.

3. 정적 설계
- 후보 객체를 Layer별로 정리합니다.
- 각 객체의 Role, Responsibility, Collaboration을 정의합니다.
- Mermaid `classDiagram`으로 구조를 확정합니다.

4. 동적 설계
- 핵심 시나리오 1~2개를 선택합니다.
- Mermaid `flowchart`로 메시지 흐름을 작성합니다.

5. 리스크 리뷰
- DIP/OCP 위반, 책임 누수, 과한 결합, 트랜잭션/동시성 경계를 점검합니다.
- 이슈를 `높음/중간/낮음`으로 분류하고 근거를 남깁니다.

6. 구현 전환
- 사용자가 `설계 완료` 또는 `설계 완료, 구현 시작`을 명시한 경우에만 구현합니다.
- 그 전에는 코드/파일 변경 없이 설계 산출물만 다룹니다.

7. 검증
- 설계 산출물 간 정합성을 점검합니다.
- 구현 단계라면 프로젝트 표준 검증을 실행하고 결과를 요약합니다.

## 멀티/서브 에이전트 운영

기본은 단일 에이전트로 진행합니다. 아래 조건에서만 선택적으로 서브에이전트를 사용합니다.

- 코드베이스 탐색 범위가 크고 읽기 작업 병렬화가 유리할 때
- 설계안 비교나 리스크 리뷰를 독립적으로 교차 검증할 때

권장 분담:
- `explorer`: 유사 코드, 의존성, 경계 탐색
- `architect`: 정적 구조 대안 설계
- `reviewer` 또는 `critic`: DIP/OCP, 회귀 리스크 검토

## 설계 규칙

- 구현 방법보다 객체가 제공하는 기능을 먼저 정의합니다.
- 절차형 분기보다 메시지 기반 협력을 우선합니다.
- 레이어 기본 원칙은 `Interface -> Application -> Domain -> Infrastructure`입니다.
- 특정 언어 문법에 과적합된 설계를 강제하지 않습니다.
- 성능보다 가독성과 변경 용이성을 우선합니다.
- 존재하지 않는 타입, 모듈, API를 가정하지 않습니다.

## 산출물 형식

1. 객체 후보 표

| 객체명 | Layer | 역할(Role) | 책임(Responsibility) | 협력자 |
|--------|-------|------------|------------------------|--------|

2. Mermaid classDiagram

```mermaid
classDiagram
```

3. Mermaid flowchart

```mermaid
flowchart LR
```
