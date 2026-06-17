#!/bin/bash
# Check environment for model downloading
# Tests hf-mirror access speed and checks modelscope availability

set -e

echo "=== 环境检查 ==="

# 1. Check if modelscope is already installed
if command -v modelscope &>/dev/null; then
    echo "✓ modelscope 已安装"
    exit 0
fi

echo "• modelscope 未安装"

# 2. Test hf-mirror access speed
HF_MIRROR_URL="https://hf-mirror.com"
echo "• 测试 hf-mirror 访问速度..."
if timeout 5 curl -s -o /dev/null -w "  HTTP状态码: %{http_code}, 耗时: %{time_total}s" "${HF_MIRROR_URL}" 2>/dev/null; then
    echo ""
    echo "  hf-mirror 可访问"
else
    echo ""
    echo "  hf-mirror 访问超时或不可用"
    echo "  → 建议安装 modelscope"
    exit 2
fi

# Also test a small file download speed
echo "• 测试 hf-mirror 下载速度..."
SPEED=$(timeout 10 curl -s -o /dev/null -w "%{speed_download}" "https://hf-mirror.com/api/models" 2>/dev/null || echo "0")
SPEED_KB=$(echo "$SPEED / 1024" | bc 2>/dev/null || echo "0")
echo "  下载速度: ${SPEED_KB} KB/s"

if [ "$(echo "$SPEED < 1024" | bc 2>/dev/null || echo "1")" -eq 1 ]; then
    echo "  → hf-mirror 下载速度较慢（< 1 KB/s），建议使用 modelscope"
    exit 2
fi

echo "✓ hf-mirror 访问正常，可直接使用"
exit 0