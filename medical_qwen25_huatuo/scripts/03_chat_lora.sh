#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory
llamafactory-cli chat medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_infer.yaml
