SHELL := /bin/bash
.DEFAULT_GOAL := help

PRESENTATION ?= presentation.md
KAFKA_BROKERS ?= localhost:19092
PIPELINE_1 ?= pipelines/01-kafka-to-processed.yaml
PIPELINE_2 ?= pipelines/02-output-fallback-dlq.yaml
PIPELINE_3 ?= pipelines/03-http-enrichment-illustrative.yaml
TEST_FILE ?= tests/01-kafka-to-processed_bento_test.yaml

.PHONY: help up down reset ps topics present notes lint test demo1 demo2 demo3 consume

help: ## Afficher les commandes disponibles
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

up: ## Démarrer Redpanda, Console et mock-api
	docker compose up -d

ps: ## Vérifier l'état des services
	docker compose ps

topics: ## Créer les topics Kafka/Redpanda nécessaires
	./scripts/setup-topics.sh

present: ## Lancer Presenterm avec publication des notes orateur
	presenterm $(PRESENTATION) --enable-snippet-execution --publish-speaker-notes

notes: ## Afficher les notes orateur dans un second terminal
	presenterm $(PRESENTATION) --listen-speaker-notes

lint: ## Valider la syntaxe des configurations Bento
	@if command -v bento >/dev/null 2>&1; then \
		bento lint $(PIPELINE_1) $(PIPELINE_2) $(PIPELINE_3); \
	else \
		docker run --rm -v "$(CURDIR):/work" -w /work ghcr.io/warpstreamlabs/bento lint $(PIPELINE_1) $(PIPELINE_2) $(PIPELINE_3); \
	fi

test: ## Exécuter les tests unitaires Bento
	@if command -v bento >/dev/null 2>&1; then \
		bento test $(TEST_FILE); \
	else \
		docker run --rm -v "$(CURDIR):/work" -w /work ghcr.io/warpstreamlabs/bento test $(TEST_FILE); \
	fi

demo1: ## Lancer la Démo 1 (Kafka -> mapping -> Kafka)
	KAFKA_BROKERS=$(KAFKA_BROKERS) ./scripts/run-pipeline.sh 1

demo2: ## Lancer la Démo 2 (output fallback vers DLQ)
	KAFKA_BROKERS=$(KAFKA_BROKERS) ./scripts/run-pipeline.sh 2

demo3: ## Lancer l'exemple illustratif d'enrichissement HTTP
	KAFKA_BROKERS=$(KAFKA_BROKERS) ./scripts/run-pipeline.sh 3

consume: ## Consommer un topic (ex: make consume TOPIC=orders-processed)
	./scripts/consume-topic.sh $(or $(TOPIC),orders-processed)

down: ## Arrêter les conteneurs
	docker compose down

reset: ## Arrêter les conteneurs et supprimer les volumes
	docker compose down -v
