# 训练完成后的评测与发布

这份文档对应 `medical_qwen25_huatuo/` 这套项目模板，目标是解决两个问题：

- 训练完成后，怎么判断模型到底有没有变好
- 训练完成后，怎么把结果发布到 Hugging Face 和 GitHub

默认前提：

- 你已经在 AutoDL 服务器上安装好了 `LLaMA-Factory`
- 当前项目已经放在 `LLaMA-Factory` 根目录下的 `medical_qwen25_huatuo/`
- 你已经激活训练环境，例如 `conda activate llama`

建议你把这件事拆成 4 层来做，而不是只看一次对话效果：

1. 先看训练日志有没有明显异常
2. 再跑标准 benchmark 评测
3. 最后做医疗场景人工抽检
4. 确认结果稳定后再发布

## 1. 先看训练结果目录

训练目录默认在：

- `medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft`

优先检查这些文件：

- `trainer_state.json`
- `train_results.json`
- `all_results.json`
- loss 曲线图
- `checkpoint-*`

重点看：

- `eval_loss` 是否比训练前更稳定
- loss 是否持续下降，而不是剧烈震荡
- 是否出现 `nan`
- 是否出现 `inf`
- 是否出现 OOM
- 是否发生中途重启

如果训练日志本身就不正常，先不要急着发布。

## 2. 跑 benchmark 评测

当前项目直接复用 `LLaMA-Factory` 的评测能力，可以跑：

- `mmlu_test`
- `cmmlu_test`

对这个中文医疗项目，建议至少跑两组：

- `MMLU`：看英文通用学科泛化
- `CMMLU`：看中文学科能力

执行方式：

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh
```

默认结果会输出到：

- `medical_qwen25_huatuo/reports/eval/<timestamp>/mmlu`
- `medical_qwen25_huatuo/reports/eval/<timestamp>/cmmlu`

如果只想跑中文：

```bash
EVAL_TARGET=cmmlu bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh
```

如果显存紧张，可以调小：

- `EVAL_BATCH_SIZE=1`
- `EVAL_N_SHOT=3`

例如：

```bash
EVAL_BATCH_SIZE=1 EVAL_N_SHOT=3 bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh
```

如果你的基础模型不是默认的 `Qwen/Qwen2.5-7B-Instruct`，可以在评测时覆盖：

```bash
BASE_MODEL_PATH=/root/autodl-tmp/Qwen2.5-7B-Instruct \
bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh
```

## 3. 做医疗场景人工抽检

benchmark 只能说明一部分问题，医疗场景一定要补人工抽检。

建议至少准备 20 到 50 条你真正关心的问题，覆盖这些类型：

- 常见病问答
- 药物与用药注意事项
- 检查指标解释
- 医学科普改写
- 高风险问题的拒答与安全边界

推荐从 4 个维度打分：

- 准确性
- 完整性
- 中文表达
- 安全性

最简单的办法：

1. 用 `bash medical_qwen25_huatuo/scripts/03_chat_lora.sh` 进入对话
2. 固定一批测试题
3. 把原模型回答和 LoRA 后回答并排比较
4. 人工记录优点、错误和风险回答

如果你愿意做得更稳一些，可以把人工测试题整理成固定表格，后续每次训练都复用同一套题。

## 4. 发布到 Hugging Face

### 发布前确认

至少确认这几件事：

- LoRA adapter 目录存在
- 如需发布 merged 模型，合并结果目录存在，或者允许脚本重新 merge
- 已经登录 Hugging Face，或者设置了 `HF_TOKEN`
- 已经想好目标仓库名

登录方式二选一：

```bash
huggingface-cli login
```

或：

```bash
export HF_TOKEN=hf_xxx
```

### 发布 LoRA adapter

```bash
cd /root/LLaMA-Factory
conda activate llama

export HF_ADAPTER_REPO_ID=<你的用户名>/<adapter仓库名>
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

默认 `HF_TARGET=adapter`，也就是只发布 LoRA adapter。

### 发布 merged 模型

```bash
cd /root/LLaMA-Factory
conda activate llama

export HF_TARGET=merged
export HF_MERGED_REPO_ID=<你的用户名>/<merged仓库名>
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

如果你想强制重新 merge 再上传：

```bash
HF_TARGET=merged HF_FORCE_MERGE=1 HF_MERGED_REPO_ID=<你的用户名>/<merged仓库名> \
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

### 同时发布 adapter 和 merged

```bash
HF_TARGET=both \
HF_ADAPTER_REPO_ID=<你的用户名>/<adapter仓库名> \
HF_MERGED_REPO_ID=<你的用户名>/<merged仓库名> \
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

### 可选环境变量

- `HF_TARGET`：`adapter`、`merged`、`both`
- `HF_PRIVATE=1`：创建私有仓库
- `HF_ADAPTER_REPO_ID`：adapter 上传目标
- `HF_MERGED_REPO_ID`：merged 上传目标
- `HF_FORCE_MERGE=1`：即使已有 merged 目录，也重新导出再上传
- `HF_TOKEN`：Hugging Face 访问令牌

## 5. 整理 GitHub 发布内容

如果你只准备上传这个项目目录，而不是整个 `LLaMA-Factory`，建议只提交这些内容：

- `README.md`
- `.gitignore`
- `configs/`
- `dataset/dataset_info.json`
- `docs/EVAL_AND_PUBLISH.md`
- `scripts/`

不要提交：

- `dataset/huatuo26m_lite_sft.jsonl`
- `dataset/prepare_report.json`
- `outputs/`
- `reports/`
- `tmp/`
- Hugging Face cache
- 合并后的完整模型

如果当前项目仍然位于 `LLaMA-Factory/medical_qwen25_huatuo/` 下，可以先在父仓库里查看会提交什么：

```bash
cd /root/LLaMA-Factory
bash medical_qwen25_huatuo/scripts/08_prepare_github_publish.sh
```

这个脚本会：

- 把 `medical_qwen25_huatuo/` 目录加入暂存区
- 显示当前暂存内容
- 提示下一步 `git commit` 和 `git push`

## 6. 建议的发布顺序

更稳的顺序是：

1. 先保留本地训练目录和日志，确认没有明显异常
2. 先跑 benchmark
3. 再做人工抽检
4. 如果结果满意，先发布 LoRA adapter
5. 确认合并模型没问题后，再发布 merged 模型
6. 最后把脚本、配置和文档推到 GitHub

## 7. 常见问题

### 为什么 benchmark 结果和聊天体验不完全一致

因为 benchmark 测的是标准化任务，不等于真实医疗问答场景。它能提供趋势参考，但不能替代人工抽检。

### 为什么评测脚本报找不到 adapter

因为默认会从这里读取 LoRA 输出：

- `medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft`

如果训练还没完成，或者输出目录被改过，评测会直接失败。

### 为什么发布 Hugging Face 时报认证问题

通常是因为：

- 没有执行 `huggingface-cli login`
- 没有设置 `HF_TOKEN`
- `HF_TOKEN` 权限不够
- 目标仓库名写错
