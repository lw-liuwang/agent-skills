---
name: uv-creator
description: 在 Docker 容器中创建 uv Python 虚拟环境。读取 sys-env.json 配置获取容器信息和挂载路径，检查系统环境（CUDA、Python 版本），使用 uv 创建项目专属的 Python 环境。当用户需要在 Docker 容器中搭建 Python 开发环境时使用此技能。
---

# UV 环境创建器

在 Docker 容器中使用 uv 创建 Python 虚拟环境。

## 核心原则

1. **命令在容器内执行** - 所有命令都通过 `docker exec` 在指定容器内执行
2. **环境本地化** - uv 环境创建在项目目录的 `.venv/` 中，不污染系统 Python
3. **路径映射** - 开发机路径与容器内路径通过挂载配置自动转换

## 环境配置

### sys-env.json

从项目目录下的 `sys-env.json` 文件读取 Docker 环境配置：

```json
{
  "docker": {
    "container_name": "lw_vlm_infer",
    "mount": {
      "host": "/data/liuwang08",
      "container": "/mount"
    },
    "project": {
      "host": "/data/liuwang08/work_spec/project",
      "container": "/mount/work_spec/project"
    },
    "network": {
      "http_proxy": "http://proxy.example.com:8080",
      "https_proxy": "http://proxy.example.com:8080",
      "no_proxy": "localhost,127.0.0.1,.baidu.com"
    }
  }
}
```

**字段说明**：
- `container_name`: Docker 容器名称
- `mount.host`: 开发机挂载路径（根目录）
- `mount.container`: 容器内挂载路径（根目录）
- `project.host`: 项目在开发机上的路径
- `project.container`: 项目在容器内的路径
- `network`: 网络代理配置（可选）

### 路径映射

通过 `project` 字段直接指定项目路径，无需从 mount 推断：

| 项目路径（开发机） | 项目路径（容器内） |
|------------------|------------------|
| `/data/liuwang08/work_spec/project` | `/mount/work_spec/project` |

**注意**：`mount` 字段用于记录整体挂载信息，实际操作中直接使用 `project.host` 和 `project.container`。

## 工作流程

### 第 1 步：读取配置

读取项目目录下的 `sys-env.json`：
- `docker.container_name` → 容器名称
- `docker.project.host` → 项目在开发机上的路径
- `docker.project.container` → 项目在容器内的路径
- `docker.network` → 网络代理配置

### 第 2 步：检查系统环境

检查容器内的环境信息：

```bash
# Python 版本
docker exec -it <container_name> python --version

# CUDA 版本
docker exec -it <container_name> nvidia-smi
docker exec -it <container_name> nvcc --version
```

### 第 3 步：创建 uv 环境

**安装 uv**：
```bash
docker exec -it <container_name> bash -c "export http_proxy='<http_proxy>' && export https_proxy='<https_proxy>' && curl -LsSf https://astral.sh/uv/install.sh | sh"
```

**创建虚拟环境**：
```bash
docker exec -it <container_name> bash -c "cd <container_project_path> && uv venv --python <python-version>"
```

**安装依赖**：
```bash
# 从 requirements.txt 安装
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && export http_proxy='<http_proxy>' && export https_proxy='<https_proxy>' && uv pip install -r requirements.txt"

# 从 pyproject.toml 安装
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && export http_proxy='<http_proxy>' && export https_proxy='<https_proxy>' && uv pip install -e ."
```

**安装 PyTorch（CUDA 版本）**：
```bash
# CUDA 11.8
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && export http_proxy='<http_proxy>' && export https_proxy='<https_proxy>' && uv pip install torch --index-url https://download.pytorch.org/whl/cu118"

# CUDA 12.1
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && export http_proxy='<http_proxy>' && export https_proxy='<https_proxy>' && uv pip install torch --index-url https://download.pytorch.org/whl/cu121"
```

### 第 4 步：验证环境

```bash
# 验证 Python 环境
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && python -c 'import sys; print(sys.version)'"

# 验证 CUDA
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')""
```

## 场景处理

### 场景 1：sys-env.json 不存在

创建 `sys-env.json` 文件：

```json
{
  "docker": {
    "container_name": "<容器名称>",
    "mount": {
      "host": "<开发机路径>",
      "container": "<容器内路径>"
    },
    "project": {
      "host": "<项目在开发机上的路径>",
      "container": "<项目在容器内的路径>"
    },
    "network": {
      "http_proxy": "<HTTP代理>",
      "https_proxy": "<HTTPS代理>",
      "no_proxy": "localhost,127.0.0.1"
    }
  }
}
```

### 场景 2：依赖冲突

使用 uv 自动解析：
```bash
docker exec -it <container_name> bash -c "cd <container_project_path> && source .venv/bin/activate && uv pip install --upgrade-package <package> -r requirements.txt"
```

### 场景 3：无网络代理

如果不需要代理，省略 `network` 配置或留空，命令中也不需要设置代理环境变量。

## 输出格式

完成后向用户报告：

1. 环境路径：`<project_path>/.venv/`
2. 激活命令：`source .venv/bin/activate`
3. Python 版本
4. 关键依赖版本

## 注意事项

- uv 环境创建在项目根目录的 `.venv/` 中
- 不修改系统 Python 环境
- 项目目录下必须包含 `sys-env.json` 文件
- 读取文件用开发机路径，执行命令用容器内路径