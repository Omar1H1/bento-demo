CREATE TABLE clients (
    client_id integer PRIMARY KEY,
    nom       text NOT NULL,
    ville     text NOT NULL,
    segment   text NOT NULL
);

INSERT INTO clients (client_id, nom, ville, segment)
SELECT i,
       (ARRAY['Martin','Bernard','Dubois','Thomas','Robert','Richard','Petit','Durand','Leroy','Moreau','Simon','Laurent'])[1 + (i % 12)]
         || ' #' || i,
       (ARRAY['Niort','Paris','Lyon','Nantes','Bordeaux','Lille','Toulouse','Rennes'])[1 + (i % 8)],
       (ARRAY['particulier','particulier','particulier','professionnel','association'])[1 + (i % 5)]
FROM generate_series(1, 300) AS i;

CREATE TABLE sinistres (
    sinistre_id      text PRIMARY KEY,
    contrat_id       text NOT NULL,
    client_id        integer NOT NULL REFERENCES clients (client_id),
    type             text NOT NULL,
    montant          numeric(10,2) NOT NULL,
    date_declaration date NOT NULL,
    statut           text NOT NULL
);

COPY sinistres FROM '/docker-entrypoint-initdb.d/sinistres.csv' WITH (FORMAT csv, HEADER true);

CREATE VIEW stats_par_type AS
SELECT type,
       count(*)                AS nombre,
       round(avg(montant), 2)  AS montant_moyen,
       sum(montant)            AS montant_total
FROM sinistres
GROUP BY type;
