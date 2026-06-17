#!/bin/bash
# huggingface model download script
# Uses ModelScope as download source (HuggingFace hf-mirror may be unreliable)
# Automatically creates a subdirectory named after the model (without org prefix)
set -e

MODEL_NAME="$1"
BASE_DIR="$2"

if [ -z "$MODEL_NAME" ] || [ -z "$BASE_DIR" ]; then
    echo "Usage: $0 <model_name> <base_dir>"
    echo "Example: $0 Qwen/Qwen3-0.6B /data/models"
    echo "  -> Downloads to /data/models/Qwen3-0.6B/"
    exit 1
fi

# Extract model short name (e.g. "Qwen3-0.6B" from "Qwen/Qwen3-0.6B")
MODEL_SHORT_NAME="${MODEL_NAME#*/}"
LOCAL_DIR="${BASE_DIR}/${MODEL_SHORT_NAME}"

mkdir -p "${LOCAL_DIR}"
echo "Downloading ${MODEL_NAME} to ${LOCAL_DIR}..."

if ! modelscope download --model "${MODEL_NAME}" --local_dir "${LOCAL_DIR}"; then
    echo "Download failed. Check model name or network."
    exit 1
fi

echo "Verifying..."
ls -lh "${LOCAL_DIR}/"*.safetensors 2>/dev/null | wc -l || true
ls -lh "${LOCAL_DIR}/"*.json 2>/dev/null | wc -l || true
du -sh "${LOCAL_DIR}"
echo "Done!"
echo "Model saved to: ${LOCAL_DIR}"