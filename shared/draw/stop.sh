#!/bin/bash
# Stops the draw.io service. draw.io is stateless — no persistent data volumes.
# Pass --volumes to also remove any named volumes.
set -e

PROJECT=draw

docker compose -p "$PROJECT" down "$@"
