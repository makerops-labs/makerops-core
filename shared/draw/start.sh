#!/bin/bash
# Starts the draw.io diagramming service.
#
# First run:
#   - Copies .env.example → .env if .env does not exist
#   - Pulls image and starts the container
# Subsequent runs:
#   - Pulls latest image and starts
set -e

PROJECT=draw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Bootstrap .env ────────────────────────────────────────────────────────────
if [[ ! -f .env ]]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
fi

# ── Pull and start ─────────────────────────────────────────────────────────────
echo "Pulling images..."
docker compose -p "$PROJECT" pull --quiet

echo "Starting services..."
docker compose -p "$PROJECT" up -d

# ── Summary ───────────────────────────────────────────────────────────────────
APP_URL=$(grep "^DRAWIO_BASE_URL=" .env | cut -d= -f2-)

echo ""
echo "draw.io is starting. Allow 20–30 s on first run."
echo ""
echo "  UI:   ${APP_URL:-http://localhost:8085}"
echo ""
echo "To tail logs:  docker compose -p $PROJECT logs -f"
