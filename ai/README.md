# AI

Self-hosted AI services for local inference. These services run open-weight models entirely on-premise — no API keys, no data leaving the host, no per-token costs — and are designed to integrate with the core stack (particularly n8n for automated workflows).

AI services are started individually rather than through `start-all.sh`. They are optional, GPU-dependent, and resource-intensive relative to the core stack; they are intended to be brought up on demand rather than run continuously alongside core services.

## ⚠ Prerequisite: NVIDIA Container Toolkit

**Before running any AI service, you must install and configure the NVIDIA Container Toolkit on the host.** Docker cannot access the GPU without it, and all GPU-accelerated containers will fail to start. The toolkit handles both the package installation and the Docker runtime configuration — it is not a simple binary install.

Follow the official installation guide through to the verification step and confirm the provided test container runs successfully before returning here to continue:

**[NVIDIA Container Toolkit Installation Guide →](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installation)**

---

## Services

| Service | Port | Purpose |
| ------- | ---- | ------- |
| [Ollama](https://ollama.com) | [11434](http://localhost:11434) | Local LLM inference — run open-weight models (Llama, Mistral, Gemma, Qwen, etc.) on GPU, with REST and OpenAI-compatible APIs |
| [ComfyUI](https://github.com/ai-dock/comfyui) | [8188](http://localhost:8188) | FLUX.1 image generation — node-based workflow UI for generative AI image creation |

Both are self-contained Docker Compose projects with their own `start.sh` / `stop.sh` / `teardown.sh` and `.env.example`. Models are pulled/provisioned on demand and persist in each service's data path.

---

## Attribution

**Ollama** is open-source software developed and maintained by the [Ollama contributors](https://github.com/ollama/ollama/graphs/contributors), made freely available under the [MIT License](https://github.com/ollama/ollama/blob/main/LICENSE).

**ComfyUI** is open-source software developed and maintained by [comfyanonymous](https://github.com/comfyanonymous) and contributors, made freely available under the [GNU GPL v3 License](https://github.com/comfyanonymous/ComfyUI/blob/master/LICENSE). Docker packaging by the [ai-dock contributors](https://github.com/ai-dock/comfyui/graphs/contributors) under the [MIT License](https://github.com/ai-dock/comfyui/blob/main/LICENSE).

---

## System Requirements

AI workloads are substantially more resource-intensive than the core stack. Requirements scale with the models you choose to run.

| Resource | Notes |
| -------- | ----- |
| GPU | NVIDIA GPU required. VRAM determines which models can run: 8 GB handles 7B–8B parameter models; 24 GB handles up to 34B; 80 GB handles 70B. |
| Disk | Models range from ~1 GB (smallest quantized) to 70+ GB (large). The `ollama_data` volume grows with each model pulled. A fast NVMe drive is recommended. |
| RAM | Models that fit VRAM add minimal host RAM overhead. Models larger than VRAM partially offload weights to system RAM — budget roughly the overflow plus a few GB. On WSL2, raise the memory cap in `.wslconfig` if a large model stalls or thrashes. |

See [ollama/README.md](ollama/README.md) for setup instructions, model management, and API usage.
