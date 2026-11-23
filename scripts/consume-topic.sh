#!/usr/bin/env bash
set -euo pipefail

TOPIC="${1:-orders-processed}"

exec docker compose exec -T redpanda rpk topic consume "$TOPIC" --brokers localhost:9092 --offset start
