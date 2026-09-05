#!/bin/sh
set -e

export LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

echo "=========================================="
echo "Starting Qwen 27B Llama.cpp Server"
echo "Host: ${LLAMA_ARG_HOST:-::}"
echo "Port: ${LLAMA_ARG_PORT:-8080}"
echo "=========================================="

exec /app/llama-server \
  --hf-repo "${LLAMA_ARG_HF_REPO:-mradermacher/Qwen3.8-27B-Uncensored-GGUF}" \
  --hf-file "${LLAMA_ARG_HF_FILE:-Qwen3.8-27B-Uncensored.Q5_K_M.gguf}" \
  --host "${LLAMA_ARG_HOST:-::}" \
  --port "${LLAMA_ARG_PORT:-8080}" \
  -c "${LLAMA_ARG_CTX_SIZE:-131072}" \
  -np "${LLAMA_ARG_N_PARALLEL:-1}" \
  -ngl "${LLAMA_ARG_N_GPU_LAYERS:-99}" \
  --flash-attn on \
  --cache-type-k "${LLAMA_ARG_CACHE_TYPE_K:-q4_0}" \
  --cache-type-v "${LLAMA_ARG_CACHE_TYPE_V:-q4_0}" \
  -b 2048 \
  -ub 512 \
  --threads 8 \
  --alias "${LLAMA_ARG_ALIAS:-orcarouter/Qwen3.8-27B-Uncensored:q6_K}" \
  --jinja \
  --reasoning-effort "${LLAMA_ARG_REASONING_EFFORT:-medium}" \
  --reasoning-budget "${LLAMA_ARG_REASONING_BUDGET:-1024}" \
  --reasoning-format "${LLAMA_ARG_REASONING_FORMAT:-deepseek}" \
  --temp "${LLAMA_SERVER_TEMP:-0.7}" \
  --top-p "${LLAMA_SERVER_TOP_P:-0.95}" \
  --min-p "${LLAMA_SERVER_MIN_P:-0.05}"
