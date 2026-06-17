#!/bin/bash
# huggingface model upload script
# Uses ModelScope as upload target
set -e

MODEL_NAME="$1"
LOCAL_DIR="$2"

if [ -z "$MODEL_NAME" ] || [ -z "$LOCAL_DIR" ]; then
    echo "Usage: $0 <model_name> <local_dir>"
    echo "Example: $0 my-org/my-model /data/liuwang08/lw/agent-skills/models/my-model"
    exit 1
fi

echo "Uploading ${LOCAL_DIR} to ${MODEL_NAME}..."
modelscope upload --model "${MODEL_NAME}" "${LOCAL_DIR}"

echo "Done!"