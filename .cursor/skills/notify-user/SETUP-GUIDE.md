# Slack + Cursor AI Agent 연동 가이드

Cursor 에이전트가 작업 중 Slack으로 알림을 보내고, 사용자의 Slack 답장을 읽어
작업을 계속 진행하는 양방향 통신 환경을 설정하는 가이드입니다.

- 작성자: jimmy
- 작성일: 2026-02-12

---

## 목차

1. [개요](#1-개요)
2. [사전 준비](#2-사전-준비)
3. [Slack 워크스페이스 생성](#3-slack-워크스페이스-생성)
4. [Slack App 생성 및 설정](#4-slack-app-생성-및-설정)
5. [Cursor MCP 설정](#5-cursor-mcp-설정)
6. [프로젝트 채널 생성](#6-프로젝트-채널-생성)
7. [.env 파일 설정](#7-env-파일-설정)
8. [연동 테스트](#8-연동-테스트)
9. [사용 방법](#9-사용-방법)
10. [트러블슈팅](#10-트러블슈팅)

---

## 1. 개요

이 연동을 설정하면:

- Cursor 에이전트가 작업 중 확인이 필요할 때 Slack DM 또는 채널로 알림
- 사용자가 자리를 비워도 Slack 모바일 푸시로 알림 수신
- 사용자가 Slack에서 답장하면 에이전트가 읽고 작업 계속 진행
- 작업 완료 후 Slack으로 결과 전송
- 무료 (Slack Free 플랜으로 충분)

동작 구조:

```
Cursor Agent ──slack_post_message──→ Slack DM ──푸시 알림──→ 사용자 모바일
    ↑                                   │
    └────slack_get_dm_history───────────┘ (사용자 답장 읽기)
```

---

## 2. 사전 준비

- Cursor IDE 설치 (https://cursor.sh)
- Slack 계정 (https://slack.com)
- Node.js 18+ 설치 (npx 명령어 사용을 위해)

Node.js 설치 확인:

```bash
node --version  # v18.0.0 이상
npx --version   # 설치되어 있어야 함
```

---

## 3. Slack 워크스페이스 생성

이미 개인 Slack 워크스페이스가 있으면 4단계로 건너뛰세요.

1. https://slack.com/create 접속
2. 이메일 주소 입력 → 인증 코드 확인
3. 워크스페이스 이름 입력 (예: `{이름}-dev`, `jimmy-workspace`)
4. 생성 완료

---

## 4. Slack App 생성 및 설정

### 4-1. App 생성

1. https://api.slack.com/apps 접속
2. "Create New App" 클릭
3. "From scratch" 선택
4. 설정:
   - App Name: `Cursor AI Agent`
   - Workspace: 본인의 워크스페이스 선택
5. "Create App" 클릭

### 4-2. Bot Token Scopes 설정

1. 왼쪽 메뉴 "OAuth & Permissions" 클릭
2. "Scopes" 섹션으로 스크롤
3. "Bot Token Scopes"에 아래 권한 모두 추가:

| Scope | 용도 |
|---|---|
| `channels:read` | 채널 목록 읽기 |
| `channels:history` | 채널 메시지 읽기 |
| `channels:join` | 채널 참여 |
| `chat:write` | 메시지 보내기 |
| `chat:write.public` | 채널 가입 없이 메시지 보내기 |
| `im:write` | DM 보내기 |
| `im:read` | DM 채널 읽기 |
| `im:history` | DM 메시지 읽기 |
| `users:read` | 사용자 정보 읽기 |
| `reactions:write` | 리액션 추가 |
| `groups:read` | 비공개 채널 정보 (선택) |
| `groups:history` | 비공개 채널 메시지 읽기 (선택) |

### 4-3. App Home 설정 (DM 답장 허용)

1. 왼쪽 메뉴 "App Home" 클릭
2. "Show Tabs" 섹션에서:
   - "Messages Tab" 토글 ON
   - "Allow users to send Slash commands and messages from the messages tab" 체크

이 설정이 없으면 사용자가 Bot에게 DM을 보낼 수 없습니다.

### 4-4. 워크스페이스에 설치

1. 왼쪽 메뉴 "OAuth & Permissions"로 돌아가기
2. 페이지 상단 "Install to Workspace" 클릭
3. 권한 확인 후 "Allow" 클릭

### 4-5. Token 및 ID 확인

설치 후 아래 정보를 메모합니다:

Bot User OAuth Token:
- "OAuth & Permissions" 페이지 상단에 표시
- `xoxb-` 로 시작하는 문자열
- 예: `xoxb-your-slack-bot-token-here`

Team ID:
- Slack 웹 브라우저에서 워크스페이스 접속
- URL: `https://app.slack.com/client/T0XXXXXXXX/...`
- `T`로 시작하는 부분이 Team ID
- 예: `T0AE828HRM4`

---

## 5. Cursor MCP 설정

### 5-1. mcp.json 파일 편집

`~/.cursor/mcp.json` 파일을 열고 `mcpServers`에 `slack-mcp` 항목을 추가합니다.

파일이 없으면 새로 생성합니다:

```json
{
  "mcpServers": {
    "slack-mcp": {
      "command": "npx",
      "args": [
        "@meepo-ab/slack-mcp"
      ],
      "env": {
        "SLACK_BOT_TOKEN": "여기에_Bot_Token_입력",
        "SLACK_TEAM_ID": "여기에_Team_ID_입력"
      }
    }
  }
}
```

이미 다른 MCP 서버가 등록되어 있다면, `mcpServers` 안에 `slack-mcp` 항목만 추가합니다:

```json
{
  "mcpServers": {
    "기존-서버": { "..." : "..." },
    "slack-mcp": {
      "command": "npx",
      "args": [
        "@meepo-ab/slack-mcp"
      ],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-여기에-실제-토큰",
        "SLACK_TEAM_ID": "T여기에실제ID"
      }
    }
  }
}
```

### 5-2. MCP 서버 활성화

1. Cursor 재시작 또는 Settings > MCP 이동
2. `slack-mcp`가 목록에 나타나는지 확인
3. 서버 상태가 "Running" (녹색)인지 확인
4. 녹색이 아니면 Restart 버튼 클릭

---

## 6. 프로젝트 채널 생성

Slack에서 프로젝트 전용 채널을 만듭니다.

1. Slack 왼쪽 사이드바에서 "채널" 옆 `+` 클릭
2. 채널 이름 입력: `{프로젝트명}` (예: `my-ios-app`, `backend-api`)
3. "만들기" 클릭

채널 ID 확인 방법:
- 웹 브라우저에서 해당 채널을 열면 URL이 `https://app.slack.com/client/TXXXXXX/CXXXXXX`
- `C`로 시작하는 부분이 채널 ID
- 또는 Cursor에서 에이전트에게 "slack_list_channels로 채널 목록 보여줘"라고 요청

---

## 7. .env 파일 설정

프로젝트의 `.cursor/skills/notify-user/.env.example`을 복사하여 `.env`로 만들고,
본인의 Slack 정보를 입력합니다.

```bash
cp .cursor/skills/notify-user/.env.example .cursor/skills/notify-user/.env
```

`.env` 파일을 열고 아래 값을 채웁니다:

```bash
SLACK_USER_ID=U여기에본인ID
SLACK_USER_NAME=본인표시이름
SLACK_DM_CHANNEL_ID=D여기에DM채널ID
SLACK_PROJECT_CHANNEL_ID=C여기에채널ID
SLACK_PROJECT_CHANNEL_NAME=my-project
SLACK_BOT_USER_ID=U여기에봇ID
```

ID 확인 방법 (Cursor에서 에이전트에게 요청):

```
"slack_list_users로 사용자 목록 보여줘"
→ 본인의 User ID (U로 시작) 및 Bot User ID 확인

"slack_open_dm으로 {User ID}와 DM 채널 열어줘"
→ DM Channel ID 확인 (D로 시작)

"slack_list_channels로 채널 목록 보여줘"
→ 프로젝트 채널 ID 확인 (C로 시작)
```

NOTE: `.env` 파일은 `.gitignore`에 포함되어 Git에 커밋되지 않습니다.
각 개발자가 본인의 정보로 개별 설정합니다.

---

## 8. 연동 테스트

Cursor 에이전트에게 아래 테스트를 요청합니다:

### 테스트 1: 메시지 발신

Cursor 채팅에서:
```
Slack DM으로 테스트 메시지 보내줘
```

Slack에서 Bot 메시지가 도착하면 성공.

### 테스트 2: 메시지 수신 (양방향)

1. Slack DM에서 Bot에게 "OK" 입력
2. Cursor 채팅에서:
```
Slack DM의 최근 메시지 읽어줘
```

에이전트가 "OK" 메시지를 읽으면 양방향 통신 성공.

### 테스트 3: 채널 메시지 발신

Cursor 채팅에서:
```
Slack 프로젝트 채널에 테스트 메시지 보내줘
```

---

## 9. 사용 방법

### 자동 알림 (에이전트 → 사용자)

에이전트가 작업 중 확인이 필요하면 자동으로 3-Phase 워크플로우를 실행합니다:
- Phase 1: Slack DM 사전 알림 + IDE AskQuestion
- Phase 2: 사용자가 Away 선택 시 Slack 폴링
- Phase 3: 작업 완료 후 Slack 결과 전송

별도 설정 없이 `@notify-user` 스킬이 활성화되면 자동 동작합니다.

### 수동 알림 (사용자 → 에이전트)

Cursor 채팅에서 직접 요청할 수도 있습니다:

```
Slack에 작업 진행 상황 보고해줘
```

```
Slack DM으로 빌드 결과 공유해줘
```

---

## 10. 트러블슈팅

### MCP 서버가 시작되지 않음

증상: Settings > MCP에서 slack-mcp가 빨간색

해결:
1. Node.js가 설치되어 있는지 확인 (`node --version`)
2. `~/.cursor/mcp.json`의 JSON 문법 오류 확인
3. Bot Token과 Team ID가 올바른지 확인
4. Cursor 재시작

### "missing_scope" 에러

증상: 에이전트가 Slack 도구 사용 시 "missing_scope" 에러

해결:
1. https://api.slack.com/apps에서 앱 선택
2. "OAuth & Permissions" > "Bot Token Scopes"에서 누락된 권한 추가
3. 페이지 상단 "Reinstall to Workspace" 클릭
4. Cursor에서 slack-mcp 서버 재시작

### "이 앱으로 메시지를 보내는 기능이 꺼져 있습니다"

증상: Slack에서 Bot에게 DM을 보낼 수 없음

해결:
1. https://api.slack.com/apps에서 앱 선택
2. "App Home" 클릭
3. "Show Tabs" > "Messages Tab" 토글 ON
4. "Allow users to send Slash commands and messages from the messages tab" 체크

### 채널 메시지를 읽을 수 없음

증상: slack_get_channel_history가 실패

해결:
- `channels:history` 권한이 추가되어 있는지 확인
- 비공개 채널이면 `groups:history` 권한도 필요
- 앱 재설치 후 MCP 서버 재시작

### DM 메시지를 읽을 수 없음

증상: slack_get_dm_history가 실패

해결:
- `im:history` 권한이 추가되어 있는지 확인
- 앱 재설치 후 MCP 서버 재시작

### Bot Token 재발급이 필요한 경우

Token이 유출되었거나 만료된 경우:
1. https://api.slack.com/apps에서 앱 선택
2. "OAuth & Permissions"에서 "Reinstall to Workspace" 클릭
3. 새 Bot Token 복사
4. `~/.cursor/mcp.json`의 `SLACK_BOT_TOKEN` 업데이트
5. Cursor에서 MCP 서버 재시작

---

## 보안 주의사항

- `~/.cursor/mcp.json` 파일에는 Bot Token이 포함되어 있습니다
- 이 파일을 Git에 커밋하지 마세요 (글로벌 경로이므로 보통 문제 없음)
- Bot Token이 유출되면 즉시 앱을 재설치하여 토큰 갱신
- Slack 메시지로 비밀번호, API 키 등 민감 정보를 전송하지 마세요
- 개인 워크스페이스를 사용하면 외부 노출 위험이 최소화됩니다
- `.env` 파일은 반드시 `.gitignore`에 포함시키세요
