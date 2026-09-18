# Qwen 27B Llama.cpp Server (CUDA)

Pre-configured CUDA `llama-server` container for SaladCloud, Vast.ai, and RunPod.

## Defaults
- **Model**: `Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf`
- **Source**: [`DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF`](https://huggingface.co/DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF)
- **Quant**: Q5_K_M, MTP (multi-token prediction) variant
- **Context**: 131,072 (128k) — the model supports 262,144, but the MTP draft context is
  created at the same size as the target's and shares the memory pool, so a larger `-c`
  shrinks the KV cache. Raise with `LLAMA_ARG_CTX_SIZE` if you need it.
- **KV Cache**: `q4_0` (Flash Attention enabled)
- **Speculative decoding**: `--spec-type draft-mtp` (3 drafts/pass), driven by the NextN
  head already inside this GGUF — no separate draft file. Set `LLAMA_ARG_SPEC_TYPE=none`
  to disable, or `LLAMA_ARG_SPEC_DRAFT_N_MAX` to change the draft depth.
- **Reasoning**: Medium effort, budget `-1` (unrestricted — see below), DeepSeek format
- **Port**: 8080

## Reasoning budget

`--reasoning-budget` is a hard cap on thinking tokens: `-1` unrestricted, `0` immediate
end, `N>0` a token budget. This entrypoint passes **`-1` by default** because the
`medium`/`einstein`/`spoon` reasoning modes are defined by their *instructions*, not by a
fixed length, and cutting them off mid-thought defeats the point. It previously defaulted
to `1024`, which truncates thinking on a model tuned to reduce thinking tokens itself —
the tuning already solves the problem the cap was there for.

Set `LLAMA_ARG_REASONING_BUDGET=2048` (or any `N`) to cap it, `0` to skip thinking
entirely. Passing the effort level per request overrides the `--reasoning-effort` default;
the model's template accepts `xhigh` (default), `medium`, `low`, plus `einstein` and `spoon`.

## Speculative decoding

The GGUF carries the MTP head (`blk.64.nextn.*`, `qwen35.nextn_predict_layers = 1`), and
llama.cpp uses the same file as its draft model, so this is self-contained. Two caveats:

- It needs a llama.cpp build with NextN/MTP support. On one without `--spec-type`, the
  entrypoint logs a warning and serves without it rather than crash-looping.
- Speculative decoding is exact — it changes speed, not what gets sampled.
