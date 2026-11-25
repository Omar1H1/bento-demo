# Bento — présentation + démo

Prérequis : Docker, [presenterm](https://github.com/mfontanini/presenterm), `bento`, `make`.
Tout se lance depuis la racine du projet. Le footer attend `assets/output.png`.

```sh
make up          # Redpanda + console (:8080) + Postgres, topics créés
make slides      # présenter (Ctrl+E pour exécuter un bloc)
make notes       # 2e terminal : notes du présentateur (minutage)
make reset       # rejouer depuis zéro
```

Quatre cas, écrits en live dans `pipelines/` ; secours dans `backup/` :

```sh
make lint DIR=backup
make run P=pont DIR=backup            # CSV → Kafka
make run P=enrichissement DIR=backup  # + lookup Postgres
make run P=analyse DIR=backup         # vue Postgres → Kafka
make run P=sauvegarde DIR=backup      # lots gzip → archives/
make run P=restauration DIR=backup    # relecture des archives
make consume TOPIC=sinistres-enrichis N=3
make watch TOPIC=sinistres            # suivre un topic en direct
```

- `testing/` : tests, logs JSON, métriques, pprof (voir son README)
- `data/` : `sinistres.csv` (2 000 lignes) et `init.sql` (clients, sinistres, vue `stats_par_type`)
- Durée : ~15 min. `make help` liste tout.
