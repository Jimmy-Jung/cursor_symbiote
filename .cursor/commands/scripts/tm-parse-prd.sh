#!/bin/bash
set -euo pipefail

ROOT_DIR="${1:-.}"
TASK_FOLDER="${2:-}"
MODE="${3:-replace}"

TASKMASTER_DIR="$ROOT_DIR/.cursor/project/taskmaster"
TEMPLATE_JSON="$TASKMASTER_DIR/tasks.template.json"

if [ -n "$TASK_FOLDER" ]; then
  PRD_JSON="$ROOT_DIR/.cursor/project/state/$TASK_FOLDER/prd.json"
else
  PRD_JSON="$(find "$ROOT_DIR/.cursor/project/state" -maxdepth 2 -name prd.json 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${PRD_JSON:-}" ] || [ ! -f "$PRD_JSON" ]; then
  echo "[tm-parse-prd][ERROR] prd.json not found" >&2
  exit 1
fi

if [ -z "$TASK_FOLDER" ]; then
  TASK_FOLDER="$(basename "$(dirname "$PRD_JSON")")"
fi

TASK_JSON="$ROOT_DIR/.cursor/project/state/$TASK_FOLDER/task.json"

if [ ! -f "$TEMPLATE_JSON" ]; then
  echo "[tm-parse-prd][ERROR] tasks.template.json not found: $TEMPLATE_JSON" >&2
  exit 1
fi

if [ ! -f "$TASK_JSON" ]; then
  cp "$TEMPLATE_JSON" "$TASK_JSON"
fi

GENERATED_TASKS="$(jq '
  {
    tasks: [
      .userStories[] as $story
      | {
          id: (($story.id // "") | sub("^US-"; "")),
          title: ($story.iWant // $story.id // "Untitled Story"),
          description: (($story.as // "사용자") + "가 " + ($story.iWant // "기능") + " 하여 " + ($story.soThat // "목표를 달성")),
          status: (($story.status // "pending") | if . == "in_progress" then "in_progress" elif . == "done" then "done" elif . == "blocked" then "blocked" else "pending" end),
          priority: ($story.priority // "medium"),
          dependencies: [($story.dependsOn // [])[] | sub("^US-"; "")],
          details: (($story.iWant // "") + "\n\nsoThat: " + ($story.soThat // "")),
          testStrategy: (($story.acceptanceCriteria // []) | join("\n")),
          subtasks: [],
          metadata: {
            source: "prd",
            tag: "master",
            taskFolder: $taskFolder,
            userStories: [$story.id],
            risks: []
          }
        }
    ]
  }
' --arg taskFolder "$TASK_FOLDER" "$PRD_JSON")"

if [ "$MODE" = "--append" ] || [ "$MODE" = "append" ]; then
  TMP_JSON="$(mktemp)"
  jq --argjson generated "$GENERATED_TASKS" '
    .tasks = (.tasks + $generated.tasks)
  ' "$TASK_JSON" > "$TMP_JSON"
  mv "$TMP_JSON" "$TASK_JSON"
  APPEND_VALUE="true"
else
  TMP_JSON="$(mktemp)"
  jq --argjson generated "$GENERATED_TASKS" '
    .tasks = $generated.tasks
  ' "$TASK_JSON" > "$TMP_JSON"
  mv "$TMP_JSON" "$TASK_JSON"
  APPEND_VALUE="false"
fi

GENERATED_COUNT="$(jq '.tasks | length' <<<"$GENERATED_TASKS")"

echo "[tm-parse-prd]"
echo ""
echo "- source: ${PRD_JSON#$ROOT_DIR/}"
echo "- target: ${TASK_JSON#$ROOT_DIR/}"
echo "- generatedTasks: $GENERATED_COUNT"
echo "- append: $APPEND_VALUE"
echo "- nextAction: /tm-validate"
