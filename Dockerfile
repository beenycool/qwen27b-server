FROM ghcr.io/ggml-org/llama.cpp:server-cuda

USER root
ENV LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

RUN apt-get update && apt-get install -y --no-install-recommends aria2 ca-certificates curl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /models && \
    aria2c -x 16 -s 16 -j 16 -k 1M -c \
    --summary-interval=10 \
    -d /models -o Qwen3.8-27B-Uncensored.Q5_K_M.gguf \
    "https://huggingface.co/mradermacher/Qwen3.8-27B-Uncensored-GGUF/resolve/main/Qwen3.8-27B-Uncensored.Q5_K_M.gguf?download=true"

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
