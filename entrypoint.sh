#!/bin/sh
set -e

export LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

MODEL_PATH="/models/Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf"
PORT="${LLAMA_ARG_PORT:-8080}"

echo "=========================================="
echo "Starting Qwen 27B Llama.cpp Server"
echo "Model: ${MODEL_PATH}"
echo "Port: ${PORT}"
echo "=========================================="

# Start llama-server in background
/app/llama-server \
  -m "${MODEL_PATH}" \
  --host "${LLAMA_ARG_HOST:-::}" \
  --port "${PORT}" \
  -c "${LLAMA_ARG_CTX_SIZE:-131072}" \
  -np "${LLAMA_ARG_N_PARALLEL:-1}" \
  -ngl "${LLAMA_ARG_N_GPU_LAYERS:-99}" \
  --flash-attn on \
  --cache-type-k "${LLAMA_ARG_CACHE_TYPE_K:-q4_0}" \
  --cache-type-v "${LLAMA_ARG_CACHE_TYPE_V:-q4_0}" \
  -b 2048 \
  -ub 512 \
  --threads 8 \
  --alias "${LLAMA_ARG_ALIAS:-orcarouter/Qwen3.8-27B-TurboFCFusion-NEO-CODER-MAX:q5_K_M}" \
  --jinja \
  --reasoning-effort "${LLAMA_ARG_REASONING_EFFORT:-medium}" \
  --reasoning-budget "${LLAMA_ARG_REASONING_BUDGET:-1024}" \
  --reasoning-format "${LLAMA_ARG_REASONING_FORMAT:-deepseek}" \
  --temp "${LLAMA_SERVER_TEMP:-0.7}" \
  --top-p "${LLAMA_SERVER_TOP_P:-0.95}" \
  --min-p "${LLAMA_SERVER_MIN_P:-0.05}" &
LLAMA_PID=$!

echo "Waiting for llama-server to be ready on port ${PORT}..."
until curl -s "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; do
  if ! kill -0 "${LLAMA_PID}" 2>/dev/null; then
    echo "llama-server process exited unexpectedly!"
    exit 1
  fi
  sleep 2
done

echo "llama-server is online!"
echo "Starting Cloudflare Quick Tunnel..."

# Start cloudflared in the foreground to stream logs and keep container alive
exec cloudflared tunnel --protocol http2 --url "http://127.0.0.1:${PORT}"
