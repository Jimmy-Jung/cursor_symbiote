---
name: notify-user
description: Slack MCP를 활용한 IDE-Slack 에스컬레이션 워크플로우. 자율 루프(Ralph/Autopilot) 중에는 Slack-First 모드로 AskQuestion 없이 Slack DM으로 직접 질문하고, 일반 모드에서는 IDE 질문 + Slack 사전 알림을 병행합니다. Use when the agent needs user confirmation while they are away from the IDE, or for urgent notifications.
disable-model-invocation: true
source: origin
---

# Notify User — IDE-Slack 에스컬레이션

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills notify-user`

Cursor 에이전트가 사용자 입력이 필요할 때 2가지 모드로 동작합니다:

Slack-First 모드 (자율 루프 중):
1. Slack DM으로 질문을 전송하고 (AskQuestion 생략)
2. IDE 채팅에도 질문 내용을 출력하며 (블로킹 없음)
3. Slack 폴링으로 응답을 대기하고
4. 응답 수신 후 작업을 계속 진행합니다

Interactive 모드 (일반 작업 중):
1. Slack DM으로 사전 알림을 보내고
2. IDE에서 AskQuestion으로 질문하며
3. 사용자가 "Away"를 선택하면 Slack 폴링으로 전환하고
4. 작업 완료 후 Slack으로 결과를 전송합니다

## 참조

- `.cursor/skills/note/SKILL.md` — 타임아웃 시 상태 보존
- `.cursor/skills/verify-loop/SKILL.md` — 자율 루프에서 에스컬레이션

## 사전 조건

- slack-mcp MCP 서버가 `~/.cursor/mcp.json`에 등록되어 실행 중이어야 합니다
- Slack App (Cursor AI Agent)이 워크스페이스에 설치되어 있어야 합니다
- Bot Token Scopes: channels:read, channels:history, chat:write, chat:write.public, im:write, im:read, im:history, users:read, reactions:write
- `.cursor/skills/notify-user/.env` 파일이 본인의 Slack 정보로 설정되어 있어야 합니다
- 최초 설정 시 SETUP-GUIDE.md를 참고하세요

## 환경 변수 (.env)

이 스킬은 `.cursor/skills/notify-user/.env` 파일에서 사용자별 Slack 정보를 읽습니다.
최초 사용 시 `.env.example`을 복사하여 `.env`로 만들고 본인의 정보를 입력하세요.

```bash
cp .cursor/skills/notify-user/.env.example .cursor/skills/notify-user/.env
```

환경 변수 목록:

| 변수 | 설명 | 예시 |
|---|---|---|
| SLACK_USER_ID | 본인의 Slack User ID | U0AEDMRTYR2 |
| SLACK_USER_NAME | Slack 표시 이름 | joony300 |
| SLACK_DM_CHANNEL_ID | Bot과의 DM 채널 ID | D0AE82S972S |
| SLACK_PROJECT_CHANNEL_ID | 프로젝트 채널 ID | C0AEDQ8065A |
| SLACK_PROJECT_CHANNEL_NAME | 프로젝트 채널 이름 | my-project |
| SLACK_BOT_USER_ID | Bot의 User ID | U0AEA4FJA4A |

에이전트는 이 스킬을 사용할 때 반드시 `.env` 파일을 먼저 읽어서 ID 값을 확인합니다.

## 사용 가능한 도구 (slack-mcp)

| 도구 | 용도 |
|---|---|
| `slack_post_message` | 채널/DM에 메시지 발신 (channelId, text) |
| `slack_post_reply` | 스레드에 답장 (channelId, threadTs, text) |
| `slack_get_dm_history` | DM 메시지 히스토리 조회 (dmChannelId, limit?) |
| `slack_get_channel_history` | 채널 메시지 히스토리 조회 (channelId, limit?) |
| `slack_get_thread_replies` | 스레드 답장 조회 (channelId, threadTs) |
| `slack_open_dm` | 사용자와 DM 채널 열기 (userId) |
| `slack_list_channels` | 채널 목록 조회 (limit?, cursor?) |
| `slack_list_users` | 사용자 목록 조회 (limit?, cursor?) |
| `slack_get_user_profile` | 사용자 프로필 조회 (userId) |
| `slack_get_user_presence` | 사용자 온라인 상태 조회 (userId) |
| `slack_add_reaction` | 메시지에 이모지 리액션 추가 (channelId, timestamp, name) |

## 워크플로우

### Step 0: .env 로드

이 스킬을 사용할 때 반드시 첫 단계로 `.env` 파일을 읽어야 합니다:

```
1. Read tool로 .cursor/skills/notify-user/.env 파일을 읽는다
2. 환경 변수에서 SLACK_DM_CHANNEL_ID, SLACK_PROJECT_CHANNEL_ID,
   SLACK_USER_ID, SLACK_BOT_USER_ID를 파싱한다
3. 이후 모든 Slack 도구 호출에 파싱한 값을 사용한다
```

.env 파일이 없거나 값이 비어있으면:
- 사용자에게 SETUP-GUIDE.md를 참고하여 설정하라고 안내
- 또는 slack_list_users, slack_list_channels로 직접 ID를 조회하여 안내

### Step 1: 모드 판별

자율 루프 활성 여부에 따라 모드를 결정합니다:

```
1. .cursor/project/state/*/ralph-state.md 파일을 확인한다
2. 파일이 존재하고 active: true이면 → Slack-First 모드
3. 그 외 → Interactive 모드
```

| 조건 | 모드 | AskQuestion | 동작 |
|------|------|-------------|------|
| ralph-state.md의 active: true | Slack-First | 사용하지 않음 | Slack DM 직행 → 폴링 |
| 그 외 (일반 작업) | Interactive | 사용 | Slack 사전 알림 + AskQuestion |

### Step 2: 알림 필요성 판단

다음 상황에서 이 워크플로우를 사용합니다:

긴급도 높음 (DM 사용):
- 시스템 권한 요청 (자격 증명, 접근 권한 등)
- 빌드/배포 실패로 즉각 대응 필요
- 작업 완전 중단 상태 (진행 불가)

긴급도 보통 (채널 또는 DM):
- 아키텍처/패턴 결정 필요
- 여러 선택지 중 사용자 의견 필요
- 작업 완료 알림 또는 승인 요청
- 비정상 상태 발견 보고

긴급도 낮음 (에스컬레이션 불필요):
- 코드 스타일 선택 (에이전트 판단으로 충분)
- 자동 복구 가능한 오류
- 진행 현황 보고 (Cursor 채팅으로 충분)

---

## Slack-First 모드 (자율 루프 중)

자율 루프(Ralph/Autopilot) 실행 중에는 사용자가 IDE를 떠난 것으로 간주합니다.
AskQuestion으로 블로킹하지 않고, Slack DM으로 직접 질문합니다.

### SF-1: Slack DM 전송

```
1. slack_post_message로 DM에 질문을 전송한다
   → 발신 메시지의 ts(timestamp)를 기억한다
2. IDE 채팅에도 동일 질문을 텍스트로 출력한다 (정보 제공용, 블로킹 아님)
   → "📨 Slack DM으로 질문을 전송했습니다. 응답을 대기합니다..."
```

Slack 메시지 형식:
```
🤖 [Cursor AI] 자율 작업 중 확인이 필요합니다

📋 작업: {task-folder 이름}
🔄 반복: {iteration}/{maxIterations}

{질문 내용}

1️⃣ {선택지 1}
2️⃣ {선택지 2}

번호로 답장해주세요.
```

### SF-2: Slack 폴링 루프

폴링 프로토콜 (Interactive 모드의 Phase 2와 동일):
```
간격: 30초 (Shell tool의 sleep 30 사용)
최대 시도: 20회 (= 10분)
감지 대상: DM 히스토리에서 ts 이후 + user가 SLACK_USER_ID인 메시지
무시 대상: Bot 메시지 (user가 SLACK_BOT_USER_ID)
```

폴링 루프 절차:
```
시도 = 0

반복:
  1. Shell tool로 sleep 30 실행 (30초 대기)
  2. slack_get_dm_history(dmChannelId: ${SLACK_DM_CHANNEL_ID}, limit: 5)
  3. 결과에서 필터링:
     - 사전 알림 메시지의 ts 이후 메시지만 대상
     - user 필드가 ${SLACK_USER_ID}인 메시지만 대상
     - user 필드가 ${SLACK_BOT_USER_ID}인 메시지는 무시
  4. 응답 발견 시:
     → 응답 내용을 파싱 (응답 처리 규칙 참조)
     → slack_add_reaction으로 ✅ 리액션
     → SF-3로 진행
  5. 응답 미발견 시:
     → 시도 += 1
     → 시도 < 20이면 1번으로 복귀
     → 시도 >= 20이면 타임아웃 처리
```

타임아웃 처리:
```
1. slack_post_message로 타임아웃 알림 전송:
   "⏰ [Cursor AI] 10분간 응답이 없어 작업을 일시정지합니다.
    작업: {task-folder 이름}
    대기 중인 질문: {질문 요약}
    Cursor로 돌아오시면 /ralph로 재개해주세요."
2. note 스킬로 현재 상태 저장 (질문 내용, 선택지, 작업 컨텍스트)
3. ralph-state.md의 phase를 waiting-user로 변경
4. 작업 일시정지
```

### SF-3: 응답 수신 후 계속 진행

```
1. 응답 내용을 IDE 채팅에 기록: "📨 Slack 응답 수신: {응답 내용}"
2. 결정된 방향으로 자율 루프 작업 계속 진행
3. 작업 완료 후 slack_post_message로 결과를 DM에 전송
4. 완료 리액션 추가 (slack_add_reaction으로 ✅)
```

### Slack-First 시나리오 예시

자율 루프 중 사용자 확인 필요:
```
[자율 루프 iteration 3/10 진행 중]
  → 아키텍처 패턴 결정 필요

SF-1:
  slack_post_message(channelId: ${SLACK_DM_CHANNEL_ID},
    text: "🤖 [Cursor AI] 자율 작업 중 확인이 필요합니다\n\n📋 작업: 2026-02-15T1430_login-feature\n🔄 반복: 3/10\n\n새 Feature 구현 시 패턴을 선택해주세요.\n\n1️⃣ Store/Worker\n2️⃣ MVVM\n\n번호로 답장해주세요.")
  → IDE 채팅에 "📨 Slack DM으로 질문을 전송했습니다. 응답을 대기합니다..." 출력

SF-2:
  → sleep 30 → slack_get_dm_history → 응답 없음 (시도 1/20)
  → sleep 30 → slack_get_dm_history → 사용자 "1" 응답 감지!
  → slack_add_reaction으로 ✅ 리액션

SF-3:
  → IDE 채팅에 "📨 Slack 응답 수신: 1 (Store/Worker)" 출력
  → Store/Worker 패턴으로 자율 루프 계속 진행
```

---

## Interactive 모드 (일반 작업)

일반 작업 중에는 IDE AskQuestion + Slack 사전 알림을 병행합니다.

### INT-1: Slack 사전 알림 + IDE AskQuestion

사용자 입력이 필요할 때 Slack과 IDE를 동시에 활용합니다.

```
1. slack_post_message로 DM에 질문을 사전 전송한다
   → 사용자가 자리를 비워도 모바일 푸시로 알림 수신
   → 발신 메시지의 ts(timestamp)를 기억한다

2. IDE AskQuestion으로 동일 질문을 표시한다
   → 선택지 마지막에 "Away - Slack으로 응답할게요" 옵션을 반드시 포함
   → 사용자가 실제 선택지를 고르면 Phase 3로 바로 진행
   → 사용자가 "Away"를 선택하면 Phase 2로 전환
```

Slack 사전 알림 메시지 형식:
```
🤖 [Cursor AI] 확인이 필요합니다

{질문 내용}

1️⃣ {선택지 1}
2️⃣ {선택지 2}

💡 IDE에서 작업 중이시면 IDE에서 응답해주세요.
자리를 비우셨다면 이 메시지에 번호로 답장해주세요.
```

AskQuestion 형식 (Away 옵션 포함):
```
AskQuestion(
  questions: [{
    id: "user_decision",
    prompt: "{질문 내용}",
    options: [
      { id: "opt_1", label: "{선택지 1}" },
      { id: "opt_2", label: "{선택지 2}" },
      { id: "away", label: "Away - Slack으로 응답할게요" }
    ]
  }]
)
```

### INT-2: Slack 폴링 루프

사용자가 "Away"를 선택하면 Slack DM에서 응답을 폴링합니다.

폴링 프로토콜:
```
간격: 30초 (Shell tool의 sleep 30 사용)
최대 시도: 20회 (= 10분)
감지 대상: DM 히스토리에서 ts 이후 + user가 SLACK_USER_ID인 메시지
무시 대상: Bot 메시지 (user가 SLACK_BOT_USER_ID)
```

폴링 루프 절차:
```
시도 = 0

반복:
  1. Shell tool로 sleep 30 실행 (30초 대기)
  2. slack_get_dm_history(dmChannelId: ${SLACK_DM_CHANNEL_ID}, limit: 5)
  3. 결과에서 필터링:
     - 사전 알림 메시지의 ts 이후 메시지만 대상
     - user 필드가 ${SLACK_USER_ID}인 메시지만 대상
     - user 필드가 ${SLACK_BOT_USER_ID}인 메시지는 무시
  4. 응답 발견 시:
     → 응답 내용을 파싱 (Step 5 참조)
     → slack_add_reaction으로 확인 리액션 추가
     → Phase 3로 진행
  5. 응답 미발견 시:
     → 시도 += 1
     → 시도 < 20이면 1번으로 복귀
     → 시도 >= 20이면 타임아웃 처리

타임아웃 처리:
  1. slack_post_message로 타임아웃 알림 전송:
     "⏰ [Cursor AI] 10분간 응답이 없어 작업을 일시정지합니다.
      Cursor로 돌아오시면 작업을 이어서 진행해주세요."
  2. note 스킬로 현재 상태 저장 (질문 내용, 선택지, 작업 컨텍스트)
  3. 작업 일시정지
```

### INT-3: 작업 완료 + 결과 전송

응답을 받은 후 작업을 수행하고, Slack으로 결과를 전송합니다.

```
1. 응답 기반으로 작업 수행
2. 작업 완료 후 slack_post_message로 결과를 DM에 전송
3. 복잡한 결과는 slack_post_reply로 원래 질문 스레드에 연결
4. 완료 리액션 추가 (slack_add_reaction으로 ✅)
```

작업 결과 메시지 형식:
```
✅ [Cursor AI] {작업명} 완료

{결과 요약}
- 수정 파일: N개
- 소요 시간: ~Nm

Cursor에서 확인해주세요.
```

INT-3는 다음 경우에 실행됩니다:
- IDE AskQuestion에서 직접 응답한 경우 (INT-1에서 바로 진행)
- Slack 폴링으로 응답을 받은 경우 (INT-2를 거쳐 진행)
- 두 경우 모두 Slack DM에 결과를 전송합니다

---

## 응답 처리 (공통)

사용자 응답 파싱 규칙:
- 숫자 응답: 선택지 번호로 처리 (1, 2, 3...)
- Y/N 응답: 승인/거부로 처리 (대소문자 무관)
- 텍스트 응답: 자유 형식 답변으로 처리
- 이모지 리액션: 간단한 승인/거부로 활용 가능

응답 확인 방법 (Slack):
- slack_get_dm_history(dmChannelId: ${SLACK_DM_CHANNEL_ID})로 최근 메시지 확인
- 발신 메시지 ts 이후의 사용자 메시지를 응답으로 간주
- user 필드가 ${SLACK_USER_ID}(사용자)인 메시지만 필터링

응답 후 행동:
1. 응답 내용을 Cursor 채팅에 기록
2. 결정된 방향으로 작업 계속 진행
3. Slack 스레드로 결과 공유 (Phase 3)
4. 완료 리액션 추가 (slack_add_reaction으로 ✅)

## 메시지 템플릿

### 확인 요청 (사전 알림)
```
🤖 [Cursor AI] 확인이 필요합니다

{질문 내용}

1️⃣ {선택지 1}
2️⃣ {선택지 2}

💡 IDE에서 작업 중이시면 IDE에서 응답해주세요.
자리를 비우셨다면 이 메시지에 번호로 답장해주세요.
```

### 완료 알림
```
✅ [Cursor AI] {작업명} 완료

{결과 요약}
- 수정 파일: N개
- 소요 시간: ~Nm

Cursor에서 확인해주세요.
```

### 에러 보고
```
🚨 [Cursor AI] {에러 유형} 발생

{간단한 설명}

1️⃣ 자동 수정 시도
2️⃣ 대기

번호로 답장해주세요.
```

### 타임아웃 알림
```
⏰ [Cursor AI] 10분간 응답이 없어 작업을 일시정지합니다.

대기 중인 질문: {질문 요약}

Cursor로 돌아오시면 작업을 이어서 진행해주세요.
```

### 스레드 기반 대화 (복잡한 결정)
```
1. slack_post_message로 초기 질문 발신 → ts 저장
2. slack_get_thread_replies(channelId, threadTs: ts)로 답장 확인
3. 추가 질문: slack_post_reply(channelId, threadTs: ts, text: "...")
4. 스레드에서 대화가 완료될 때까지 반복
```

## 사용 시나리오 예시

### 시나리오 1: Interactive — 사용자가 IDE에 있는 경우

```
INT-1:
  slack_post_message로 DM에 사전 알림
  → AskQuestion으로 IDE에도 질문 표시
  → 사용자가 IDE에서 "Store/Worker" 선택

INT-3:
  → Store/Worker 패턴으로 구현 진행
  → 완료 후 slack_post_message로 결과 전송
```

### 시나리오 2: Interactive — 사용자가 Away 선택

```
INT-1:
  slack_post_message로 DM에 질문 전송 (ts 저장)
  → AskQuestion으로 IDE에도 질문 표시
  → 사용자가 IDE에서 "Away - Slack으로 응답할게요" 선택

INT-2:
  → sleep 30 → slack_get_dm_history → 응답 없음 (시도 1/20)
  → sleep 30 → slack_get_dm_history → 사용자 "1" 응답 감지!
  → slack_add_reaction으로 ✅ 리액션

INT-3:
  → Store/Worker 패턴으로 구현 진행
  → 완료 후 slack_post_message로 결과 전송
```

### 시나리오 3: Slack-First — 자율 루프 중 확인 필요

```
[Ralph Loop iteration 3/10 진행 중]
  → 아키텍처 패턴 결정 필요 → ralph-state.md active: true → Slack-First

SF-1:
  slack_post_message로 DM에 질문 전송 (ts 저장)
  → IDE 채팅에 "📨 Slack DM으로 질문을 전송했습니다..." 출력

SF-2:
  → sleep 30 → slack_get_dm_history → 응답 없음 (시도 1/20)
  → sleep 30 → slack_get_dm_history → 사용자 "1" 응답 감지!
  → slack_add_reaction으로 ✅ 리액션

SF-3:
  → IDE 채팅에 "📨 Slack 응답 수신: 1 (Store/Worker)" 출력
  → Store/Worker 패턴으로 자율 루프 계속 진행
  → 완료 후 slack_post_message로 결과 전송
```

### 시나리오 4: Slack-First — 타임아웃

```
[Autopilot iteration 2/3 진행 중]

SF-1:
  slack_post_message로 DM에 질문 전송

SF-2:
  → 20회 폴링 (10분) 동안 응답 없음
  → 타임아웃 메시지 전송
  → note 스킬로 상태 저장
  → ralph-state.md phase를 waiting-user로 변경
  → 작업 일시정지
```

### 시나리오 5: Interactive — 긴급 에러 알림

```
INT-1:
  slack_post_message(channelId: ${SLACK_DM_CHANNEL_ID},
    text: "🚨 [Cursor AI] 빌드 실패 3건 발생\n\n...")
  → AskQuestion(Away 옵션 포함)

(이후 INT-2 또는 직접 응답에 따라 진행)
```

## 에이전트 연동

- Synapse 오케스트레이터: verify-loop의 에스컬레이션 시점에서 이 스킬 호출
- ralph/autopilot: 자율 루프 중 사용자 확인이 필요할 때 이 스킬 호출 → Slack-First 모드 자동 활성화
- 모든 에이전트: 긴급도 높은 결정이 필요할 때 이 스킬 호출

호출 시점:
1. 에이전트가 사용자 입력 없이 진행 불가한 상태
2. 보안/권한 관련 결정이 필요한 상태
3. 작업 완료 후 결과를 알려야 하는 상태

모드 자동 선택:
- ralph-state.md active: true → Slack-First (AskQuestion 없이 Slack DM 직행)
- 그 외 → Interactive (AskQuestion + Slack 사전 알림 병행)

## 주의사항

- 짧은 간격으로 반복 발신하지 않습니다 (최소 3분 간격)
- 개인정보나 자격 증명을 Slack 메시지로 전송하지 않습니다
- 코드 블록이 길면 요약만 보내고 "Cursor에서 확인" 안내
- DM 히스토리 조회 시 limit을 최소화 (5~10개)
- 사용자 응답 판별: user 필드가 ${SLACK_USER_ID}인 메시지만 응답으로 처리
- Bot 자신의 메시지 (user: ${SLACK_BOT_USER_ID})는 무시
- .env 파일은 Git에 커밋하지 않습니다 (.gitignore에 포함됨)
- 폴링 중 비차단 작업 (독립적인 코드 분석 등)은 병행 가능
