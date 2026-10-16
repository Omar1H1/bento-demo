#!/usr/bin/env sh
set -eu

case "${1:-help}" in
  up)
    docker compose up -d
    docker compose ps
    ;;
  lint)
    bento lint pipelines/01-kafka-to-processed.yaml
    bento lint pipelines/02-output-fallback-dlq.yaml
    ;;
  test)
    bento test tests/01-kafka-to-processed_bento_test.yaml
    ;;
  run)
    exec bento -c pipelines/01-kafka-to-processed.yaml
    ;;
  publish)
    printf '%s\n' '{"order_id":101,"customer_id":42,"total":29.90}' |
      docker compose exec -T redpanda rpk topic produce orders
    ;;
  consume)
    docker compose exec redpanda rpk topic consume orders-processed -n 1
    ;;
  down)
    docker compose down
    ;;
  help|*)
    cat <<'EOF'
Usage: scripts/demo.sh {up|lint|test|run|publish|consume|down}
  up       start Redpanda and Console
  lint     lint the runnable pipeline configs
  test     run the processor unit test
  run      run the Bento consumer (foreground)
  publish  publish one example order
  consume  consume one processed order
  down     stop services (keeps the volume)
EOF
    ;;
esac
