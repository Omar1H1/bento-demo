# Bento — présentation Presenterm + démos locales

Ce projet regroupe la présentation Markdown, trois configurations Bento, Redpanda et les commandes nécessaires pour reproduire les démos.

## Prérequis

- Docker Engine + `docker compose`
- `presenterm`
- Un terminal compatible avec les images utilisées par Presenterm

Les commandes ci-dessous sont prévues pour être lancées depuis la racine du projet.

## 1. Démarrer l'environnement

```sh
docker compose up -d redpanda mock-api
```

Attendre que Redpanda soit prêt, puis créer les topics :

```sh
docker compose ps
./scripts/setup-topics.sh
```

Le broker est accessible depuis l'hôte sur `localhost:19092` et depuis les conteneurs sur `redpanda:9092`. La petite API locale d'enrichissement est exposée sur `http://localhost:18080`.

## 2. Présenter les slides

Dans un terminal :

```sh
presenterm presentation.md --publish-speaker-notes
```

Pour afficher les notes dans un deuxième terminal :

```sh
presenterm presentation.md --listen-speaker-notes
```

## 3. Démo 1 — Kafka → transformation → Kafka

Dans un terminal, lancer le pipeline :

```sh
./scripts/run-pipeline.sh 1
```

Dans un autre terminal, publier un message :

```sh
./scripts/publish-demo-message.sh
```

Observer le message transformé dans un troisième terminal :

```sh
./scripts/consume-topic.sh orders-processed
```

Le message de sortie contient `demo_processed` et `processed_at`. Pour rejouer la démo, republier un message avec un `order_id` différent.

## 4. Démo 2 — output fallback vers une DLQ

Lancer :

```sh
./scripts/run-pipeline.sh 2
```

Puis publier un message :

```sh
./scripts/publish-demo-message.sh '{"order_id":202,"customer_id":7,"total":12.5}'
```

L'output HTTP est volontairement configuré vers un port local inaccessible depuis le conteneur Bento. Le fallback envoie donc le message vers `orders-dlq`. Observer la DLQ :

```sh
./scripts/consume-topic.sh orders-dlq
```

Cette panne est déterministe et ne nécessite pas d'arrêter Redpanda. C'est une démo de fallback d'output, pas une politique générale de retry.

## 5. Exemple HTTP d'enrichissement

Le fichier `pipelines/03-http-enrichment-illustrative.yaml` est également exécutable avec l'API mock locale incluse :

```sh
./scripts/run-pipeline.sh 3
```

Publier un message puis lire le résultat :

```sh
./scripts/publish-demo-message.sh '{"order_id":303,"customer_id":9,"total":45.0}'
./scripts/consume-topic.sh orders-enriched
```

L'API mock renvoie un petit objet d'enrichissement. Cet exemple reste distinct du fallback d'output de la démo 2.

## Arrêter et nettoyer

```sh
docker compose down
```

Pour supprimer aussi les données persistées de Redpanda :

```sh
docker compose down -v
```

## Références

- Presenterm — commandes et notes du présentateur : https://mfontanini.github.io/presenterm/features/speaker-notes.html
- Bento — configuration : https://warpstreamlabs.github.io/bento/docs/configuration/about/
- Bento — entrée Kafka : https://warpstreamlabs.github.io/bento/docs/components/inputs/kafka/
- Bento — output fallback : https://warpstreamlabs.github.io/bento/docs/components/outputs/about/
