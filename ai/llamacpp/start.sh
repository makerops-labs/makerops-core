#!/bin/bash
# Starts llama.cpp llama-server in router mode.
# Requires GGUF files in LLAMACPP_MODELS_DIR (see README.md for the download).
set -e

PROJECT=llamacpp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Created .env from .env.example."
    echo "Edit LLAMACPP_MODELS_DIR in .env to point at your GGUF directory, then re-run."
    exit 1
fi

set -a
source .env
set +a

if [[ ! -d "$LLAMACPP_MODELS_DIR" ]]; then
    echo "ERROR: LLAMACPP_MODELS_DIR does not exist: $LLAMACPP_MODELS_DIR"
    echo "Create it and download the model files (see README.md)."
    exit 1
fi

echo "Pulling pinned image..."
docker compose -p "$PROJECT" pull

echo "Starting services..."
docker compose -p "$PROJECT" up -d

echo ""
echo "llama-server is starting. Models load on first request (~20-35 s)."
echo ""
echo "API:     http://localhost:${LLAMACPP_PORT:-8110}"
echo "Models:  curl http://localhost:${LLAMACPP_PORT:-8110}/models"
echo ""
echo "To watch startup: docker compose -p $PROJECT logs -f llamacpp"
