---
name: vllm-cli
description: >-
  Launch vLLM services and run online serving benchmarks via CLI inside a Docker
  container. Maintains two reusable scripts: start_server.sh (start vLLM OpenAI API)
  and run_benchmark.sh (vllm bench serve). Trigger when the user asks to start/serve
  a vLLM model, run benchmark/pressure test, or test model performance. Handles
  three workflows: (1) start server, (2) run benchmark, (3) combined workflow.
  When the user changes environment config (container name, paths, etc.), update
  the script defaults accordingly.
---

# vllm-cli

启动 vLLM 服务和运行在线压测的 CLI 工具，维护两个可复用脚本。

## 脚本结构

```
vllm-cli/
├── SKILL.md
├── scripts/
│   ├── start_server.sh     # 启动 vLLM API server
│   └── run_benchmark.sh    # 运行在线压测
└── evals/
    └── evals.json
```

### start_server.sh

在 Docker 容器中启动 vLLM OpenAI-compatible API server。

```bash
# 基本用法
./scripts/start_server.sh --model /workspace/models/Qwen3-0.6B --port 8000

# 指定额外参数
./scripts/start_server.sh -m /workspace/models/Qwen3-0.6B -p 8001 --gpu-memory-utilization 0.8
```

**参数**：

| 参数 | 简写 | 默认值 | 说明 |
|------|------|--------|------|
| `--model` | `-m` | (必填) | 模型路径 |
| `--port` | `-p` | 8000 | 服务端口 |
| `--host` | - | 0.0.0.0 | 监听地址 |

其他未识别的参数透传给 `vllm serve`（如 `--gpu-memory-utilization`, `--tensor-parallel-size` 等）。

### run_benchmark.sh

对运行中的 vLLM 服务执行在线压测。

```bash
# 基本用法
./scripts/run_benchmark.sh --model /workspace/models/Qwen3-0.6B --base-url http://127.0.0.1:8000

# 指定压测参数
./scripts/run_benchmark.sh -m Qwen3-0.6B -u http://127.0.0.1:8000 -r 10 -n 200 --input-len 512 --output-len 128
```

**参数**：

| 参数 | 简写 | 默认值 | 说明 |
|------|------|--------|------|
| `--model` | `-m` | (必填) | 模型名称或路径 |
| `--base-url` | `-u` | http://127.0.0.1:8000 | 服务地址 |
| `--host` | - | 127.0.0.1 | 主机（未指定 base-url 时用） |
| `--port` | `-p` | 8000 | 端口（未指定 base-url 时用） |
| `--backend` | `-b` | openai | 后端类型 |
| `--request-rate` | `-r` | inf | 每秒请求数 |
| `--num-prompts` | `-n` | 1000 | 请求总数 |
| `--input-len` | - | (dataset default) | 输入长度 |
| `--output-len` | - | (dataset default) | 输出长度 |
| `--dataset` | `-d` | random | 数据集类型 |
| `--result-dir` | - | (不保存) | 结果保存目录 |

## 环境配置维护

**两个脚本顶部的环境变量区域定义了所有路径配置**，这是维护的入口：

```bash
# ---------- 环境配置（按需修改） ----------
DOCKER_CONTAINER="${VLLM_DOCKER_CONTAINER:-lw_agent}"
VENV_PATH="${VLLM_VENV_PATH:-/workspace/vllm-0.21.0/.venv}"
PROJECT_PATH="${VLLM_PROJECT_PATH:-/workspace/vllm-0.21.0}"
DEFAULT_PORT="${VLLM_DEFAULT_PORT:-8000}"
DEFAULT_HOST="${VLLM_DEFAULT_HOST:-0.0.0.0}"
# -----------------------------------------
```

### 何时更新

当用户发生以下变更时，**必须同时更新两个脚本**的环境配置区域：

1. **容器变更**：容器名称或挂载路径变化 → 更新 `DOCKER_CONTAINER`、`VENV_PATH`、`PROJECT_PATH`
2. **Python 环境变更**：venv 路径变化 → 更新 `VENV_PATH`、`PROJECT_PATH`
3. **默认端口变更** → 更新 `DEFAULT_PORT`

### 更新方式

通过 `Edit` 工具编辑脚本中 `# ---------- 环境配置 ----------` 区域内的变量默认值。变量支持通过同名环境变量覆盖（如 `VLLM_DOCKER_CONTAINER=new_container`），修改默认值时同时保持此机制。

## 工作流模式

### Mode 1：启动服务

```bash
./scripts/start_server.sh --model <model> --port <port>
```

- 服务在前台运行，`Ctrl+C` 停止
- 如需后台运行，用户应使用 `docker exec -d` 或 `nohup`

### Mode 2：运行压测（服务须已运行）

```bash
./scripts/run_benchmark.sh --model <model> --base-url <url> --request-rate <n> --num-prompts <n>
```

### Mode 3：测试性能（自动：启动 → 压测 → 清理）

1. 先在后台启动服务
2. 等待服务就绪（轮询 `/v1/models`）
3. 执行压测
4. 询问是否停止服务

## 故障处理

### GPU 显存不足
```bash
# 查看 GPU 状态
docker exec lw_agent nvidia-smi

# 指定其他 GPU
CUDA_VISIBLE_DEVICES=1 ./scripts/start_server.sh --model <model> --port 8000

# 调低显存利用率
./scripts/start_server.sh --model <model> --port 8000 --gpu-memory-utilization 0.6
```

### 服务无响应
```bash
# 检查服务日志
docker exec lw_agent cat /tmp/vllm_server_<port>.log

# 检查进程
docker exec lw_agent ps aux | grep vllm
```

### 端口冲突
```bash
# 查看端口占用
docker exec lw_agent bash -c "ss -tlnp | grep <port>"

# 换端口启动
./scripts/start_server.sh --model <model> --port <new_port>
```