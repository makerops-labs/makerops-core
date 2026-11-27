#!/bin/bash
# Stops the llama.cpp container. Model files (LLAMACPP_MODELS_DIR) are never touched.
set -e

PROJECT=llamacpp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

docker compose -p "$PROJECT" down "$@"
