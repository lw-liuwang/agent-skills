#!/bin/bash
# ============================================================
# vllm-cli: run_benchmark.sh
# 在 Docker 容器中对运行中的 vLLM 服务执行在线压测
#
# 用法:
#   ./run_benchmark.sh --model <model_name> --base-url <url> [options]
#
# 示例:
#   ./run_benchmark.sh --model /workspace/models/Qwen3-0.6B --base-url http://127.0.0.1:8000
#   ./run_benchmark.sh -m Qwen3-0.6B -u http://127.0.0.1:8000 -r 10 -n 200
# ============================================================

set -euo pipefail

# ---------- 环境配置（按需修改） ----------
DOCKER_CONTAINER="${VLLM_DOCKER_CONTAINER:-lw_agent}"
VENV_PATH="${VLLM_VENV_PATH:-/workspace/vllm-0.21.0/.venv}"
PROJECT_PATH="${VLLM_PROJECT_PATH:-/workspace/vllm-0.21.0}"
DEFAULT_HOST="${VLLM_DEFAULT_HOST:-127.0.0.1}"
DEFAULT_PORT="${VLLM_DEFAULT_PORT:-8000}"
DEFAULT_BACKEND="${VLLM_DEFAULT_BACKEND:-openai}"
# -----------------------------------------

# 解析参数
MODEL=""
BASE_URL=""
HOST="$DEFAULT_HOST"
PORT="$DEFAULT_PORT"
BACKEND="$DEFAULT_BACKEND"
REQUEST_RATE=""
NUM_PROMPTS=""
INPUT_LEN=""
OUTPUT_LEN=""
DATASET_NAME="random"
RESULT_DIR=""
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --model|-m)       MODEL="$2"; shift 2 ;;
    --base-url|-u)    BASE_URL="$2"; shift 2 ;;
    --host)           HOST="$2"; shift 2 ;;
    --port|-p)        PORT="$2"; shift 2 ;;
    --backend|-b)     BACKEND="$2"; shift 2 ;;
    --request-rate|-r) REQUEST_RATE="$2"; shift 2 ;;
    --num-prompts|-n) NUM_PROMPTS="$2"; shift 2 ;;
    --input-len)      INPUT_LEN="$2"; shift 2 ;;
    --output-len)     OUTPUT_LEN="$2"; shift 2 ;;
    --dataset|-d)     DATASET_NAME="$2"; shift 2 ;;
    --result-dir)     RESULT_DIR="$2"; shift 2 ;;
    *)                EXTRA_ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$MODEL" ]; then
  echo "错误: 必须指定 --model <模型名称>"
  echo "用法: $0 --model <model_name> --base-url <url> [options]"
  exit 1
fi

# 如果没指定 --base-url，用 --host 和 --port 拼接
if [ -z "$BASE_URL" ]; then
  BASE_URL="http://$HOST:$PORT"
fi

# 构建命令
BENCH_CMD="cd $PROJECT_PATH && source $VENV_PATH/bin/activate && vllm bench serve"
BENCH_CMD+=" --model $MODEL"
BENCH_CMD+=" --base-url $BASE_URL"
BENCH_CMD+=" --backend $BACKEND"
[ -n "$REQUEST_RATE" ] && BENCH_CMD+=" --request-rate $REQUEST_RATE"
[ -n "$NUM_PROMPTS" ]  && BENCH_CMD+=" --num-prompts $NUM_PROMPTS"
[ -n "$INPUT_LEN" ]    && BENCH_CMD+=" --input-len $INPUT_LEN"
[ -n "$OUTPUT_LEN" ]   && BENCH_CMD+=" --output-len $OUTPUT_LEN"
[ -n "$DATASET_NAME" ] && BENCH_CMD+=" --dataset-name $DATASET_NAME"
[ -n "$RESULT_DIR" ]   && BENCH_CMD+=" --save-result --result-dir $RESULT_DIR"
[ ${#EXTRA_ARGS[@]} -gt 0 ] && BENCH_CMD+=" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

echo "=========================================="
echo "  vLLM Benchmark"
echo "  容器:    $DOCKER_CONTAINER"
echo "  模型:    $MODEL"
echo "  地址:    $BASE_URL"
echo "  后端:    $BACKEND"
echo "  速率:    ${REQUEST_RATE:-inf} req/s"
echo "  Prompts: ${NUM_PROMPTS:-1000}"
echo "=========================================="

echo ""
echo "执行命令:"
echo "  docker exec $DOCKER_CONTAINER bash -c \"$BENCH_CMD\""
echo ""

exec docker exec "$DOCKER_CONTAINER" bash -c "$BENCH_CMD"