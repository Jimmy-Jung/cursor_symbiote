# Xcode MCP Reference

## Scope

이 문서는 아래 주제에 사용합니다.

- Xcode Intelligence 설정
- 외부 에이전트의 Xcode 접근
- `xcrun mcpbridge`
- Codex 또는 다른 에이전트의 Xcode MCP 서버 등록
- Xcode가 MCP를 통해 노출하는 기능 설명

## Official Apple References

- Setting up coding intelligence:
  https://developer.apple.com/documentation/Xcode/setting-up-coding-intelligence
- Writing code with intelligence in Xcode:
  https://developer.apple.com/documentation/Xcode/writing-code-with-intelligence-in-xcode
- Giving external agentic coding tools access to Xcode:
  https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode

## Confirmed Local Facts To Check

다음 명령으로 현재 머신 상태를 먼저 확인합니다.

```bash
xcrun --find mcpbridge
xcrun mcpbridge --help
codex mcp list
```

## Mental Model

```text
External agent
  -> STDIO JSON-RPC
mcpbridge
  -> Xcode MCP tool service
Xcode
  -> project context and Xcode capabilities
```

중요한 점:
- `mcpbridge`는 transport bridge입니다.
- 실제 기능은 Xcode가 제공합니다.

## Xcode Setup Flow

1. Xcode를 엽니다.
2. `Xcode > Settings > Intelligence`로 이동합니다.
3. `Model Context Protocol`에서 `Xcode Tools`를 켭니다.
4. MCP 서버를 등록합니다.

```bash
codex mcp add xcode -- xcrun mcpbridge
```

5. 등록을 확인합니다.

```bash
codex mcp list
```

## Troubleshooting Order

1. Xcode가 실행 중인지 확인
2. Intelligence 설정에서 `Xcode Tools`가 켜져 있는지 확인
3. `xcrun --find mcpbridge`가 정상 동작하는지 확인
4. `codex mcp list`에 `xcode`가 있는지 확인
5. Xcode가 여러 개 열려 있으면 `MCP_XCODE_PID` 사용
6. 필요하면 Xcode 재실행 후 bridge 프로세스를 새로 시작
