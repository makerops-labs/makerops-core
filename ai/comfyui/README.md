# ComfyUI

Node-based workflow UI for generative AI image creation. This service uses the [ai-dock/comfyui](https://github.com/ai-dock/comfyui) Docker image, which packages ComfyUI with a built-in service portal, process management, and a provisioning system for downloading models on first run.

The default foundation model is **FLUX.1**:

- **FLUX.1-dev** — higher quality, requires a Hugging Face token and license acceptance
- **FLUX.1-schnell** — faster, no license acceptance required

> ⚠ **Both official Black Forest Labs repos on Hugging Face are now gated** (they return
> 401 without a token — including FLUX.1-schnell, which the ai-dock provisioning script
> still assumes is public). Without `HF_TOKEN`, provisioning silently skips the UNET and
> VAE and ComfyUI starts with no usable image model. Either set `HF_TOKEN` in `.env`
> before the first start, or download the ungated all-in-one fp8 checkpoint from
> [Comfy-Org/flux1-schnell](https://huggingface.co/Comfy-Org/flux1-schnell) (17 GB,
> recommended for ≤16 GB VRAM):
>
> ```bash
> docker exec -u user comfyui wget -qnc --content-disposition \
>   -P /opt/storage/stable_diffusion/models/ckpt \
>   https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors
> ```

## Prerequisites

Before starting, install the NVIDIA Container Toolkit on the host. See [ai/README.md](../README.md#-prerequisite-nvidia-container-toolkit) for the installation link and verification steps.

## Attribution

**ComfyUI** is open-source software developed and maintained by [comfyanonymous](https://github.com/comfyanonymous) and contributors, made freely available under the [GNU GPL v3 License](https://github.com/comfyanonymous/ComfyUI/blob/master/LICENSE).

**ai-dock/comfyui** Docker packaging is developed and maintained by the [ai-dock contributors](https://github.com/ai-dock/comfyui/graphs/contributors), made freely available under the [MIT License](https://github.com/ai-dock/comfyui/blob/main/LICENSE).

**FLUX.1** models are developed by [Black Forest Labs](https://blackforestlabs.ai). FLUX.1-dev is available under the [FLUX.1-dev Non-Commercial License](https://huggingface.co/black-forest-labs/FLUX.1-dev/blob/main/LICENSE.md). FLUX.1-schnell is available under the [Apache 2.0 License](https://huggingface.co/black-forest-labs/FLUX.1-schnell/blob/main/LICENSE.md).

## Ports

| Port | Purpose |
| ---- | ------- |
| [8188](http://localhost:8188) | ComfyUI web interface |
| [1111](http://localhost:1111) | ai-dock service portal (logs, process control, system info) |

## First-Run Setup

1. **Set your Hugging Face token** (optional, for FLUX.1-dev):
   - Create a token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
   - Accept the FLUX.1-dev model license at [huggingface.co/black-forest-labs/FLUX.1-dev](https://huggingface.co/black-forest-labs/FLUX.1-dev)
   - Set `HF_TOKEN=<your-token>` in `.env`
   - Without a token, FLUX.1-schnell is downloaded automatically (no license required)

2. **Run the service:**

   ```bash
   ./start.sh
   ```

   On the very first run, `start.sh` will create `.env` from `.env.example` and exit, prompting you to set `HF_TOKEN`. Run it again after editing `.env`.

3. **Wait for provisioning to complete:**
   On first container start, the provisioning script downloads FLUX models (~25 GB total). This takes 10–30 minutes depending on your connection. Watch progress:

   ```bash
   docker compose -p comfyui logs -f comfyui
   ```

   ComfyUI becomes accessible once provisioning finishes and the process starts.

   `start.sh` automatically disables provisioning after the first successful start by writing a `.provisioned` sentinel file and clearing `PROVISIONING_SCRIPT` from `.env`. Subsequent starts skip provisioning and launch immediately.

   To re-run provisioning (e.g. to pull updated models): delete `.provisioned` and restore the `PROVISIONING_SCRIPT` URL in `.env`, then run `start.sh` again.

## Model Storage

Two host directories back the container:

- `./data/storage` (`COMFYUI_STORAGE_PATH`) → `/opt/storage` — **models downloaded by provisioning live here.** Without this mount they are container-local and lost on every recreate.
- `./data/workspace` (`COMFYUI_WORKSPACE_PATH`) → `/workspace` — generated outputs, custom nodes, and configuration.

FLUX models are large (~25 GB). If disk space is a concern, point these variables at absolute paths on a larger volume before starting.

Both directories are pre-created by `start.sh` so they are owned by the invoking user. If Docker creates them instead, they end up root-owned and the container's unprivileged user cannot write to them — provisioning then fails **silently** and reports success with nothing downloaded.
