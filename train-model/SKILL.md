---
name: train-model
description: 在 Docker 容器中训练模型。读取 train-env.json 获取容器信息和路径配置，分析项目的训练方式，询问用户需求后启动后台训练，并监控训练状态。当用户需要在 Docker 容器中训练深度学习模型时使用此技能。
---

# 模型训练器

在 Docker 容器中训练深度学习模型。

## 核心原则

1. **命令在容器内执行** - 所有训练命令都通过 `docker exec` 在指定容器内执行
2. **后台训练** - 训练任务在后台运行，不阻塞用户操作
3. **日志记录** - 训练日志重定向到 `train_log/*.log` 文件
4. **启动监控** - 等待训练启动，确保任务正常运行

## 环境配置

### train-env.json

从项目目录下的 `train-env.json` 文件读取训练环境配置：

```json
{
  "docker": {
    "container_name": "lw_vlm_infer",
    "mount": {
      "host": "/data/liuwang08",
      "container": "/mount"
    }
  },
  "uv_env": {
    "container_path": "/mount/work_spec/project/.venv"
  },
  "container_paths": {
    "model": "/mount/work_spec/project/models",
    "dataset": "/mount/work_spec/project/data"
  }
}
```

**字段说明**：
- `docker.container_name`: Docker 容器名称
- `docker.mount.host`: 开发机挂载路径
- `docker.mount.container`: 容器内挂载路径
- `uv_env.container_path`: uv 虚拟环境在容器内的路径
- `container_paths.model`: 模型文件在容器内的路径
- `container_paths.dataset`: 数据集在容器内的路径

## 工作流程

### 第 1 步：读取配置

读取项目目录下的 `train-env.json`：
- `docker.container_name` → 容器名称
- `uv_env.container_path` → uv 环境路径
- `container_paths.model` → 模型路径
- `container_paths.dataset` → 数据集路径

如果 `train-env.json` 不存在，提示用户创建。

### 第 2 步：分析项目训练方式

**读取项目 README.md**，分析以下内容：

1. **训练脚本** - 项目提供哪些训练脚本或命令
2. **训练参数** - 支持哪些训练参数（学习率、batch size、epochs 等）
3. **资源需求** - 需要什么模型权重、数据集格式
4. **配置文件** - 是否需要配置文件（如 config.yaml）

将分析结果整理后展示给用户。

### 第 3 步：询问用户需求

向用户确认以下信息：

1. **训练方式** - 选择哪种训练方式（如果有多种）
2. **GPU 选择** - 使用哪些 GPU（如 0,1 或 0,1,2,3）
3. **训练参数** - 是否需要调整默认参数
4. **其他配置** - 根据项目需求询问

### 第 4 步：创建日志目录

在项目目录下创建 `train_log/` 目录（如果不存在）：

```bash
mkdir -p <project_path>/train_log
```

### 第 5 步：启动后台训练

**生成训练命令**：

```bash
# 基本模板
docker exec -it <container_name> bash -c "cd <container_project_path> && source <uv_env_path>/bin/activate && CUDA_VISIBLE_DEVICES=<gpus> nohup python <train_script> <args> > train_log/<log_file>.log 2>&1 &"
```

**示例**：
```bash
# 单 GPU 训练
docker exec -it lw_vlm_infer bash -c "cd /mount/work_spec/project && source .venv/bin/activate && CUDA_VISIBLE_DEVICES=0 nohup python train.py --config config.yaml > train_log/train_20260502_120000.log 2>&1 &"

# 多 GPU 训练
docker exec -it lw_vlm_infer bash -c "cd /mount/work_spec/project && source .venv/bin/activate && CUDA_VISIBLE_DEVICES=0,1 nohup python train.py --config config.yaml > train_log/train_20260502_120000.log 2>&1 &"
```

**日志文件命名规则**：`train_<YYYYMMDD>_<HHMMSS>.log`

### 第 6 步：监控训练启动

启动训练后，进入监控流程：

1. **等待 1 分钟**，然后检查训练进程
2. 如果未启动，**继续等待**，每次等待 1 分钟
3. **累计等待时间不超过 5 分钟**

**检查训练进程**：
```bash
# 检查是否有 python 训练进程在运行
docker exec -it <container_name> bash -c "ps aux | grep python | grep -v grep"
```

**检查日志文件**：
```bash
# 查看日志文件是否有输出
docker exec -it <container_name> bash -c "tail -20 <container_project_path>/train_log/<log_file>.log"
```

### 第 7 步：反馈训练状态

**训练启动成功**：
```
训练已成功启动！

日志文件：<project_path>/train_log/<log_file>.log
GPU 使用：<gpus>

查看训练进度：
  tail -f <project_path>/train_log/<log_file>.log

查看 GPU 使用情况：
  docker exec -it <container_name> nvidia-smi
```

**训练启动失败**：
```
训练未能成功启动。

可能的原因：
1. 训练脚本路径错误
2. 依赖缺失
3. GPU 资源不足

请查看日志文件排查问题：
  cat <project_path>/train_log/<log_file>.log
```

## 常见场景

### 场景 1：使用配置文件训练

```bash
docker exec -it <container_name> bash -c "cd <container_project_path> && source <uv_env_path>/bin/activate && CUDA_VISIBLE_DEVICES=<gpus> nohup python train.py --config configs/default.yaml > train_log/train.log 2>&1 &"
```

### 场景 2：使用 torchrun 多卡训练

```bash
docker exec -it <container_name> bash -c "cd <container_project_path> && source <uv_env_path>/bin/activate && CUDA_VISIBLE_DEVICES=<gpus> nohup torchrun --nproc_per_node=<num_gpus> train.py > train_log/train.log 2>&1 &"
```

### 场景 3：使用 accelerate 训练

```bash
docker exec -it <container_name> bash -c "cd <container_project_path> && source <uv_env_path>/bin/activate && CUDA_VISIBLE_DEVICES=<gpus> nohup accelerate launch train.py > train_log/train.log 2>&1 &"
```

### 场景 4：train-env.json 不存在

创建 `train-env.json` 文件：

```json
{
  "docker": {
    "container_name": "<容器名称>",
    "mount": {
      "host": "<开发机路径>",
      "container": "<容器内路径>"
    }
  },
  "uv_env": {
    "container_path": "<uv环境在容器内的路径>"
  },
  "container_paths": {
    "model": "<模型在容器内的路径>",
    "dataset": "<数据集在容器内的路径>"
  }
}
```

## 输出格式

训练启动后，向用户报告：

1. 训练状态（成功/失败）
2. 日志文件路径
3. 使用的 GPU
4. 查看进度的命令

## 注意事项

- 训练任务在容器内后台运行，不会阻塞用户
- 日志文件存储在项目的 `train_log/` 目录下
- 累计等待时间不超过 5 分钟
- 如果训练启动失败，查看日志文件排查问题
- 使用 `nvidia-smi` 监控 GPU 使用情况