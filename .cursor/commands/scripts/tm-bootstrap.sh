#!/bin/bash
set -euo pipefail

ROOT_DIR="${1:-.}"

echo "[tm-bootstrap]"
echo ""

bash "$ROOT_DIR/.cursor/commands/scripts/tm-init.sh" "$ROOT_DIR"
echo ""
bash "$ROOT_DIR/.cursor/commands/scripts/tm-validate.sh" "$ROOT_DIR"
echo ""
echo "[Next]"
echo "1. /tm-parse-prd"
echo "2. /tm-next"
echo "3. /tm-start <taskId>"
