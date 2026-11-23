# Bento — présentation Presenterm + démos locales

Ce projet regroupe la présentation Markdown (`presentation.md`), les configurations et tests WarpStream Bento, un broker Redpanda (avec Redpanda Console et une API mock locale), un `Makefile` et les scripts pour reproduire les démos.

## Prérequis

- Docker Engine + `docker compose`
- GNU `make` et `bash`
- `bento` (WarpStream Bento, `ghcr.io/warpstreamlabs/bento` ou binaire local)
- `presenterm`
- Un terminal compatible avec les images utilisées par Presenterm

Les commandes ci-dessous sont prévues pour être lancées depuis la racine du projet.

## Structure du projet

- `compose.yaml` — services `redpanda` (`localhost:19092`), `console` (`localhost:8080`), `mock-api` (`localhost:18080`) et service optionnel `bento` (`ghcr.io/warpstreamlabs/bento`)
- `Makefile` — raccourcis pour l'environnement, la présentation, le lint, les tests et les démos
- `presentation.md` — slides Presenterm et notes orateur
- `pipelines/` — configurations Bento (`01-kafka-to-processed.yaml`, `02-output-fallback-dlq.yaml`, `03-http-enrichment-illustrative.yaml`)
- `tests/` — tests unitaires Bento (`01-kafka-to-processed_bento_test.yaml`)
- `scripts/` — `setup-topics.sh`, `run-pipeline.sh`, `publish-demo-message.sh`, `consume-topic.sh`

## 1. Démarrer l'environnement

Démarrer les services :

```sh
make up
```

Vérifier l'état des conteneurs, puis créer les topics (`orders`, `orders-processed`, `orders-dlq`, `orders-enriched`) :

```sh
make ps
make topics
```

Le broker est accessible depuis l'hôte sur `localhost:19092` (et `redpanda:9092` depuis le réseau Docker). Redpanda Console est disponible sur `http://localhost:8080` et l'API mock d'enrichissement sur `http://localhost:18080`.

## 2. Présenter les slides

Dans un terminal :

```sh
make present
```

Pour afficher les notes orateur dans un second terminal :

```sh
make notes
```

## 3. Démo 1 — Kafka → transformation → Kafka

Dans un terminal, lancer le pipeline :

```sh
make demo1
```

Dans un autre terminal, publier un message :

```sh
./scripts/publish-demo-message.sh
```

Observer le message transformé dans un troisième terminal :

```sh
make consume TOPIC=orders-processed
```

Le message de sortie contient `demo_processed` et `processed_at`. Pour rejouer la démo, republier un message avec un `order_id` différent :

```sh
./scripts/publish-demo-message.sh '{"order_id":102,"customer_id":42,"total":29.9}'
```

## 4. Démo 2 — output fallback vers une DLQ

Lancer :

```sh
make demo2
```

Puis publier un message :

```sh
./scripts/publish-demo-message.sh '{"order_id":202,"customer_id":7,"total":12.5}'
```

Lorsque la sortie principale échoue, le fallback route le message vers `orders-dlq`. Observer la DLQ :

```sh
make consume TOPIC=orders-dlq
```

C'est une démonstration de fallback d'output vers une DLQ, pas une politique générale de retry.

## 5. Exemple HTTP d'enrichissement

Le fichier `pipelines/03-http-enrichment-illustrative.yaml` utilise l'API mock locale (`http://localhost:18080`) :

```sh
make demo3
```

Publier un message puis lire le résultat :

```sh
./scripts/publish-demo-message.sh '{"order_id":303,"customer_id":9,"total":45.0}'
make consume TOPIC=orders-enriched
```

Cet exemple reste distinct du fallback d'output de la démo 2.

## 6. Lint et tests unitaires Bento

Valider la configuration et exécuter les tests unitaires :

```sh
make lint
make test
```

## Arrêter et nettoyer

```sh
make down
```

Pour supprimer aussi les données persistées de Redpanda :

```sh
make reset
```

## Références

- Presenterm — commandes et notes du présentateur : https://mfontanini.github.io/presenterm/features/speaker-notes.html
- WarpStream Bento — documentation : https://warpstreamlabs.github.io/bento/
- WarpStream Bento — dépôt GitHub : https://github.com/warpstreamlabs/bento
- Bento — configuration : https://warpstreamlabs.github.io/bento/docs/configuration/about/
- Bento — entrée Kafka : https://warpstreamlabs.github.io/bento/docs/components/inputs/kafka/
- Bento — output fallback : https://warpstreamlabs.github.io/bento/docs/components/outputs/about/