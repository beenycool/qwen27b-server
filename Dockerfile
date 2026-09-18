FROM ghcr.io/ggml-org/llama.cpp:server-cuda

USER root
ENV LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

RUN apt-get update && apt-get install -y --no-install-recommends aria2 ca-certificates curl && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

RUN mkdir -p /models && \
    aria2c -x 16 -s 16 -j 16 -k 1M -c \
    --summary-interval=10 \
    -d /models -o Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf \
    "https://huggingface.co/DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF/resolve/main/Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf?download=true"

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
