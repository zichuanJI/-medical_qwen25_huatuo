#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LLAMA_FACTORY_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

cd "$LLAMA_FACTORY_ROOT"
llamafactory-cli export medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_merge.yaml
