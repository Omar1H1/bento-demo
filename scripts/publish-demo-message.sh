#!/usr/bin/env bash
set -euo pipefail

TOPIC="${TOPIC:-orders}"
PAYLOAD="${1:-{\"order_id\":101,\"customer_id\":42,\"total\":29.9}}"

printf '%s\n' "$PAYLOAD" | docker compose exec -T redpanda rpk topic produce "$TOPIC" --brokers localhost:9092
