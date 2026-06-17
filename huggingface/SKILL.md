---
name: huggingface
description: 从 HuggingFace / ModelScope 下载和上传模型。当用户提到下载模型、上传模型、从 HuggingFace 拉取模型、使用 modelscope 下载模型，或者需要获取预训练模型权重时使用此技能。适用于任何需要模型下载或上传的场景，包括用户明确指定模型名称和路径的情况，以及用户不确定模型信息需要引导的情况。
---

# HuggingFace 模型管理

帮助用户从 HuggingFace / ModelScope 下载和上传模型。由于 HuggingFace hf-mirror 的 xet 协议可能超时不可用，使用 ModelScope 国内源作为替代下载源。

## 核心工作流程

### 下载模型

#### 第 1 步：确认模型信息

与用户沟通确认以下两个参数。如果用户已经明确给出，直接使用；如果用户不确定，主动询问：

- **MODEL_NAME**: 模型名称，格式为 `组织/模型名`（例如 `Qwen/Qwen3-0.6B`）
  - 如果用户只给了模型名没有给组织名，询问完整名称
  - 如果用户不确定，可以给出常见模型建议（如 Qwen、LLaMA、ChatGLM 系列）

- **LOCAL_DIR**: 模型下载到本地的**父目录**路径
  - 路径应是宿主机上的路径，而非容器路径
  - 如果用户没有指定，建议一个合理的路径（如 `/data/liuwang08/lw/models`）
  - 需要确保路径是绝对路径
  - **注意**：实际下载时会自动在 LOCAL_DIR 下创建以模型简称命名的子目录（例如模型 `Qwen/Qwen3-0.6B` 会下载到 `<LOCAL_DIR>/Qwen3-0.6B/`）

#### 第 2 步：环境检查

在确认模型信息后、执行下载前，运行环境检查脚本：

```bash
bash <skill_path>/scripts/check_env.sh
```

根据检查结果执行不同分支：

**情况 A：modelscope 已安装**
- 直接使用 modelscope 下载，跳到第 3 步

**情况 B：modelscope 未安装，hf-mirror 访问正常且速度足够**
- 告知用户 hf-mirror 可用，提示用户选择：
  1. 直接使用 huggingface-cli 从 hf-mirror 下载
  2. 安装 modelscope 后再下载
- 根据用户选择执行

**情况 C：modelscope 未安装，hf-mirror 不可用或速度很慢**
- 告知用户 hf-mirror 速度慢，建议安装 modelscope
- 询问用户是否同意安装 modelscope：
  - 同意：执行 `pip install modelscope`
  - 不同意：告知用户下载可能失败或很慢，让用户自行决定是否继续
- 安装完成后跳到第 3 步

#### 第 3 步：展示并确认

向用户展示将要执行的下载信息：

```bash
MODEL_NAME="<确认的模型名称>"
MODEL_SHORT_NAME="<模型简称（自动提取）>"
BASE_DIR="<确认的本地父目录路径>"
ACTUAL_DIR="<BASE_DIR>/<MODEL_SHORT_NAME>"
```

以及使用的下载方式（modelscope / huggingface-cli）。

**提示用户**：模型文件将自动下载到 `<BASE_DIR>/<MODEL_SHORT_NAME>/` 子目录下。

询问用户是否确认下载。

#### 第 4 步：执行下载

根据选择的下载方式执行：

**使用 modelscope（推荐）：**
```bash
bash <skill_path>/scripts/download_model.sh <MODEL_NAME> <BASE_DIR>
```
脚本会自动提取模型简称并在 BASE_DIR 下创建 `<MODEL_SHORT_NAME>/` 子目录。

**使用 huggingface-cli：**
```bash
MODEL_SHORT_NAME="${MODEL_NAME#*/}"
mkdir -p <BASE_DIR>/${MODEL_SHORT_NAME}
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download <MODEL_NAME> --local-dir <BASE_DIR>/${MODEL_SHORT_NAME}
```

#### 第 5 步：验证结果

下载完成后，向用户报告结果：
- 模型文件数量（safetensors / json 等）
- 模型大小
- 实际下载路径（`<BASE_DIR>/<MODEL_SHORT_NAME>/`）

### 上传模型

#### 第 1 步：确认模型信息

与用户沟通确认：
- **MODEL_NAME**: 上传后的模型名称，格式为 `组织/模型名`
- **LOCAL_DIR**: 本地模型路径

#### 第 2 步：执行上传

```bash
bash <skill_path>/scripts/upload_model.sh <MODEL_NAME> <LOCAL_DIR>
```

## 注意事项

1. **路径规则**：用户指定的 LOCAL_DIR 为**父目录**，实际下载路径为 `<LOCAL_DIR>/<MODEL_SHORT_NAME>/`（模型简称子目录）
2. **用户确认**：执行任何操作前（安装、下载、上传），必须先让用户确认
3. **路径检查**：下载前检查实际路径（`<BASE_DIR>/<MODEL_SHORT_NAME>/`）是否存在，如果存在询问用户是否覆盖
4. **错误处理**：如果下载失败，提示用户检查模型名称是否正确、网络是否通畅
5. **源选择优先级**：modelscope > hf-mirror > 官方 HuggingFace