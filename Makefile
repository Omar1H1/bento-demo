COMPOSE ?= podman compose
RPK     := $(COMPOSE) exec -T redpanda rpk
TOPICS  := sinistres sinistres-enrichis
DIR     ?= pipelines
P       ?= 1-pont
TOPIC   ?= sinistres

.DEFAULT_GOAL := help
.PHONY: help up topics reset run test prod watch psql slides notes down clean

help: ## Liste les commandes
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-9s %s\n", $$1, $$2}'

up: ## Démarre Redpanda, la console (:8080) et Postgres, crée les topics
	$(COMPOSE) up -d --wait
	$(MAKE) --no-print-directory topics
	$(COMPOSE) ps

topics: ## Crée les topics
	@for t in $(TOPICS); do echo "rpk topic create $$t"; $(RPK) topic create $$t -p 1 2>&1 | tail -n +2 || true; done
	$(RPK) topic list

reset: ## Vide les topics pour rejouer
	-$(RPK) topic delete $(TOPICS)
	@sleep 2
	$(MAKE) --no-print-directory topics

run: ## Lance un pipeline : make run P=1-pont, ou P=pont DIR=backup
	bento -c $(DIR)/$(P).yaml

test: ## Tests unitaires : make test [DIR=pipelines|backup]
	bento test ./$(DIR)/...

prod: ## Pipeline sans fin : logs JSON, métriques sur :4195
	@bento -c prod/normalisation.yaml

watch: ## Suit un topic en direct : make watch TOPIC=sinistres
	@$(RPK) topic consume $(TOPIC) -o end -f '%k  %v\n'

psql: ## Ouvre psql sur la base assurance
	$(COMPOSE) exec postgres psql -U bento assurance

slides: ## Présente (notes publiées pour un 2e terminal)
	presenterm presentation.md --publish-speaker-notes

notes: ## 2e terminal : notes du présentateur
	presenterm presentation.md --listen-speaker-notes

down: ## Arrête les conteneurs
	$(COMPOSE) down

clean: ## Arrête et supprime les volumes (Postgres re-seedé)
	$(COMPOSE) down -v
