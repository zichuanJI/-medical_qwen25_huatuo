#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LLAMA_FACTORY_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

cd "$LLAMA_FACTORY_ROOT"
python medical_qwen25_huatuo/scripts/prepare_huatuo26m_lite.py "$@"
