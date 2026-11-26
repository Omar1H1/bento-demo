# Bento — présentation + démo

Prérequis : Podman (avec `docker-compose` ou `podman-compose` pour `podman compose`), [presenterm](https://github.com/mfontanini/presenterm), `bento`, `make`, `jq`.
Tout se lance depuis la racine du projet. Les images vont dans `assets/` (`output.png`, `openshift.png`).

```sh
make up          # Redpanda + console (:8080) + Postgres, topics créés
make slides      # présenter (Ctrl+E pour exécuter un bloc)
make notes       # 2e terminal : notes du présentateur (minutage)
make reset       # rejouer depuis zéro
```

Pendant le talk, les pipelines s'écrivent en live dans `pipelines/` ; secours dans `backup/` :

```sh
make run P=pont DIR=backup            # cas 1 : CSV → Kafka
make run P=enrichissement DIR=backup  # cas 2 : + lookup Postgres
make watch TOPIC=sinistres            # suivre un topic en direct
make test                             # test du cas 2 (Postgres mocké)
make test DIR=backup                  # même test, version de secours
```

Un test porte le nom de la config suivi de `_bento_test` : `2-enrichissement.yaml` → `2-enrichissement_bento_test.yaml`.

En production (pipeline sans fin dans `prod/`) :

```sh
make prod 2>&1 | jq -c '{niveau: .level, msg, sinistre_id, valide}'          # logs JSON
curl -s localhost:4195/metrics | grep -E '^(input_received|output_sent|output_error|processor_error)'
```

Une seule instance de `make prod` à la fois (port 4195). `make help` liste tout.
