#!/usr/bin/env bash
set -euo pipefail

TOPICS=("orders" "orders-processed" "orders-dlq" "orders-enriched")

for topic in "${TOPICS[@]}"; do
  docker compose exec -T redpanda rpk topic create "$topic" \
    --brokers localhost:9092 \
    --partitions 1 \
    --replicas 1 >/dev/null 2>&1 || true
done
