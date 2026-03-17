---
name: xcode-mcp
description: Xcode MCP server, `xcrun mcpbridge`, Xcode Intelligence 연동을 점검하거나 설명할 때 사용합니다. Use when the user wants to connect an agentic coding tool to Xcode through the Xcode MCP server, inspect or troubleshoot `xcrun mcpbridge`, verify MCP setup, or understand which Xcode capabilities are exposed to an external agent.
source: origin
---

# Xcode MCP

> @-tracking: `bash .cursor/hooks/usage-tracker.sh skills xcode-mcp`

## Overview

이 스킬은 Xcode MCP 설정, 점검, 트러블슈팅, 사용법 설명을 위한 가이드입니다. `xcrun mcpbridge`, Xcode Intelligence 설정, 외부 에이전트의 Xcode 접근 방식이 주제일 때 사용합니다.

## Workflow

1. 요청이 Xcode MCP bridge, 외부 에이전트 접근, Xcode Intelligence 연동과 관련된 것인지 확인합니다.
2. 현재 로컬 Xcode 상태를 먼저 확인합니다.
   - `xcrun --find mcpbridge`
   - `xcrun mcpbridge --help`
   - `codex mcp list`
3. 제품 동작과 설정 세부 사항은 Apple 공식 문서를 우선합니다.
4. 아래를 명확히 구분해 설명합니다.
   - 로컬 명령으로 확인한 사실
   - Apple 공식 문서에 있는 동작
   - 내부 구조에 대한 합리적 추론
5. 설정 도움말이 필요하면 정확한 명령과 검증 절차를 함께 제공합니다.
6. 트러블슈팅이면 활성 Xcode 인스턴스 선택, MCP 등록, Xcode Intelligence 설정을 먼저 점검합니다.

## What To Explain

- `xcrun mcpbridge`가 하는 일
- STDIO JSON-RPC 트래픽이 Xcode MCP tool service로 브리지되는 방식
- `MCP_XCODE_PID`를 통한 Xcode 인스턴스 선택 방식
- `MCP_XCODE_SESSION_ID`를 통한 세션 식별 방식
- Xcode Intelligence 설정에서 Xcode Tools 활성화 방법
- Codex 등 외부 에이전트에서 Xcode MCP 서버를 등록하는 방법

## Key Commands

```bash
xcrun --find mcpbridge
xcrun mcpbridge --help
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
```

여러 Xcode 프로세스가 열려 있으면 어느 인스턴스를 대상으로 할지 확인하고 필요하면 `MCP_XCODE_PID`를 함께 설명합니다.

## References

- Apple 동작과 설정 기준은 [references/xcode-mcp.md](references/xcode-mcp.md)를 읽습니다.
- 전체를 한 번에 읽기보다 필요한 섹션만 선택적으로 봅니다.
