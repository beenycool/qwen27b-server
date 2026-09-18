# Qwen 27B Llama.cpp Server (CUDA)

Pre-configured CUDA `llama-server` container for SaladCloud, Vast.ai, and RunPod.

## Defaults
- **Model**: `Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q5_K_M.gguf`
- **Source**: [`DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF`](https://huggingface.co/DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF)
- **Quant**: Q5_K_M, MTP (multi-token prediction) variant
- **Context**: 131,072 (128k)
- **KV Cache**: `q4_0` (Flash Attention enabled)
- **Reasoning**: Medium effort, 1024 token budget, DeepSeek format
- **Port**: 8080
