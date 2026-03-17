#!/bin/bash
set -euo pipefail

ROOT_DIR="${1:-.}"
TASKMASTER_DIR="$ROOT_DIR/.cursor/project/taskmaster"

mkdir -p "$TASKMASTER_DIR"

copy_template() {
  local template_name="$1"
  local runtime_name="$2"
  local src="$TASKMASTER_DIR/$template_name"
  local dst="$TASKMASTER_DIR/$runtime_name"

  if [ ! -f "$src" ]; then
    echo "[tm-init][ERROR] template not found: $src" >&2
    exit 1
  fi

  if [ -f "$dst" ]; then
    echo "[tm-init][SKIP] already exists: $dst"
    return
  fi

  cp "$src" "$dst"
  echo "[tm-init][CREATE] $dst"
}

copy_template "state.template.json" "state.json"
copy_template "config.template.json" "config.json"

echo "[tm-init][DONE] task graph initialized at $TASKMASTER_DIR"
