# PRD: 사용자 알림 시스템

- description: 실시간 알림과 알림 설정 관리 기능
- completionLevel: 3
- createdAt: 2026-02-17T14:30:00Z
- updatedAt: 2026-02-17T15:00:00Z

## User Stories

### US-001: 실시간 알림 수신

- as: 사용자
- iWant: 새 메시지나 이벤트 발생 시 실시간 알림을 받고 싶다
- soThat: 중요한 업데이트를 놓치지 않을 수 있다
- status: done
- implementedIn: src/notifications/NotificationService.ts, src/notifications/WebSocketHandler.ts

Acceptance Criteria:

- [x] AC-1: WebSocket 연결로 실시간 알림 수신
- [x] AC-2: 알림 수신 시 브라우저 Notification API 호출
- [x] AC-3: 연결 끊김 시 자동 재연결 (최대 3회)

### US-002: 알림 목록 조회

- as: 사용자
- iWant: 과거 알림을 목록으로 조회하고 싶다
- soThat: 놓친 알림을 확인할 수 있다
- status: in_progress
- implementedIn: src/notifications/NotificationList.tsx

Acceptance Criteria:

- [x] AC-1: 최근 30일 알림을 시간순으로 표시
- [ ] AC-2: 읽음/안읽음 상태 구분
- [ ] AC-3: 무한 스크롤 페이지네이션

### US-003: 알림 설정 관리

- as: 사용자
- iWant: 알림 유형별로 수신 여부를 설정하고 싶다
- soThat: 원하는 알림만 받을 수 있다
- status: pending
- implementedIn: (none)

Acceptance Criteria:

- [ ] AC-1: 알림 유형별 토글 UI
- [ ] AC-2: 설정 변경 즉시 반영
- [ ] AC-3: 기본 설정 초기화 기능

## Risks

| 설명 | 영향도 | 완화 방안 |
|------|--------|----------|
| WebSocket 연결 불안정 시 알림 누락 | high | 폴링 fallback + 메시지 큐 도입 |
| 대량 알림 시 UI 성능 저하 | medium | 가상 스크롤 + 배치 렌더링 |

## Scope

### In Scope

- 실시간 알림 수신 (WebSocket)
- 알림 목록 조회 (페이지네이션)
- 알림 설정 관리 UI

### Out of Scope

- 이메일/SMS 알림
- 알림 분석 대시보드
- 관리자용 알림 발송 도구
