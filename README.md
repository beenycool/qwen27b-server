# Qwen 27B Llama.cpp Server (CUDA)

Pre-configured CUDA `llama-server` container for SaladCloud, Vast.ai, and RunPod.

## Defaults
- **Model**: `Qwen3.8-27B-Uncensored.Q5_K_M.gguf`
- **Context**: 131,072 (128k)
- **KV Cache**: `q4_0` (Flash Attention enabled)
- **Reasoning**: Medium effort, 1024 token budget, DeepSeek format
- **Port**: 8080
