#!/bin/bash
set -euo pipefail

# prd.json을 prd.md로 변환 (가독성용 보조 파일)

ROOT_DIR="${1:-.}"
TASK_FOLDER="${2:-}"

if [ -n "$TASK_FOLDER" ]; then
  PRD_JSON="$ROOT_DIR/.cursor/project/state/$TASK_FOLDER/prd.json"
else
  PRD_JSON="$(find "$ROOT_DIR/.cursor/project/state" -maxdepth 2 -name prd.json 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${PRD_JSON:-}" ] || [ ! -f "$PRD_JSON" ]; then
  echo "[prd-to-md][ERROR] prd.json not found" >&2
  exit 1
fi

if [ -z "$TASK_FOLDER" ]; then
  TASK_FOLDER="$(basename "$(dirname "$PRD_JSON")")"
fi

PRD_MD="$ROOT_DIR/.cursor/project/state/$TASK_FOLDER/prd.md"

TITLE="$(jq -r '.title // "Untitled"' "$PRD_JSON")"
DESCRIPTION="$(jq -r '.description // ""' "$PRD_JSON")"
COMPLETION_LEVEL="$(jq -r '.completionLevel // 3' "$PRD_JSON")"
CREATED_AT="$(jq -r '.createdAt // ""' "$PRD_JSON")"
UPDATED_AT="$(jq -r '.updatedAt // ""' "$PRD_JSON")"

cat > "$PRD_MD" <<EOF
# PRD: $TITLE

- description: $DESCRIPTION
- completionLevel: $COMPLETION_LEVEL
- createdAt: $CREATED_AT
- updatedAt: $UPDATED_AT

## User Stories

EOF

jq -r '.userStories[] | 
"### \(.id): \(.title // .iWant)\n\n- as: \(.as)\n- iWant: \(.iWant)\n- soThat: \(.soThat)\n- status: \(.status)\n- priority: \(.priority)\n- implementedIn: \(if (.implementedIn | length) > 0 then (.implementedIn | join(", ")) else "(none)" end)\n\nAcceptance Criteria:\n\n\(if .acceptanceCriteria then (.acceptanceCriteria | map("- [ ] " + .) | join("\n")) else "" end)\n\n"
' "$PRD_JSON" >> "$PRD_MD"

cat >> "$PRD_MD" <<EOF
## Risks

| 설명 | 영향도 | 완화 방안 |
|------|--------|----------|
EOF

jq -r '.risks[]? | "| \(.description) | \(.impact) | \(.mitigation) |"' "$PRD_JSON" >> "$PRD_MD" || true

cat >> "$PRD_MD" <<EOF

## Scope

### In Scope

EOF

jq -r '.scope.inScope[]? | "- \(.)"' "$PRD_JSON" >> "$PRD_MD" || true

cat >> "$PRD_MD" <<EOF

### Out of Scope

EOF

jq -r '.scope.outOfScope[]? | "- \(.)"' "$PRD_JSON" >> "$PRD_MD" || true

echo "[prd-to-md]"
echo ""
echo "- source: ${PRD_JSON#$ROOT_DIR/}"
echo "- output: ${PRD_MD#$ROOT_DIR/}"
echo "- userStories: $(jq '.userStories | length' "$PRD_JSON")"
