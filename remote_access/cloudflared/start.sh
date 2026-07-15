#!/bin/bash
# Starts the cloudflared tunnel.
#
# First run: complete the one-time `cloudflared tunnel login/create/route
#             dns` setup in README.md, which produces config/config.yml
#             and config/credentials-*.json, BEFORE running this script.
# Subsequent runs: just starts up.
set -e

PROJECT=cloudflared
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
fi

if [[ ! -f config/config.yml ]]; then
    echo "ERROR: config/config.yml is missing."
    echo "Complete the one-time tunnel setup in README.md first (cloudflared"
    echo "tunnel login/create/route dns), then copy the ingress-rule template"
    echo "from makerops-ai/proxy/cloudflared-config.yml.template into"
    echo "config/config.yml and fill in your tunnel ID + credentials path."
    exit 1
fi

docker compose -p "$PROJECT" up -d

echo ""
echo "cloudflared is starting."
echo "  Logs: docker compose -p $PROJECT logs -f"
echo ""
echo "Verify the public hop once DNS has propagated:"
echo "  curl -s https://<your-hostname>/healthz"
