# llamacpp — llama.cpp Router-Mode Inference Server

llama.cpp's `llama-server` running in **router mode**: one OpenAI-compatible endpoint that serves several GGUF models, loads them on demand, unloads the least-recently-used one when the limit is reached, and sleeps idle models to free VRAM.

- **GitHub:** <https://github.com/ggml-org/llama.cpp>
- **Server docs:** <https://github.com/ggml-org/llama.cpp/tree/master/tools/server>
- **Docker image:** `ghcr.io/ggml-org/llama.cpp:server-cuda` (pinned by digest)

---

## Why it coexists with Ollama

[Ollama](../ollama/README.md) stays the default engine. llamacpp complements it: a model is served here only when its **measured** performance is better on llama.cpp. The engine is chosen per model, on evidence, not as a blanket replacement.

Measured 2026-11-27 for Qwen3.6-35B-A3B (Q4_K_M, 64k context) against the same model under Ollama:

| Metric | llama.cpp | Ollama |
| --- | --- | --- |
| Decode speed | 66 tok/s | 50 tok/s |
| Prefill speed (18k-token prompt) | 2445 tok/s | 1364 tok/s |
| Locked host RAM | ~2.6 GiB | ~14.5 GiB |

---

## Attribution

**llama.cpp** is open-source software developed by [Georgi Gerganov](https://github.com/ggerganov) and the [ggml-org contributors](https://github.com/ggml-org/llama.cpp/graphs/contributors), made freely available under the [MIT License](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE).

The default model, **Qwen3.6-35B-A3B**, is published by the Qwen team (Alibaba Cloud); the GGUF quantization is by [bartowski](https://huggingface.co/bartowski). The model weights are released under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) (see the [model card](https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF)).

---

## Prerequisites

The NVIDIA Container Toolkit must be installed and configured on the host. See [ai/README.md](../README.md).

---

## Local Access

| | |
| --- | --- |
| **API endpoint** | <http://localhost:8110> |
| **Via name-proxy** | <http://llamacpp.localhost> |

Host port 8110 maps to container port 8080 (change with `LLAMACPP_PORT`).

---

## Setup

### 1. Download the model

GGUF files live **outside the repo**. Ollama's own GGUF blobs do **not** load in upstream llama.cpp (Ollama modifies the format), so models must be downloaded separately.

| | |
| --- | --- |
| Source | `bartowski/Qwen_Qwen3.6-35B-A3B-GGUF` on Hugging Face |
| File | `Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf` |
| sha256 | `b46fedd33e0bfb0cae308aa3c158d0a4b2c4a1d2185a1ed6f093cdaf39064772` |

```bash
mkdir -p ~/models/gguf && cd ~/models/gguf
curl -L -O https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
echo "b46fedd33e0bfb0cae308aa3c158d0a4b2c4a1d2185a1ed6f093cdaf39064772  Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf" | sha256sum -c -
```

### 2. Configure

```bash
cp .env.example .env
```

Set `LLAMACPP_MODELS_DIR` in `.env` to the directory from step 1.

### 3. Start

```bash
./start.sh
```

The container starts with no model loaded. The first request to a model loads it (wake ≈ 20–35 s).

---

## Scripts

### `./start.sh`

Creates `.env` from `.env.example` if missing (then exits so you can edit it), checks that the models directory exists, pulls the pinned image, and starts the container.

### `./stop.sh`

Stops and removes the container. Model files are never touched.

### `./teardown.sh`

Removes the container, network, and image after a confirmation prompt. There are no Docker volumes; your GGUF files and `models.ini` are not deleted.

---

## Files

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | Single-container stack with GPU reservation and pinned image |
| `models.ini` | Tracked model presets (shared defaults + one section per model; no secrets) |
| `.env.example` | Models directory and host port |
| `start.sh` / `stop.sh` / `teardown.sh` | Lifecycle scripts |

---

## Architecture

```text
LLM clients / n8n / applications
  └─► localhost:8110  (TCP) → llama-server router (container :8080)
          ├─► models.ini        (/config/models.ini, read-only)
          ├─► GGUF files        (/models, read-only, from LLAMACPP_MODELS_DIR)
          └─► NVIDIA GPU        (via NVIDIA Container Toolkit)
```

Router flags (see `docker-compose.yml`): `--models-max 2` (at most two models loaded; the least recently used is unloaded), `--models-memory-margin 512` (MiB kept free), `--sleep-idle-seconds 300` (unload after 5 idle minutes).

---

## API

| Endpoint | Purpose |
| --- | --- |
| `POST /v1/chat/completions` | OpenAI-compatible chat; set `"model"` to a preset id from `models.ini` |
| `GET /models` | List presets and their load state |
| `POST /models/unload` | Unload a model to free VRAM immediately |
| `GET /health` | Liveness (used by the healthcheck; does not wake models or reset the idle timer) |

```bash
curl http://localhost:8110/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.6-35b-64k",
    "messages": [{"role": "user", "content": "Say hello."}],
    "tool_choice": "auto"
  }'

curl http://localhost:8110/models

curl -X POST http://localhost:8110/models/unload \
  -H 'Content-Type: application/json' -d '{"model": "qwen3.6-35b-64k"}'
```

---

## Adding a model

1. Put the GGUF file in `LLAMACPP_MODELS_DIR` and verify its sha256.
2. Add a section to `models.ini`; settings under `[*]` are inherited:

   ```ini
   [my-model-id]
   model = /models/my-model.gguf
   c = 32768
   n-gpu-layers = 99
   ```

3. Restart: `docker compose -p llamacpp restart llamacpp` (the file is bind-mounted read-only; the router reads it at start).

Model ids must **not** contain `:`. The router parses text after a colon as a quant tag and renames the model. Clients that use Ollama-style names (`qwen3.6:35b-64k`) must map them to the preset id (`qwen3.6-35b-64k`).

---

## Gotchas

- **Send `tool_choice: "auto"`.** llama.cpp enforces `"required"` with a grammar that prevents a text answer from ending, which causes runaway generations. Ollama ignores the field, so clients written against Ollama may send `"required"` unnoticed.
- **VRAM is shared with Ollama.** Both engines compete for the same GPU. Idle sleep (300 s) frees llamacpp's VRAM; the next request wakes the model (≈ 20–35 s). Unload explicitly with `POST /models/unload` if you need the GPU sooner.
- **`n-cpu-moe = 16`** keeps the experts of the first 16 layers in host RAM. 12 spills VRAM into shared memory; 16 was fastest on a 16 GB GPU. Retune for other GPUs.
- **`cache-ram = 0`** disables llama-server's 8 GB host prompt cache, which caused OOM kills of the 35b under Ollama's memory pressure.
- **`n-predict = 8192`** caps generation so a looping response fails fast. Raise it per model if you need longer outputs.
- **WSL2:** the container pulls nothing at runtime, so no explicit `dns:` is set. Image pulls use the Docker daemon. If a pull fails with DNS errors, see the WSL2 notes in [ai/README.md](../README.md).
- **Large GGUFs on WSL2:** keep them on the Linux filesystem (`~/...`), not under `/mnt/c`, or loading will be very slow.

---

## Cheat Sheet

```bash
# Logs
docker compose -p llamacpp logs -f llamacpp

# Health
curl http://localhost:8110/health

# Which models are loaded
curl http://localhost:8110/models

# GPU usage
nvidia-smi
```

### Upgrade (bump the pinned image deliberately)

The image is pinned by digest (llama.cpp build 12774) so behaviour does not change underneath you.

1. Pull the new tag and read its digest:

   ```bash
   docker pull ghcr.io/ggml-org/llama.cpp:server-cuda
   docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/ggml-org/llama.cpp:server-cuda
   ```

2. Replace the `image:` line in `docker-compose.yml` with the new `...:server-cuda@sha256:<digest>`.
3. Re-run the decode/prefill benchmark and a quality check on your own workload before keeping the bump, then `./start.sh`.
