# Prêt pour la prod : tests, logs JSON, métriques, pprof

Un seul pipeline, `normalisation.yaml`. Il tourne sans Docker (entrée synthétique, un sinistre toutes les 500 ms).
Tout se lance depuis la racine du projet.

## 1. Les tests

```sh
make test
```

- `bento lint` valide la config, `bento test` rejoue `normalisation_test.yaml`.
- Deux cas : champs texte → types propres, et montant illisible → `valide: false` (le message n'est pas perdu).
- Pour montrer un test qui échoue : changer `AUTO` en `VOITURE` dans le test, relancer, remettre.

## 2. Lancer le pipeline

```sh
make prod
```

## 3. Dans un 2e terminal : l'observer

Logs JSON (ils sortent sur stderr) :

```sh
make prod 2>&1 | jq -c '{niveau: .level, msg, sinistre_id, valide}'
make prod 2>&1 | jq -c 'select(.valide == false)'   # seulement les montants illisibles
```

Santé et métriques :

```sh
curl -s localhost:4195/ping
curl -s localhost:4195/ready
curl -s localhost:4195/metrics | grep -E '^(input|processor|output)_' | head -20
```

pprof (`debug_endpoints: true`) :

```sh
curl -s localhost:4195/debug/pprof/ | head
go tool pprof -top 'http://localhost:4195/debug/pprof/profile?seconds=5'
go tool pprof -top http://localhost:4195/debug/pprof/heap
```

## 4. Le waouh : un flamegraph

```sh
make load      # terminal 1 : même pipeline, 1 ms entre deux messages
make flame     # terminal 2 : profil CPU de 10 s, ouvert dans le navigateur
```

Dans le navigateur : menu *View* → *Flame Graph*. On voit où Bento passe son temps.

Puis le coupable (avant / après) :

1. Dans `normalisation.yaml`, décommenter la ligne `root.empreinte = …` du mapping, relancer `make load`.
2. `make flame` : un gros bloc apparaît (hash / mapping).
3. Recommenter la ligne, relancer, relancer `make flame` : il a disparu.

Autres vues, en secours :

```sh
curl -s 'localhost:4195/debug/pprof/goroutine?debug=1' | head -40
go tool pprof -top http://localhost:4195/debug/pprof/heap
```

## À vérifier avant le talk (non exécuté lors de la rédaction)

- `make test` passe (syntaxe des conditions `json_equals`, `null` pour `montant`).
- Les noms exacts des champs de logs (`level`, `msg`) et des métriques.
- `${INTERVAL:500ms}` et `${MSG_LOG_LEVEL:INFO}` (variables d'environnement avec valeur par défaut), la fonction `range`/`map_each`/`hash` de la ligne d'empreinte, et la lisibilité des noms dans le flamegraph.
- Une seule instance sur le port 4195 à la fois.
