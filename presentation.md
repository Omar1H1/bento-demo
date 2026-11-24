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

# whoami

<!-- pause -->

```bash +exec
/// whoami() { echo "/maif/dsi/datathèque/TED/omar-hamad"; }
whoami
```

<!-- speaker_note: |
  [0:00 → 0:20]
  - Ctrl+E, laisser le gag
  - (sourire, ne rien dire)
-->

<!-- end_slide -->

# De la donnée, il y en a partout

<!-- pause -->

Batch. Streaming.

<!-- pause -->

ETL. ELT.

<!-- pause -->

Un pont entre deux systèmes.

<!-- pause -->

## Au fond : on déplace et on transforme de la donnée.

<!-- speaker_note: |
  [0:20 → 0:45] ton : chaleureux, calme
  - "plomberie" (sourire)
  - batch / streaming / ETL / ELT : mots différents, même geste
  - déplacer + transformer
  → "deux familles de solutions"
-->

<!-- end_slide -->

# Deux façons de faire

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

**Un programme sur mesure**

Beaucoup de code à maintenir.

<!-- pause -->

<!-- column: 1 -->

**Un moteur lourd**

Flink, Spark : un cluster à exploiter.

<!-- reset_layout -->

<!-- pause -->

Parfois, c'est exactement ce qu'il faut. Souvent, c'est trop.

<!-- speaker_note: |
  [0:45 → 1:15] ton : respectueux, jamais de mépris
  - sur mesure : on l'a tous écrit, il faut le maintenir
  - moteur lourd : formidable, mais un cluster à piloter
  - (léger sourire) "un camion pour une baguette"
  → "un entre-deux ?"
-->

<!-- end_slide -->

<!-- alignment: center -->

# Et si c'était plus simple ?

<!-- pause -->

Simple à exploiter.

<!-- pause -->

Facile à faire grandir.

<!-- pause -->

Rien de lourd à porter.

<!-- speaker_note: |
  [1:15 → 1:35] ton : lent, laisser respirer
  - 3 phrases, 3 pauses
  - simple / grandir / léger
  → "Bento"
-->

<!-- end_slide -->

# Bento

<!-- column_layout: [1, 1, 1] -->

<!-- column: 0 -->

**Sources**

Fichier, base, Kafka, API...

<!-- pause -->

<!-- column: 1 -->

**Traitements**

Transformer, filtrer, enrichir.

<!-- pause -->

<!-- column: 2 -->

**Destinations**

Base, topic, fichier...

<!-- reset_layout -->

<!-- speaker_note: |
  [1:35 → 2:25] ton : pédagogue, simple
  - 3 blocs : entre / transforme / sort
  - 4 briques aujourd'hui : CSV, Postgres → Kafka, fichiers
  - si question : fork Benthos, MIT, WarpStream
  → "qu'est-ce qui le rend simple ?"
-->

<!-- end_slide -->

# Pourquoi c'est simple

```bash +exec
B="$(command -v bento)" || { echo "bento introuvable dans le PATH"; exit 1; }
ls -lhL "$B"
file "$B" | cut -d, -f1-2
```

<!-- pause -->

**Un seul binaire.** Rien à installer autour.

<!-- pause -->

**Un fichier YAML.** On décrit, on ne compile pas.

<!-- pause -->

**Sans état.** Une instance de plus, et ça monte en charge.

<!-- pause -->

**Transactionnel.** Acquitté seulement une fois bien livré.

<!-- speaker_note: |
  [2:25 → 3:35] Ctrl+E dès l'arrivée
  - le binaire : un fichier, rien de caché (montrer la taille)
  - YAML : on décrit
  - sans état : s'appuie sur les systèmes reliés → on en lance dix
  - transactionnel : ack après livraison
  - (honnête, regard salle) at-least-once = doublon possible
  → "on l'utilise, quatre fois"
-->

<!-- end_slide -->

# Quatre cas, un par un

<!-- pause -->

**1. Le pont** : un CSV vers Kafka

<!-- pause -->

**2. L'enrichissement** : ajouter des infos de Postgres

<!-- pause -->

**3. L'analyse légère** : Postgres calcule, Bento publie

<!-- pause -->

**4. La sauvegarde** : par lots, compressée, relue

<!-- speaker_note: |
  [3:35 → 3:50] ton : rapide
  - du simple au riche
  - "j'écris chaque pipeline devant vous"
-->

<!-- end_slide -->

# Notre terrain de jeu

```bash +exec
docker compose ps --format "table {{.Service}}\t{{.Status}}"
```

```bash +exec
head -4 data/sinistres.csv
```

```bash +exec
docker compose exec -T postgres psql -U bento assurance -c "SELECT * FROM clients LIMIT 4"
```

<!-- speaker_note: |
  [3:50 → 4:30] Ctrl+E ×3, un par un
  - conteneurs : Redpanda, console :8080, Postgres → "rien d'autre"
  - CSV : 2 000 sinistres, juste un client_id
  - clients : les noms sont ici
  - (complice) "retenez la frustration"
  - démarré avant (images) : le dire
  → terminal
-->

<!-- end_slide -->

<!-- alignment: center -->

# Cas n°1

## Le pont

CSV → Kafka

<!-- pause -->

Comment passer d'un fichier à un topic ?

<!-- speaker_note: |
  [4:30 → 6:30] terminal — secours : make run P=pont DIR=backup
  gestes :
  - input file + scanner csv → lancer : JSON défile
  - ajouter output kafka (19092, topic sinistres, clé sinistre_id)
  - 2e terminal : make watch TOPIC=sinistres ; console :8080
  preuve : 2 000 messages, pas d'erreur
  (logs de démarrage normaux)
  → "mais qui est le client ?"
-->

<!-- end_slide -->

<!-- alignment: center -->

# Cas n°2

## L'enrichissement

CSV + Postgres → Kafka

<!-- pause -->

Et si le message savait qui est le client ?

<!-- speaker_note: |
  [6:30 → 8:40] terminal — secours : make run P=enrichissement DIR=backup
  gestes :
  - partir du pont, ajouter pipeline
  - branch : "chercher ailleurs, rattacher sans écraser"
  - sql_select clients (15432), where client_id
  - topic sinistres-enrichis ; threads: 4
  - make watch TOPIC=sinistres-enrichis
  mots-clés : request_map / result_map / Bloblang ("gauche = droite")
  preuve : le client est dans le message
  → "et des chiffres ?"
-->

<!-- end_slide -->

<!-- alignment: center -->

# Cas n°3

## L'analyse légère

Postgres → Kafka

<!-- pause -->

Pas besoin d'un gros moteur pour compter.

<!-- speaker_note: |
  [8:40 → 10:15] terminal — secours : make run P=analyse DIR=backup
  gestes :
  - make psql → SELECT * FROM stats_par_type
  - input sql_select sur la vue → output kafka sinistres-stats
  - make consume TOPIC=sinistres-stats N=7
  idée : sans état → la base calcule, Bento publie
  (détendu) même pipeline, autre entrée ; flux borné → s'arrête
  → "garder une trace ?"
-->

<!-- end_slide -->

<!-- alignment: center -->

# Cas n°4

## La sauvegarde

Postgres → fichiers → relecture

<!-- pause -->

Des lots, de la compression, et on relit.

<!-- speaker_note: |
  [10:15 → 12:00] terminal — secours : sauvegarde puis restauration (DIR=backup)
  gestes :
  - sql_select sinistres → file archives/, nom horodaté
  - batching 500 + archive lines + compress gzip
  - ls -lh archives/ : 4 fichiers
  - restauration : file archives/*.gz + scanner decompress → stdout
  idée : flux → lots → flux, même outil
  → "et si ça ne va pas ?"
-->

<!-- end_slide -->

# Pas une boîte noire

<!-- pause -->

**On peut l'observer.**

Métriques, traces, profils pprof.

<!-- pause -->

**On peut l'étendre.**

Son propre processeur, en Go.

<!-- pause -->

**On voit ce qui se passe.**

CPU, mémoire : rien de caché.

<!-- speaker_note: |
  [12:00 → 13:20] ton : confiant, rassurant
  - observer : /metrics (Prometheus), /ping, /ready
  - pprof : http → debug_endpoints → on regarde CPU / mémoire
  geste : relancer un pipeline avec debug_endpoints, puis
  go tool pprof http://localhost:4195/debug/pprof/heap (ou /profile)
  - étendre : Bento = bibliothèque Go → public/service,
  enregistrer son processeur, compiler son binaire
  - (honnête) tout ça : à vérifier dans la doc avant le talk
  → "bilan"
-->

<!-- end_slide -->

# Ce qu'on vient d'écrire

```bash +exec
wc -l pipelines/*.yaml
```

```bash +exec
make stats
```

<!-- pause -->

**Quatre cas.** Quelques lignes de YAML chacun.

<!-- pause -->

Pas de programme à maintenir. Pas de cluster à exploiter.

<!-- speaker_note: |
  [13:20 → 14:15] Ctrl+E ×2
  - wc -l pipelines : ce qu'on a écrit
  - make stats : le résultat, à l'écran
  - (honnête) pas la réponse à tout : logique métier complexe, gros volume avec état
  - plomberie du quotidien : très bon choix
  → "questions"
-->

<!-- end_slide -->

<!-- alignment: center -->

# Questions ?

<!-- pause -->

## Merci !

Docs : https://warpstreamlabs.github.io/bento

GitHub : warpstreamlabs/bento

<!-- speaker_note: |
  [14:15 → 15:00] ton : souriant
  - merci
  - rejouer : make up + un binaire
  - MIT, contributions bienvenues
  - (ouvert) questions
-->
