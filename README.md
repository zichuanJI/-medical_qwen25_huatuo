# Qwen2.5-7B-Instruct + Huatuo26M-Lite 医疗 LoRA 微调

这个仓库用于把 `Qwen/Qwen2.5-7B-Instruct` 用 `FreedomIntelligence/Huatuo26M-Lite` 做医疗领域 LoRA 微调。

**如果对你有用，欢迎留下Star！**

1.  GitHub 仓库只放当前这套项目文件。
2. 使用者先在 AutoDL 服务器安装 `LLaMA-Factory`。
3. 再把这个仓库克隆到 `LLaMA-Factory` 根目录下的 `medical_qwen25_huatuo/`。
4. 然后按本文档一步一步执行。

## 这个仓库包含什么

1. `README.md`：从零安装到训练复现的主说明
2. `configs/qwen2_5_huatuo_lora_sft.yaml`：LoRA SFT 训练配置
3. `configs/qwen2_5_huatuo_lora_infer.yaml`：LoRA 推理配置
4. `configs/qwen2_5_huatuo_lora_merge.yaml`：LoRA 合并配置
5. `dataset/dataset_info.json`：项目自己的数据集注册文件
6. `scripts/prepare_huatuo26m_lite.py`：下载并转换 Huatuo26M-Lite
7. `scripts/01_prepare_dataset.sh`：准备数据集
8. `scripts/02_train_lora.sh`：启动训练
9. `scripts/03_chat_lora.sh`：加载 LoRA 做对话测试
10. `scripts/04_merge_lora.sh`：合并 LoRA 权重
11. `scripts/05_webui.sh`：启动 WebUI
12. `scripts/06_eval_benchmarks.sh`：训练后 benchmark 评测
13. `scripts/07_publish_huggingface.sh`：发布到 Hugging Face
14. `scripts/08_prepare_github_publish.sh`：整理 Git 提交
15. `docs/EVAL_AND_PUBLISH.md`：训练完成后的评测与发布说明
16. `.gitignore`：忽略数据、checkpoint、报告和导出模型

## 仓库结构

```text
.
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

## 环境建议

- 系统：Ubuntu / AutoDL
- GPU：建议 24GB 显存起步
- 磁盘：建议至少预留 50GB
- Python：建议 3.11
- 网络：需要能访问 GitHub 和 Hugging Face

如果显存不够，可以优先做这几件事：

- 把 `configs/qwen2_5_huatuo_lora_sft.yaml` 里的 `cutoff_len` 从 `2048` 改成 `1024`
- 适当减小 `gradient_accumulation_steps`
- 改成 QLoRA，例如增加 `quantization_bit: 4`

## 为什么不走“数据集全自动处理”

`Huatuo26M-Lite` 本身已经是结构化数据集，核心字段就是：

- `instruction`
- `input`
- `output`

因此最稳的做法不是先转 txt，再做数据清洗，而是直接下载原始数据集并转换成 LLaMA-Factory 能直接读取的 `jsonl` 文件。

## 从零开始复现

下面假设你拿到的是一台干净的 AutoDL 服务器，没有预装镜像。

### 第 1 步：创建环境并安装 LLaMA-Factory

官方 `LLaMA-Factory` README 给出的安装入口是：

```bash
cd /root
git clone --depth 1 https://github.com/hiyouga/LLaMA-Factory.git
cd /root/LLaMA-Factory

conda create -n llama python=3.11 -y
conda activate llama

pip install -e ".[torch,metrics]"
pip install -U datasets huggingface_hub transformers accelerate
```

如果你的 AutoDL 环境已经有可用的 `conda` 环境，也可以复用已有环境，但下面的命令默认都按 `llama` 环境来写。

### 第 2 步：把本项目克隆到正确位置

本仓库不是独立训练框架，而是依赖 `LLaMA-Factory` 的项目模板。

当前配置默认要求目录结构是：

```text
/root/LLaMA-Factory/
`- medical_qwen25_huatuo/
   |- README.md
   |- .gitignore
   |- configs/
   |- dataset/
   |- docs/
   `- scripts/
```

所以你的仓库应该这样克隆：

```bash
cd /root/LLaMA-Factory
git clone <你的GitHub仓库地址> medical_qwen25_huatuo
```

不要把仓库随便克隆成别的目录名。当前配置文件里仍然使用了 `medical_qwen25_huatuo/...` 这个相对路径。

### 第 3 步：可选，登录 Hugging Face

本项目默认会从 Hugging Face 下载：

- 基础模型：`Qwen/Qwen2.5-7B-Instruct`
- 数据集：`FreedomIntelligence/Huatuo26M-Lite`

如果你的环境需要登录再下载，可以执行：

```bash
huggingface-cli login
```

### 第 4 步：准备基础模型

默认配置直接使用：

- `Qwen/Qwen2.5-7B-Instruct`

你可以让 `transformers` 在训练时自动下载，也可以先手动下载到本地：

```bash
huggingface-cli download Qwen/Qwen2.5-7B-Instruct --local-dir /root/autodl-tmp/Qwen2.5-7B-Instruct
```

如果你改成本地路径，请同步修改下面 3 个文件里的 `model_name_or_path`：

- `configs/qwen2_5_huatuo_lora_sft.yaml`
- `configs/qwen2_5_huatuo_lora_infer.yaml`
- `configs/qwen2_5_huatuo_lora_merge.yaml`

### 第 5 步：下载并转换 Huatuo26M-Lite

直接运行：

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/01_prepare_dataset.sh
```

如果你想先做一个小规模冒烟测试：

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

### 第 6 步：确认项目自己的数据集注册文件

这个项目不依赖 `LLaMA-Factory` 根目录下的 `data/dataset_info.json`，而是单独使用：

- `medical_qwen25_huatuo/dataset/dataset_info.json`

训练配置已经写好：

- `dataset_dir: medical_qwen25_huatuo/dataset`
- `dataset: huatuo26m_lite_med_sft`

因此你不需要去修改官方仓库自带的数据集注册文件。

### 第 7 步：开始 LoRA 训练

运行：

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/02_train_lora.sh
```

等价命令：

```bash
llamafactory-cli train medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_sft.yaml
```

默认训练参数：

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

### 第 8 步：如果你更喜欢图形界面，就启动 WebUI

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/05_webui.sh
```

当前脚本会调用官方入口 `llamafactory-cli webui`。

### 第 9 步：加载 LoRA 做对话测试

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/03_chat_lora.sh
```

等价命令：

```bash
llamafactory-cli chat medical_qwen25_huatuo/configs/qwen2_5_huatuo_lora_infer.yaml
```

### 第 10 步：如需独立模型，合并 LoRA

```bash
cd /root/LLaMA-Factory
conda activate llama
bash medical_qwen25_huatuo/scripts/04_merge_lora.sh
```

合并后的输出目录：

- `medical_qwen25_huatuo/outputs/qwen2.5-7b-instruct/merged`

注意：

- 不要从量化后的基座模型直接做 merge

### 第 11 步：评测与发布

详细说明见：

- `docs/EVAL_AND_PUBLISH.md`

常用命令：

- 评测：`bash medical_qwen25_huatuo/scripts/06_eval_benchmarks.sh`
- 发布 Hugging Face：`bash medical_qwen25_huatuo/scripts/07_publish_huggingface.sh`
- 整理 Git 提交：`bash medical_qwen25_huatuo/scripts/08_prepare_github_publish.sh`

## 常见问题

### 1. 为什么脚本提示找不到路径

这些脚本现在会根据自己的位置自动定位 `LLaMA-Factory` 根目录，不再写死 `/root/LLaMA-Factory`。

但你仍然需要把仓库克隆成下面这个目录名：

```bash
/root/LLaMA-Factory/medical_qwen25_huatuo
```

原因不是脚本，而是配置文件里仍然写着 `medical_qwen25_huatuo/...` 这些相对路径。

### 2. 显存不够怎么办

优先尝试：

- 把 `cutoff_len` 改成 `1024`
- 减小 `gradient_accumulation_steps`
- 改成 QLoRA
- 先用 `--max-samples 2000` 做小样本验证

### 3. 为什么单独维护 `dataset/dataset_info.json`

这是为了不修改 `LLaMA-Factory` 官方仓库原本的 `data/dataset_info.json`，降低和上游仓库冲突的概率。

## 参考链接

- Huatuo26M-Lite: https://huggingface.co/datasets/FreedomIntelligence/Huatuo26M-Lite
- Qwen2.5-7B-Instruct: https://huggingface.co/Qwen/Qwen2.5-7B-Instruct
- LLaMA-Factory: https://github.com/hiyouga/LLaMA-Factory
