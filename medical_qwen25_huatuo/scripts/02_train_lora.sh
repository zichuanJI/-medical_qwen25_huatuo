#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory
llamafactory-cli train medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_sft.yaml
