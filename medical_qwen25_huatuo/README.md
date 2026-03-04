# Qwen2.5-7B-Instruct + Huatuo26M-Lite 医疗 LoRA 微调

这个目录是一套独立的、可直接放进 GitHub 的项目模板，用来在当前 LLaMA-Factory 镜像里，把 `Qwen/Qwen2.5-7B-Instruct` 用 `FreedomIntelligence/Huatuo26M-Lite` 做医疗领域 LoRA 微调。

我把所有文件都放在 `medical_qwen25_huatuo/` 下，原因很简单：

- 不覆盖镜像原本的顶层 `README.md`
- 不修改仓库根目录下已经被你改动过的 `data/dataset_info.json`
- 方便你把这一整套流程单独上传到 GitHub

## 目录说明

- `configs/qwen2_5_huatuo_lora_sft.yaml`：LoRA SFT 训练配置
- `configs/qwen2_5_huatuo_lora_infer.yaml`：LoRA 推理配置
- `configs/qwen2_5_huatuo_lora_merge.yaml`：LoRA 合并配置
- `dataset/dataset_info.json`：这个项目自己的数据集注册文件
- `scripts/prepare_huatuo26m_lite.py`：从 Hugging Face 下载并转换 Huatuo26M-Lite
- `scripts/01_prepare_dataset.sh`：数据集准备脚本
- `scripts/02_train_lora.sh`：训练脚本
- `scripts/03_chat_lora.sh`：加载 LoRA 对话测试脚本
- `scripts/04_merge_lora.sh`：合并 LoRA 权重脚本
- `scripts/05_webui.sh`：启动镜像 WebUI 脚本
- `scripts/06_eval_benchmarks.sh`：训练后 benchmark 评测脚本
- `scripts/07_publish_huggingface.sh`：发布到 Hugging Face 的脚本
- `scripts/08_prepare_github_publish.sh`：准备发布到 GitHub 的脚本
- `scripts/publish_huggingface.py`：上传本地目录到 Hugging Face Hub
- `docs/EVAL_AND_PUBLISH.md`：训练完成后的评测与发布说明
- `.gitignore`：忽略数据、报告、checkpoint 和导出模型

## 为什么这次不走镜像里的“数据集全自动处理”

镜像自带的 `数据集全自动处理/` 和 `chuli/单多轮脚本/` 更适合把你手写的 txt 问答、文章文本、对话文本转成训练集。

但 `Huatuo26M-Lite` 本身已经是结构化数据集，核心字段就是：

- `instruction`
- `input`
- `output`

所以这次最稳的做法不是再走一遍 txt 转换流程，而是直接下载数据集，然后转成 LLaMA-Factory 能直接读的 `jsonl` 文件。

## 环境建议

这份镜像明显是面向 Linux / AutoDL 一类环境的，因为自带脚本使用的是：

- `/root/LLaMA-Factory`
- `source activate llama`

建议环境：

- 系统：Linux 镜像 / AutoDL
- GPU：建议 24GB 显存起步
- 磁盘：至少预留 50GB
- Python 环境：优先使用镜像已有的 `llama` 环境

如果显存不够：

- 把 `cutoff_len` 从 `2048` 改成 `1024`
- 适当减小 `gradient_accumulation_steps`
- 或者在 `configs/qwen2_5_huatuo_lora_sft.yaml` 里增加 `quantization_bit: 4` 改成 QLoRA

## 一步一步执行

### 第 1 步：进入镜像并激活环境

```bash
cd /root/LLaMA-Factory
source activate llama
```

如果镜像里的依赖不完整，再补一次：

```bash
pip install -e .
pip install -U datasets huggingface_hub transformers accelerate
```

### 第 2 步：准备基础模型

本项目默认基础模型是：

- `Qwen/Qwen2.5-7B-Instruct`

如果你习惯提前下载到本地目录，可以这样：

```bash
huggingface-cli download Qwen/Qwen2.5-7B-Instruct --local-dir /root/autodl-tmp/Qwen2.5-7B-Instruct
```

如果你改成了本地路径，请同步修改下面 3 个配置文件中的 `model_name_or_path`：

- `configs/qwen2_5_huatuo_lora_sft.yaml`
- `configs/qwen2_5_huatuo_lora_infer.yaml`
- `configs/qwen2_5_huatuo_lora_merge.yaml`

### 第 3 步：下载并转换 Huatuo26M-Lite

直接运行：

```bash
bash medical_qwen25_huatuo/scripts/01_prepare_dataset.sh
```

如果你想先做一次小规模冒烟测试：

```bash
bash medical_qwen25_huatuo/scripts/01_prepare_dataset.sh --max-samples 2000
```

生成结果：

- `medical_qwen25_huatuo/dataset/huatuo26m_lite_sft.jsonl`
- `medical_qwen25_huatuo/dataset/prepare_report.json`

转换后的单条数据格式如下：

```json
{"instruction": "...", "input": "...", "output": "..."}
```

### 第 4 步：确认项目自己的数据集注册文件

这个项目不依赖根目录的 `data/dataset_info.json`，而是单独使用：

- `medical_qwen25_huatuo/dataset/dataset_info.json`

训练配置里已经写好了：

- `dataset_dir: medical_qwen25_huatuo/dataset`
- `dataset: huatuo26m_lite_med_sft`

所以你不用再去改镜像原本的数据注册文件。

### 第 5 步：开始 LoRA 训练

运行：

```bash
bash medical_qwen25_huatuo/scripts/02_train_lora.sh
```

等价命令：

```bash
llamafactory-cli train medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_sft.yaml
```

当前默认训练参数：

- 基础模型：`Qwen/Qwen2.5-7B-Instruct`
- 训练方式：LoRA SFT
- 模板：`qwen`
- `lora_target: all`
- `lora_rank: 16`
- `learning_rate: 5e-5`
- `cutoff_len: 2048`
- `val_size: 0.01`

输出目录：

- `medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft`

### 第 6 步：如果你更喜欢图形界面，就启动 WebUI

```bash
bash medical_qwen25_huatuo/scripts/05_webui.sh
```

然后在 WebUI 里填写关键参数：

- Model name or path：`Qwen/Qwen2.5-7B-Instruct`
- Finetuning method：`lora`
- Stage：`sft`
- Dataset dir：`medical_qwen25_huatuo/dataset`
- Dataset：`huatuo26m_lite_med_sft`
- Template：`qwen`
- Output dir：`medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/lora/sft`

如果你直接走 CLI，这一步可以跳过。

### 第 7 步：加载 LoRA 做对话测试

```bash
bash medical_qwen25_huatuo/scripts/03_chat_lora.sh
```

等价命令：

```bash
llamafactory-cli chat medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_infer.yaml
```

### 第 8 步：如需独立模型，合并 LoRA

```bash
bash medical_qwen25_huatuo/scripts/04_merge_lora.sh
```

合并后的输出目录：

- `medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/merged`

注意：

- 不要从量化后的基座模型直接做 merge

## 训练完成后如何评测与发布

我另外补了一份专门文档：

- `medical_qwen25_huatuo/docs/EVAL_AND_PUBLISH.md`

配套脚本：

- 评测：`bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh`
- 发布 Hugging Face：`bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh`
- 准备发布 GitHub：`bash medical_qwen25_huatuo/scripts/08_prepare_github_publish.sh`

## 建议上传到 GitHub 的文件

建议上传：

- `medical_qwen25_huatuo/README.md`
- `medical_qwen25_huatuo/docs/EVAL_AND_PUBLISH.md`
- `medical_qwen25_huatuo/configs/`
- `medical_qwen25_huatuo/dataset/dataset_info.json`
- `medical_qwen25_huatuo/scripts/`
- `medical_qwen25_huatuo/.gitignore`

不建议上传：

- 基础模型权重
- 完整下载后的训练数据 `jsonl`
- Hugging Face cache
- 训练输出 `outputs/`
- 评测输出 `reports/`
- 合并后的完整模型

这样别人 clone 你的仓库后，只要重新执行数据准备脚本，就可以复现整个流程。

## 建议仓库结构

```text
medical_qwen25_huatuo/
|- README.md
|- .gitignore
|- configs/
|  |- qwen2_5_huatuo_lora_sft.yaml
|  |- qwen2_5_huatuo_lora_infer.yaml
|  `- qwen2_5_huatuo_lora_merge.yaml
|- dataset/
|  `- dataset_info.json
|- docs/
|  `- EVAL_AND_PUBLISH.md
`- scripts/
   |- 01_prepare_dataset.sh
   |- 02_train_lora.sh
   |- 03_chat_lora.sh
   |- 04_merge_lora.sh
   |- 05_webui.sh
   |- 06_eval_benchmarks.sh
   |- 07_publish_huggingface.sh
   |- 08_prepare_github_publish.sh
   |- prepare_huatuo26m_lite.py
   `- publish_huggingface.py
```

## 可复现性说明

- 当前仓库已经支持 `Qwen2.5` 微调，并且有 `qwen` 模板，所以这套配置能直接对接镜像现有能力。
- 数据转换脚本故意只保留 `instruction`、`input`、`output`，因为做 SFT 这 3 个字段已经够用。
- 建议先用 `--max-samples` 小样本试跑，确认环境没问题再上全量数据。

## 参考链接

- Huatuo26M-Lite: https://huggingface.co/datasets/FreedomIntelligence/Huatuo26M-Lite
- Qwen2.5-7B-Instruct: https://huggingface.co/Qwen/Qwen2.5-7B-Instruct
- LLaMA-Factory: https://github.com/hiyouga/LLaMA-Factory
