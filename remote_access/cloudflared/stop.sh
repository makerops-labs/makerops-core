#!/bin/bash
# Stops the cloudflared container. config/ (tunnel identity) is preserved.
set -e

PROJECT=cloudflared

docker compose -p "$PROJECT" down "$@"
