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
