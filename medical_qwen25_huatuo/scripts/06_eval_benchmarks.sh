#!/bin/bash
set -euo pipefail

cd /root/LLaMA-Factory

STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="medical_qwen25_huatuo/reports/eval/$STAMP"
TMP_DIR="medical_qwen25_huatuo/tmp"
mkdir -p "$ROOT" "$TMP_DIR"

BATCH_SIZE="${EVAL_BATCH_SIZE:-4}"
N_SHOT="${EVAL_N_SHOT:-5}"
TARGET="${EVAL_TARGET:-all}"

run_eval() {
  local name="$1"
  local task="$2"
  local lang="$3"
  local save_dir="$ROOT/$name"
  local config_path="$TMP_DIR/${name}_eval_${STAMP}.yaml"

  cat > "$config_path" <<EOF
### model
model_name_or_path: Qwen/Qwen2.5-7B-Instruct
adapter_name_or_path: medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft

### method
finetuning_type: lora

### dataset
task: $task
template: fewshot
lang: $lang
n_shot: $N_SHOT

### output
save_dir: $save_dir

### eval
batch_size: $BATCH_SIZE
EOF

  echo "Running $name evaluation..."
  llamafactory-cli eval "$config_path"
}

if [[ ! -d "medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft" ]]; then
  echo "LoRA adapter directory not found. Train the model first." >&2
  exit 1
fi

case "$TARGET" in
  all)
    run_eval "mmlu" "mmlu_test" "en"
    run_eval "cmmlu" "cmmlu_test" "zh"
    ;;
  mmlu)
    run_eval "mmlu" "mmlu_test" "en"
    ;;
  cmmlu)
    run_eval "cmmlu" "cmmlu_test" "zh"
    ;;
  *)
    echo "EVAL_TARGET must be one of: all, mmlu, cmmlu" >&2
    exit 1
    ;;
esac

echo "Evaluation reports saved under: $ROOT"
