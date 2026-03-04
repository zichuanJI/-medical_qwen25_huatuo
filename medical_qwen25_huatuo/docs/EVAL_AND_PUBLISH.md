# 训练完成后的评测与发布

这份文档对应 `medical_qwen25_huatuo/` 这套项目模板，目标是解决两个问题：

- 训练完成后，怎么判断模型到底有没有变好
- 训练完成后，怎么把结果发布到 Hugging Face 和 GitHub

建议你把这件事拆成 3 层来做，而不是只看一次对话效果：

1. 先看训练日志有没有明显异常
2. 再跑标准 benchmark 评测
3. 最后做医疗场景人工抽检

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
- 是否出现 `nan`、`inf`、OOM、中途重启

如果训练日志本身就不正常，先不要急着发布。

## 2. 跑 benchmark 评测

当前仓库自带 LLaMA-Factory 的评测能力，可以直接跑：

- `mmlu_test`
- `cmmlu_test`

对这个中文医疗项目，我更建议至少跑两组：

- `MMLU`：看英文通用学科泛化
- `CMMLU`：看中文学科能力

执行脚本：

```bash
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

## 3. 做医疗场景人工抽检

benchmark 只能说明一部分问题，医疗场景一定要补人工抽检。

建议至少准备 20 到 50 条你真正关心的问题，覆盖这些类型：

- 常见病问答
- 药物与用药注意事项
- 检查指标解释
- 医学科普改写
- 高风险问题的拒答与安全边界

推荐你从 4 个维度打分：

- 准确性
- 完整性
- 中文表达
- 安全性

最简单的办法：

1. 用 `bash medical_qwen25_huatuo/scripts/03_chat_lora.sh` 进入对话
2. 固定一批测试题
3. 把原模型回答和 LoRA 后回答并排比较
4. 人工记录优点、错误和风险回答

## 4. 发布到 Hugging Face 的两种方式

最常见有两种：

- 发布 LoRA adapter
- 发布 merge 后的完整模型

### 4.1 更推荐先发布 adapter

原因：

- 文件更小
- 上传更快
- 别人可以基于官方底模自行加载
- 对公开仓库更友好

执行：

```bash
HF_TARGET=adapter \
HF_ADAPTER_REPO_ID=your-name/qwen2_5_7b_huatuo_lora \
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

### 4.2 如果你要给别人一个开箱即用版本，再发布 merged model

执行：

```bash
HF_TARGET=merged \
HF_MERGED_REPO_ID=your-name/qwen2_5_7b_huatuo_merged \
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

如果 merged 目录不存在，脚本会先自动执行：

- `llamafactory-cli export medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_merge.yaml`

### 4.3 一次同时发布 adapter 和 merged

```bash
HF_TARGET=both \
HF_ADAPTER_REPO_ID=your-name/qwen2_5_7b_huatuo_lora \
HF_MERGED_REPO_ID=your-name/qwen2_5_7b_huatuo_merged \
bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

### 4.4 公开或私有仓库

默认公开。

如果你想先发私有仓库：

```bash
HF_PRIVATE=1 HF_TARGET=adapter HF_ADAPTER_REPO_ID=your-name/private-repo bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh
```

## 5. 发布到 Hugging Face 前的检查清单

正式发布前，建议确认：

- 你是否遵守了基础模型的 license
- 你是否确认训练数据可以公开传播
- 你是否明确写清楚这是医疗问答微调模型，不是执业医生
- 你是否在模型页写清楚适用范围和风险边界
- 你是否说明这是 adapter 还是 merged model

## 6. 发布到 GitHub

这个仓库目前不是干净工作区，所以我不建议写一个“自动 commit + 自动 push”的激进脚本。

更稳的方式是：

1. 先只 stage `medical_qwen25_huatuo/`
2. 手动检查差异
3. 再决定 commit 和 push

执行：

```bash
bash medical_qwen25_huatuo/scripts/08_prepare_github_publish.sh
```

这个脚本会：

- 只暂存 `medical_qwen25_huatuo/`
- 打印已暂存文件
- 给出后续 commit / push 提示

然后你再手动执行：

```bash
git commit -m "Add Huatuo26M-Lite Qwen2.5 LoRA eval and publish workflow"
git push origin <your-branch>
```

## 7. 推荐上传到 GitHub 的内容

建议上传：

- `medical_qwen25_huatuo/README.md`
- `medical_qwen25_huatuo/docs/EVAL_AND_PUBLISH.md`
- `medical_qwen25_huatuo/configs/`
- `medical_qwen25_huatuo/dataset/dataset_info.json`
- `medical_qwen25_huatuo/scripts/`
- `medical_qwen25_huatuo/.gitignore`

不要上传：

- `outputs/`
- `reports/`
- `tmp/`
- 基础模型权重
- merged 后的完整模型
- 全量训练数据导出文件

## 8. 你最终至少应该保留的发布资产

如果你要做一个最小可复现仓库，至少保留：

- 数据准备脚本
- 训练配置
- 评测脚本
- 发布脚本
- README
- 训练参数说明

这样别人拿到你的仓库，才能真正复现，而不是只能看截图。
