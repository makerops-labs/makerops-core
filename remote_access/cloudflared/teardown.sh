#!/bin/bash
# Tears down the cloudflared container, image, and network.
#
# NOTE: this does NOT delete the tunnel itself from your Cloudflare account
# or the config/credentials-*.json files on disk (those are host files, not
# Docker resources) — only the running container. To fully retire the
# tunnel, also run `cloudflared tunnel delete <name>` and remove the DNS
# record it created, and delete config/ by hand if you want a clean slate.
set -e

PROJECT=cloudflared
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CONTAINERS=$(docker compose -p "$PROJECT" ps -a \
    --format "  {{.Name}}  ({{.Status}})" 2>/dev/null || true)
IMAGES=$(docker compose -p "$PROJECT" images 2>/dev/null \
    | awk 'NR>1 && $2!="<none>" {print "  "$2":"$3}' | sort -u || true)
NETWORKS=$(docker network ls \
    --filter "label=com.docker.compose.project=$PROJECT" \
    --format "  {{.Name}}" 2>/dev/null || true)

echo "══════════════════════════════════════════"
echo "  cloudflared — teardown"
echo "══════════════════════════════════════════"
echo ""
echo "The following Docker resources will be permanently removed:"
echo ""
echo "Containers:"
[[ -n "$CONTAINERS" ]] && echo "$CONTAINERS" || echo "  (none)"
echo ""
echo "Images:"
[[ -n "$IMAGES" ]] && echo "$IMAGES" || echo "  (none)"
echo ""
echo "Networks:"
[[ -n "$NETWORKS" ]] && echo "$NETWORKS" || echo "  (none)"
echo ""
echo "NOTE: this stops Alexa (and anything else routed through this tunnel)"
echo "from being reachable from the public internet until start.sh is run"
echo "again. The tunnel itself and config/ are NOT deleted — see this"
echo "script's header comment to fully retire it."
echo "──────────────────────────────────────────"
echo ""
read -r -p "Proceed with teardown? [y/N] " REPLY
echo ""

if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted — nothing was removed."
    exit 0
fi

echo "Removing containers, images, and networks..."
docker compose -p "$PROJECT" down --rmi all --remove-orphans

echo ""
echo "Done. Re-run start.sh to create a fresh installation."
