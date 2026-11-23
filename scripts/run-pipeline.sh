#!/usr/bin/env bash
set -euo pipefail

DEMO_NUM="${1:-}"
export KAFKA_BROKERS="${KAFKA_BROKERS:-localhost:19092}"

case "$DEMO_NUM" in
  1)
    CONFIG="pipelines/01-kafka-to-processed.yaml"
    ;;
  2)
    CONFIG="pipelines/02-output-fallback-dlq.yaml"
    ;;
  3)
    CONFIG="pipelines/03-http-enrichment-illustrative.yaml"
    ;;
  *)
    echo "Usage: $0 {1|2|3}" >&2
    exit 1
    ;;
esac

if [[ ! -f "$CONFIG" ]]; then
  echo "Pipeline config not found: $CONFIG" >&2
  exit 1
fi

if command -v bento >/dev/null 2>&1; then
  bento lint "$CONFIG"
  exec bento -c "$CONFIG"
else
  docker run --rm --network host \
    -e KAFKA_BROKERS="$KAFKA_BROKERS" \
    -v "$(pwd):/work" -w /work \
    ghcr.io/warpstreamlabs/bento lint "$CONFIG"
  exec docker run --rm --network host \
    -e KAFKA_BROKERS="$KAFKA_BROKERS" \
    -v "$(pwd):/work" -w /work \
    ghcr.io/warpstreamlabs/bento -c "$CONFIG"
fi
