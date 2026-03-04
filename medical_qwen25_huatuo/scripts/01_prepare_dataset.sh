#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory
python medical_qwen25_huatuo/scripts/prepare_huatuo26m_lite.py "$@"
