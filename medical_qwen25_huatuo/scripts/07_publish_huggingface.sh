#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory

TARGET="${HF_TARGET:-adapter}"
PRIVATE_FLAG=""
if [[ "${HF_PRIVATE:-0}" == "1" ]]; then
  PRIVATE_FLAG="--private"
fi

ADAPTER_DIR="medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft"
MERGED_DIR="medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/merged"

upload_dir() {
  local repo_id="$1"
  local local_dir="$2"
  local commit_message="$3"

  if [[ -z "$repo_id" ]]; then
    echo "Missing repo id for upload target: $local_dir" >&2
    exit 1
  fi

  python medical_qwen25_huatuo/scripts/publish_huggingface.py \
    --repo-id "$repo_id" \
    --local-dir "$local_dir" \
    $PRIVATE_FLAG \
    --commit-message "$commit_message"
}

if [[ "$TARGET" != "adapter" && "$TARGET" != "merged" && "$TARGET" != "both" ]]; then
  echo "HF_TARGET must be one of: adapter, merged, both" >&2
  exit 1
fi

if [[ "$TARGET" == "adapter" || "$TARGET" == "both" ]]; then
  if [[ ! -d "$ADAPTER_DIR" ]]; then
    echo "Adapter directory not found: $ADAPTER_DIR" >&2
    echo "Run training first." >&2
    exit 1
  fi
  upload_dir "${HF_ADAPTER_REPO_ID:-}" "$ADAPTER_DIR" "Upload LoRA adapter from medical_qwen25_huatuo"
fi

if [[ "$TARGET" == "merged" || "$TARGET" == "both" ]]; then
  if [[ ! -d "$MERGED_DIR" || "${HF_FORCE_MERGE:-0}" == "1" ]]; then
    llamafactory-cli export medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_merge.yaml
  fi
  upload_dir "${HF_MERGED_REPO_ID:-}" "$MERGED_DIR" "Upload merged model from medical_qwen25_huatuo"
fi

echo "Done."
