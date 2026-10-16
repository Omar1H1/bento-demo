---
title: Bento
sub_title: Simplifier vos pipelines de données
theme:
  name: catppuccin-latte
  override:
    footer:
      style: template
      left:
        image: assets/output.png
      height: 3
author: Omar HAMAD
---

<!-- alignment: center -->

# Bento

## Simplifier vos pipelines de données

<!-- pause -->

Des pipelines lisibles. Des erreurs pensées.

<!-- speaker_note: TODO -->

<!-- end_slide -->

<!-- alignment: center -->

# whoami

<!-- pause -->

```bash +exec
/// whoami() { echo "/maif/dsi/datathèque/TED/omar-hamad"; }
whoami
```

<!-- end_slide -->

<!-- alignment: center -->

# Pas une couche de code en plus.

<!-- pause -->

Une description de ce que le pipeline doit faire.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Un pipeline, c'est quoi ?

De la donnée qui va d'un **point A** vers un **point B**, des sources et des sinks

<!-- pause -->

**La source** peut être...

<!-- pause -->

![image:width:5%](./assets/postgre.png)

<!-- pause -->

![image](./assets/kafka.png)

<!-- pause -->

![image:width:5%](./assets/csv.png)

<!-- pause -->

![image:width:5%](./assets/rest.jpg)

<!-- pause -->

**La destination** peut être...

<!-- pause -->

![image:width:5%](./assets/postgre.png)

<!-- pause -->

![image:width:5%](./assets/es.png)

<!-- pause -->

![image:width:5%](./assets/s3.png)

<!-- pause -->

![image:width:5%](./assets/duckdb.png)

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Le trajet n'est pas toute l'histoire

<!-- pause -->

Entre A et B, il faut parfois...

<!-- pause -->

**Transformer** la donnée.

<!-- pause -->

**Enrichir** un message avec un appel HTTP.

<!-- pause -->

**Gérer** une destination indisponible.

<!-- pause -->

**Limiter** le travail en cours pour ne pas saturer le système.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Comment lisez-vous un fichier CSV de 20 Go ?

<!-- pause -->

**Tout charger en mémoire** : simple, jusqu'au manque de mémoire.

<!-- pause -->

**Lire progressivement** : combien de lignes ou de messages en vol ?

<!-- pause -->

**Et si la destination ralentit ?** La source doit-elle continuer à produire ?

<!-- pause -->

## Ce sont des décisions de flux, pas seulement de syntaxe.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Deux notions à garder en tête

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

**In-flight data**

Combien de messages sont en cours de traitement ?

<!-- column: 1 -->

**Backpressure**

Comment ralentir l'amont quand l'aval ne suit plus ?

<!-- reset_layout -->

<!-- pause -->

Ces mécanismes doivent être compris, configurés et observés.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Le biais du développeur

<!-- pause -->

On pense naturellement aux erreurs métier.

_« Cet utilisateur existe-t-il ? »_

<!-- pause -->

Mais les dépendances peuvent aussi échouer.

DNS. Timeout. Réseau. Service indisponible.

<!-- pause -->

## Une erreur technique peut changer le destin de tout un batch.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Le scénario Kafka

Un batch de **20 messages**.

<!-- pause -->

Chaque message déclenche un appel HTTP externe.

<!-- pause -->

19 appels réussissent.

<!-- pause -->

Le 20ᵉ échoue : le service est indisponible.

<!-- pause -->

## Qu'est-ce qui a été confirmé ? Qu'est-ce qui doit être rejoué ?

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Le piège : confondre échec et succès partiel

```go
func processBatch(messages []kafka.Message) error {
    for i, msg := range messages {
        resp, err := httpClient.Post(enrichURL, msg.Body)
        if err != nil {
            return err // le commit final n'est pas atteint
        }
        if resp.StatusCode == http.StatusNotFound {
            log.Printf("message %d: utilisateur absent, skip", i)
            continue
        }
        index(msg, resp)
    }
    return consumer.CommitBatch(messages)
}
```

<!-- pause -->

Si le commit porte sur le batch entier, l'échec du dernier appel peut entraîner le rejeu des messages précédents.

<!-- pause -->

**Conséquence possible :** travail répété, effets de bord dupliqués, progression bloquée.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Que devrait-on gérer à la main ?

<!-- pause -->

Les règles métier.

<!-- pause -->

Les transformations propres au domaine.

<!-- pause -->

Les choix explicites de reprise, de fallback et de DLQ.

<!-- pause -->

## Pas toute la plomberie du flux.

<!-- pause -->

Trois démos pour le montrer : le transport de base, une destination qui échoue, et ce que l'enrichissement HTTP change à l'équation.

<!-- speaker_note: TODO -->

<!-- end_slide -->

<!-- alignment: center -->

# Démo 1

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Le pipeline tient en quelques blocs

```yaml
input:
  kafka:
    addresses: ["${KAFKA_BROKERS:localhost:19092}"]
    topics: ["orders"]
    consumer_group: "bento-presenterm-demo"
    checkpoint_limit: 16

pipeline:
  processors:
    - mapping: |
        root = this
        root.demo_processed = true
        root.processed_at = now()

output:
  kafka:
    addresses: ["${KAFKA_BROKERS:localhost:19092}"]
    topic: "orders-processed"
    key: '${! json("order_id") }'
```

<!-- pause -->

La configuration décrit le flux ; le runtime exécute les composants et applique leurs mécanismes de traitement.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Ce que Bento prend en charge

<!-- pause -->

**Le transport** : lire et écrire via les composants configurés.

<!-- pause -->

**Le flux** : limiter le travail en cours et appliquer la backpressure.

<!-- pause -->

**Les erreurs** : propager les échecs et appliquer la stratégie configurée.

<!-- pause -->

Pour répondre à la question posée tout à l'heure : le commit du consumer suit le composant input, pas un minuteur séparé — un message n'est acquitté qu'une fois sorti du pipeline. Le détail exact (par message ou par batch) dépend du composant et de sa configuration.

<!-- speaker_note: TODO -->

<!-- end_slide -->

<!-- alignment: center -->

# Démo 2

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Un fallback d'output

```yaml
output:
  fallback:
    - kafka:
        addresses: ["${KAFKA_BROKERS:localhost:19092}"]
        topic: "orders-processed"
    - kafka:
        addresses: ["${KAFKA_BROKERS:localhost:19092}"]
        topic: "orders-dlq"
```

<!-- pause -->

La seconde sortie est une solution de repli si la première échoue.

<!-- pause -->

## Une DLQ n'est pas une stratégie de retry universelle.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Et l'enrichissement HTTP du scénario Kafka ?

<!-- pause -->

Une API nominale peut tomber, exactement comme dans l'exemple Go.

<!-- pause -->

On peut définir un fallback applicatif : source secondaire, valeur par défaut ou échec contrôlé.

<!-- pause -->

Mais il faut distinguer cet enchaînement du fallback d'output vu à l'instant.

<!-- pause -->

## Annoncé en introduction : cette partie reste illustrative, pas démontrée en direct.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Un YAML, ça se teste ?

<!-- pause -->

Oui : la configuration peut être versionnée et validée.

<!-- pause -->

`bento lint` détecte les erreurs de configuration.

<!-- pause -->

`bento test` exécute des tests sur des processeurs ciblés.

<!-- pause -->

## Ce n'est pas un test d'intégration du broker.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# Un test de transformation

```yaml
tests:
  - name: adds demo marker and timestamp
    target_processors: "/pipeline/processors"
    input_batch:
      - json_content:
          order_id: 101
          customer_id: 42
          total: 29.9
    output_batches:
      - - json_equals:
            order_id: 101
            customer_id: 42
            total: 29.9
            demo_processed: true
```

<!-- pause -->

Le test est versionné à côté du pipeline et peut tourner en CI.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# De la démo à la CI

```sh
bento lint pipelines/01-kafka-to-processed.yaml
bento test tests/01-kafka-to-processed_bento_test.yaml
```

<!-- pause -->

Un pipeline déclaratif peut être relu, contrôlé et testé avant déploiement.

<!-- pause -->

La CI ne remplace pas les tests d'intégration ni l'observabilité en production.

<!-- speaker_note: TODO -->

<!-- end_slide -->

# L'observabilité fait partie du système

<!-- pause -->

Métriques, logs et traces doivent aider à répondre à trois questions :

<!-- pause -->

**Est-ce que ça avance ?**

<!-- pause -->

**Où est-ce que ça ralentit ?**

<!-- pause -->

**Pourquoi ce message est-il en échec ?**

<!-- speaker_note: TODO -->

<!-- end_slide -->

# À retenir

<!-- pause -->

- Un pipeline, ce n'est pas seulement A → B : c'est aussi la transformation et les échecs.

<!-- pause -->

- Backpressure et données en vol influencent la stabilité du flux.

<!-- pause -->

- Bento rend la configuration explicite et réutilisable.

<!-- pause -->

- Retries, fallback et DLQ doivent correspondre au comportement souhaité.

<!-- pause -->

- Lint, tests et observabilité complètent la configuration.

<!-- speaker_note: TODO -->

<!-- end_slide -->

<!-- alignment: center -->

# Questions ?

<!-- pause -->

## Merci !

Docs : https://warpstreamlabs.github.io/bento

GitHub : warpstreamlabs/bento