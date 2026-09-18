#!/bin/sh
set -e

export LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

MODEL_PATH="/models/Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf"
PORT="${LLAMA_ARG_PORT:-8080}"

# --- MTP speculative decoding ------------------------------------------------
# This GGUF carries the multi-token-prediction (NextN) head:
#   blk.64.nextn.{eh_proj,enorm,hnorm,shared_head_norm}.weight  (4 tensors, blk 64 of 64)
# and qwen35.nextn_predict_layers = 1 in its metadata. llama.cpp drives that head
# as a draft model using THE SAME FILE (common/speculative.cpp:
# "model_path = params.model.path" for spec_mtp), so no separate draft GGUF is
# needed. Without --spec-type draft-mtp the head is simply never used and you
# pay full price per token.
#
# Note the token budget is NOT reserved per sequence: the MTP draft context is
# created with n_ctx == the target's and lives in the same memory pool, so a
# large -c shrinks what is left for KV cache. That is why -c defaults to 131072
# here rather than the model's full 262144.
#
# LLAMA_ARG_SPEC_TYPE=none disables it (also the escape hatch for an older
# llama-server build that predates the flag).
SPEC_TYPE="${LLAMA_ARG_SPEC_TYPE:-draft-mtp}"
SPEC_N_MAX="${LLAMA_ARG_SPEC_DRAFT_N_MAX:-3}"

# Validate before use: these end up in an unquoted expansion below, and the
# binary's own error for a bad value is far less clear than this.
case "${SPEC_N_MAX}" in ''|*[!0-9]*) SPEC_N_MAX=3 ;; esac
case "${SPEC_TYPE}" in
  draft-mtp|draft-simple|draft-eagle3|draft-dflash|draft-dspark|\
  ngram-simple|ngram-map-k|ngram-map-k4v|ngram-mod|ngram-cache)
    SPEC_ARGS="--spec-type ${SPEC_TYPE} --spec-draft-n-max ${SPEC_N_MAX}" ;;
  *) SPEC_TYPE="none"; SPEC_ARGS="" ;;
esac

# A build without the flag would abort at startup; check first and degrade
# loudly instead of crash-looping the container.
if [ -n "${SPEC_ARGS}" ] && ! /app/llama-server --help 2>&1 | grep -q -- "--spec-type"; then
  echo "WARNING: this llama-server build has no --spec-type; serving WITHOUT speculative decoding."
  echo "         MTP needs a build with NextN/MTP support -- re-pull the image, or silence this"
  echo "         with LLAMA_ARG_SPEC_TYPE=none. Expect roughly 1/3 the tokens/sec."
  SPEC_TYPE="none"; SPEC_ARGS=""
fi

echo "=========================================="
echo "Starting Qwen 27B Llama.cpp Server"
echo "Model: ${MODEL_PATH}"
echo "Port: ${PORT}"
echo "Speculative decoding: ${SPEC_TYPE}$([ "${SPEC_TYPE}" = none ] || echo " (drafts ${SPEC_N_MAX}/pass)")"
echo "=========================================="

# Start llama-server in background
# shellcheck disable=SC2086  # SPEC_ARGS is a validated, deliberately split flag list
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
  ${SPEC_ARGS} \
  --reasoning-effort "${LLAMA_ARG_REASONING_EFFORT:-medium}" \
  --reasoning-budget "${LLAMA_ARG_REASONING_BUDGET:--1}" \
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
