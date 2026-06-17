#!/bin/bash
# ============================================================
# vllm-cli: start_server.sh
# 在 Docker 容器中启动 vLLM OpenAI-compatible API server
#
# 用法:
#   ./start_server.sh --model <model_path> [--port <port>] [args...]
#
# 示例:
#   ./start_server.sh --model /workspace/models/Qwen3-0.6B --port 8000
#   ./start_server.sh -m /workspace/models/Qwen3-0.6B -p 8001 --gpu-memory-utilization 0.8
# ============================================================

set -euo pipefail

# ---------- 环境配置（按需修改） ----------
DOCKER_CONTAINER="${VLLM_DOCKER_CONTAINER:-lw_agent}"
VENV_PATH="${VLLM_VENV_PATH:-/workspace/vllm-0.21.0/.venv}"
PROJECT_PATH="${VLLM_PROJECT_PATH:-/workspace/vllm-0.21.0}"
DEFAULT_PORT="${VLLM_DEFAULT_PORT:-8000}"
DEFAULT_HOST="${VLLM_DEFAULT_HOST:-0.0.0.0}"
# -----------------------------------------

# 解析参数
MODEL=""
PORT="$DEFAULT_PORT"
HOST="$DEFAULT_HOST"
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --model|-m)
      MODEL="$2"; shift 2 ;;
    --port|-p)
      PORT="$2"; shift 2 ;;
    --host)
      HOST="$2"; shift 2 ;;
    *)
      EXTRA_ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$MODEL" ]; then
  echo "错误: 必须指定 --model <模型路径>"
  echo "用法: $0 --model <model_path> [--port <port>] [args...]"
  exit 1
fi

echo "=========================================="
echo "  vLLM Server 启动"
echo "  容器:    $DOCKER_CONTAINER"
echo "  模型:    $MODEL"
echo "  地址:    $HOST:$PORT"
echo "  环境:    $VENV_PATH"
echo "=========================================="

CMD="cd $PROJECT_PATH && source $VENV_PATH/bin/activate && vllm serve $MODEL --host $HOST --port $PORT ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

echo ""
echo "执行命令:"
echo "  docker exec $DOCKER_CONTAINER bash -c \"$CMD\""
echo ""
echo "服务将在前台运行，按 Ctrl+C 停止。"
echo "如需后台运行，请使用 -d 参数或 nohup。"
echo ""

echo "前台运行中（按 Ctrl+C 停止）..."
echo ""

# 非交互式执行（适用于 Claude Code 等自动化场景）
exec docker exec "$DOCKER_CONTAINER" bash -c "$CMD"