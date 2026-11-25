COMPOSE ?= docker compose
RPK     := $(COMPOSE) exec -T redpanda rpk
TOPICS  := sinistres sinistres-enrichis sinistres-stats
DIR     ?= pipelines
P       ?= pont
TOPIC   ?= sinistres
N       ?= 3

.DEFAULT_GOAL := help
.PHONY: test prod load flame help up ps topics reset run lint consume watch stats psql slides notes down clean

help: ## Liste les commandes
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-9s %s\n", $$1, $$2}'

up: ## Démarre Redpanda, la console (:8080) et Postgres, crée les topics
	$(COMPOSE) up -d --wait
	$(MAKE) --no-print-directory topics
	$(COMPOSE) ps

ps: ## Liste les conteneurs
	$(COMPOSE) ps

topics: ## Crée les topics
	@for t in $(TOPICS); do echo "rpk topic create $$t"; $(RPK) topic create $$t -p 1 2>&1 | tail -n +2 || true; done
	$(RPK) topic list

reset: ## Vide topics et archives pour rejouer
	-$(RPK) topic delete $(TOPICS)
	rm -f archives/*.gz
	@sleep 2
	$(MAKE) --no-print-directory topics

run: ## Lance un pipeline : make run P=pont [DIR=backup]
	bento -c $(DIR)/$(P).yaml

test: ## Lint + tests unitaires du pipeline de testing/
	bento lint testing/normalisation.yaml
	bento test ./testing/...

prod: ## Lance testing/normalisation.yaml (logs JSON, métriques :4195)
	@bento -c testing/normalisation.yaml

load: ## Même pipeline, à pleine charge (pour pprof)
	@INTERVAL=1ms MSG_LOG_LEVEL=DEBUG bento -c testing/normalisation.yaml

flame: ## Flamegraph CPU de 10 s dans le navigateur (:8081)
	go tool pprof -http=:8081 'http://localhost:4195/debug/pprof/profile?seconds=10'

lint: ## Valide les pipelines
	bento lint $(wildcard $(DIR)/*.yaml)

consume: ## Lit un topic : make consume TOPIC=sinistres N=3
	@$(RPK) topic consume $(TOPIC) -o start -n $(N) -f '%k  %v\n'

watch: ## Suit un topic en direct : make watch TOPIC=sinistres
	@$(RPK) topic consume $(TOPIC) -o end -f '%k  %v\n'

stats: ## Nombre de messages par topic
	@for t in $(TOPICS); do printf "%-20s" $$t; $(RPK) topic describe $$t -p | awk 'NR>1 {n+=$$NF} END {print n+0}'; done

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
