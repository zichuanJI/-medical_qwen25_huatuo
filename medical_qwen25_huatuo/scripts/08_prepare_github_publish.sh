#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory

PROJECT_DIR="medical_qwen25_huatuo"

git rev-parse --is-inside-work-tree >/dev/null

git add "$PROJECT_DIR"

echo "Staged files under $PROJECT_DIR:"
git diff --cached --name-status -- "$PROJECT_DIR"

echo
echo "Next steps:"
echo "  git commit -m \"Add Huatuo26M-Lite Qwen2.5 LoRA eval and publish workflow\""
echo "  git push origin $(git branch --show-current)"
