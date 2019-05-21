Note import données cadastre dans PostgreSQL
============================================

NB : tout est à peu près à mettre à la beine et à remplacer par 

<https://github.com/etalab/DVF-app/tree/master/db>




Initialisation 
--------------

### Téléchargement des données

```bash
wget --recursive --no-parent -e robots=off https://cadastre.data.gouv.fr/data/hackathon-dgfip-dvf/
```

### Création de la base

On crée la base PG

```bash
sudo -u postgres dropdb cadastre
sudo -u postgres createdb cadastre -O romulus
```


Ensuite, on génère un schéma pour PG avec `csvsql`. Il faut pas mal de lignes pour éviter que `csvsql` ne prenne type trop restrictif. Voir par exemple <https://stackoverflow.com/questions/35243432/how-to-generate-a-schema-from-a-csv-for-a-postgresql-copy>

```bash
zcat valeursfoncieres-2018.txt.gz | head -n 50000 > sample.txt
time csvsql sample.txt --tables valeursfoncieres > schema.sql
# 14 secondes
psql -d cadastre -c "drop table if exists valeursfoncieres;"
psql -d cadastre -f schema.sql
```

Test sur un volume limité
-------------------------

```bash
csvsql -d '|' --db 'postgresql://romulus:MdPpostgres0@localhost:5432/cadastre' --no-create --insert --tables valeursfoncieres sample.txt
psql cadastre -c "SELECT COUNT(*) FROM valeursfoncieres;"
psql -d cadastre -c "delete from valeursfoncieres;"
```

Déja, c'est assez long pour 50.000. Si on essaie plus gros, c'est la panade pour `csvsql` (stop après 10' et 5.3 GB de ram)

Passage à l'échelle : l'intégralité des données
-----------------------------------------------

Déjà, on remplace les virgules par des points et on décompresse au passage. Le `sed 's/,/\./g'` est un peu violent mais beaucoup plus rapide.

```bash 
zcat valeursfoncieres-2018.txt.gz | sed 's/\([[:digit:]]\+\),\([[:digit:]]\)\+/\1.\2/g'  > valeursfoncieres-2018.csv
# Sans ça, lors de l'import
#ERROR:  invalid input syntax for type numeric: "109000,00"
#CONTEXT:  COPY valeursfoncieres, line 2, column Valeur fonciere: "109000,00"
```

Là, on va se prendre une tripotée d'erreurs succéssives lors de la l'import CSV

```bash
time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2018.csv' DELIMITER '|' CSV HEADER;"
```

Donc on va lancer psql et faire la maj des types de colonnes trop restrictives.


```bash
psql -d cadastre
```

```sql
ALTER TABLE valeursfoncieres ALTER COLUMN "1er lot" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "2eme lot" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "3eme lot" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "4eme lot" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "5eme lot" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "Voie" TYPE VARCHAR(255);
ALTER TABLE valeursfoncieres ALTER COLUMN "Commune" TYPE VARCHAR(255);
ALTER TABLE valeursfoncieres ALTER COLUMN "Code departement" TYPE VARCHAR(3);
ALTER TABLE valeursfoncieres ALTER COLUMN "No Volume" TYPE VARCHAR(16);
ALTER TABLE valeursfoncieres ALTER COLUMN "Commune" DROP NOT NULL;

-- On aura peut être besoin d'autre modifs si le sample pour csvsql est trop petit, comme suit
ALTER TABLE valeursfoncieres ALTER COLUMN "No Volume" TYPE DECIMAL USING ("No Volume"::int::numeric);
```

On est prêts

```bash
time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2018.csv' DELIMITER '|' CSV HEADER;"
# COPY 2339002
# 
# real	0m9,798s
# user	0m0,491s
# sys	0m0,180s
```

La suite

```bash

time zcat valeursfoncieres-2017.txt.gz | sed 's/\([[:digit:]]\+\),\([[:digit:]]\)\+/\1.\2/g'  > valeursfoncieres-2017.csv
time zcat valeursfoncieres-2016.txt.gz | sed 's/\([[:digit:]]\+\),\([[:digit:]]\)\+/\1.\2/g'  > valeursfoncieres-2016.csv
time zcat valeursfoncieres-2015.txt.gz | sed 's/\([[:digit:]]\+\),\([[:digit:]]\)\+/\1.\2/g'  > valeursfoncieres-2015.csv
time zcat valeursfoncieres-2014.txt.gz | sed 's/\([[:digit:]]\+\),\([[:digit:]]\)\+/\1.\2/g'  > valeursfoncieres-2014.csv

time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2017.csv' DELIMITER '|' CSV HEADER;"
# COPY 3361073
# real	0m15,950s
time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2016.csv' DELIMITER '|' CSV HEADER;"
# COPY 2936524
# real	0m15,241s
time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2015.csv' DELIMITER '|' CSV HEADER;"
# COPY 2749830
# real	0m13,608s
time psql -d cadastre -c "\copy valeursfoncieres FROM './valeursfoncieres-2014.csv' DELIMITER '|' CSV HEADER;"
# COPY 2516688
# real	0m13,031s

# environ 30s pour sed et 15sec pour copy sur ma machine
# au total 67.8 sec
# soit ~200.000 tuples par secondes pour \copy (sans sed)
```

Dans psql, on teste, avec bien sûr un gros `VACUUM`.

```sql
\timing
SELECT COUNT (*) FROM valeursfoncieres ;
-- count   
-- ----------
-- 13903117
-- (1 row)
-- Time: 2220,895 ms (00:02,221)

VACUUM FULL VERBOSE ANALYZE valeursfoncieres ;
-- INFO:  vacuuming "public.valeursfoncieres"
-- INFO:  "valeursfoncieres": found 0 removable, 13903117 nonremovable row versions in 262649 pages
-- DETAIL:  0 dead row versions cannot be removed yet.
-- CPU: user: 10.98 s, system: 3.26 s, elapsed: 35.20 s.
-- INFO:  analyzing "public.valeursfoncieres"
-- INFO:  "valeursfoncieres": scanned 30000 of 262649 pages, containing 1587918 live rows and 0 dead rows; 30000 rows in sample, 13902169 estimated total rows
-- VACUUM
-- Time: 37981,005 ms (00:37,981)
```

```sql
SELECT DISTINCT "Nature mutation" FROM valeursfoncieres ;

SELECT COUNT(*) FROM valeursfoncieres WHERE "Nature mutation" = 'Vente' ;

SELECT DISTINCT "Commune"
FROM valeursfoncieres
WHERE "Code departement" = '69'
FETCH FIRST 100 ROWS ONLY ;


SELECT EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) as annee,
        "Valeur fonciere",
        "Commune",
        "Code departement",
        "Type local",
        "Surface reelle bati",
        ("Valeur fonciere"/"Surface reelle bati") as prix_m2
FROM valeursfoncieres
WHERE "Code departement" = '69'
        AND "Nature mutation" = 'Vente'
        AND "Surface reelle bati" > 30
        AND "Type local" IN ('Maison', 'Appartement')
        AND "Valeur fonciere" BETWEEN 0 AND 1000000
        AND "Commune" = 'LYON 2EME'
ORDER BY prix_m2 DESC
LIMIT 100;

SELECT  "Commune",
        AVG("Valeur fonciere"/"Surface reelle bati") FILTER ( WHERE EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) = 2014) as m2_moyen_2014,
        AVG("Valeur fonciere"/"Surface reelle bati") FILTER ( WHERE EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) = 2015) as m2_moyen_2015,
        AVG("Valeur fonciere"/"Surface reelle bati") FILTER ( WHERE EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) = 2016) as m2_moyen_2016,
        AVG("Valeur fonciere"/"Surface reelle bati") FILTER ( WHERE EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) = 2017) as m2_moyen_2017,
        AVG("Valeur fonciere"/"Surface reelle bati") FILTER ( WHERE EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) = 2018) as m2_moyen_2018        
FROM valeursfoncieres
WHERE 
        "Nature mutation" = 'Vente'
        AND "Surface reelle bati" > 30
        AND "Type local" IN ('Maison', 'Appartement')
        AND "Valeur fonciere" BETWEEN 0 AND 1000000
--        AND "Commune" = 'LYON 2EME'
--        AND "Code departement" = '69'
GROUP BY "Commune"
ORDER BY "Commune" ASC;

```


Jouons avec les index
---------------------

Requête de référence

```sql
SELECT  "Code commune",
         EXTRACT(YEAR FROM to_date("Date mutation", 'DD/MM/YYYY')) as annee,
         AVG("Valeur fonciere"/"Surface reelle bati") as prix
FROM valeursfoncieres
WHERE 
        "Nature mutation" = 'Vente'
        AND "Surface reelle bati" > 30
        AND "Type local" IN ('Maison', 'Appartement')
        AND "Valeur fonciere" BETWEEN 0 AND 1000000
GROUP BY "Code commune", annee
ORDER BY "Code commune", annee
```

Environ 7-8 secondes.


```sql
ALTER TABLE valeursfoncieres ADD COLUMN "Date mutation2" date;

UPDATE valeursfoncieres SET "Date mutation2" = to_date("Date mutation", 'DD/MM/YYYY');
-- UPDATE 13903117
-- Query returned successfully in 1 min 25 secs.

CREATE INDEX commune_annee_idx ON valeursfoncieres ("Code commune", "Date mutation2");
-- CREATE INDEX
-- Query returned successfully in 48 secs 573 msec.

```

Avec les données d'etatlab
--------------------------

Des données nettoyées (dates et nombres au format iso, attributs normalisés) et enrichies (avec index, *latitude et longitude*, changement de code commune).

On va changer de base de données, ici on suppose que `gis` est créee. On va aussi copier un des fichiers de dpt.

```bash
time csvsql 69.csv.gz --tables etalab > schema_etalab.sql
# 14 secondes
psql -d gis -c "CREATE SCHEMA IF NOT EXISTS cadastre;"
psql -d gis -c "ALTER DATABASE gis SET search_path TO cadastre, grand_lyon, data_gouv, osm, parcoursup, pgr, elections, public;"
# cadastre est le premier, donc utilisé par défaut si pas précisé
psql -d gis -c "DROP TABLE IF EXISTS cadastre.etalab;"
psql -d gis -f schema_etalab.sql
```

On test l'import

```bash
time psql -d gis -c "\copy etalab FROM program 'zcat 69.csv.gz' DELIMITER ',' CSV HEADER;"
```



```sql
ALTER TABLE etalab ALTER COLUMN "id_mutation" TYPE VARCHAR(12);

ALTER TABLE etalab ALTER COLUMN "lot1_numero" TYPE VARCHAR(8);
ALTER TABLE etalab ALTER COLUMN "lot2_numero" TYPE VARCHAR(8);
ALTER TABLE etalab ALTER COLUMN "lot3_numero" TYPE VARCHAR(8);
ALTER TABLE etalab ALTER COLUMN "lot4_numero" TYPE VARCHAR(8);
ALTER TABLE etalab ALTER COLUMN "lot5_numero" TYPE VARCHAR(8);

ALTER TABLE etalab ALTER COLUMN "nom_commune" TYPE VARCHAR(64);
ALTER TABLE etalab ALTER COLUMN "ancien_nom_commune" TYPE VARCHAR(64);
ALTER TABLE etalab ALTER COLUMN "code_commune" TYPE VARCHAR(8);
ALTER TABLE etalab ALTER COLUMN "ancien_code_commune" TYPE VARCHAR(8);

ALTER TABLE etalab ALTER COLUMN "numero_volume" TYPE VARCHAR(8);

ALTER TABLE etalab ALTER COLUMN "code_departement" TYPE VARCHAR(3);

ALTER TABLE etalab ALTER COLUMN "adresse_nom_voie" TYPE VARCHAR(64);
ALTER TABLE etalab ALTER COLUMN "ancien_id_parcelle" TYPE VARCHAR(14);
```


Et on y va avec le script

```bash
#!/bin/bash

BASE="./contrib/etalab-csv/"
OIFS="$IFS"
IFS=$'\n'

# echo Base folder $BASE

for year in  `find $BASE  -maxdepth 1 ! -path $BASE  -type d `
do
  # echo Year folder "$year"
  ls -al $year/full.csv.gz
  time psql -d gis -c "\copy etalab FROM program 'zcat $year/full.csv.gz' DELIMITER ',' CSV HEADER;"
done
IFS="$OIFS"
```
Et on y va

```
-rw-r--r-- 1 romulus romulus 77832978 mai    7 17:43 ./contrib/etalab-csv/2015/full.csv.gz
COPY 2749830

real	0m16,698s
user	0m3,524s
sys	0m0,579s
-rw-r--r-- 1 romulus romulus 66464368 mai    7 15:26 ./contrib/etalab-csv/2018/full.csv.gz
COPY 2339002

real	0m13,713s
user	0m3,087s
sys	0m0,487s
-rw-r--r-- 1 romulus romulus 83195688 mai    7 16:59 ./contrib/etalab-csv/2016/full.csv.gz
COPY 2936524

real	0m17,643s
user	0m3,931s
sys	0m0,650s
-rw-r--r-- 1 romulus romulus 71732630 mai    7 18:27 ./contrib/etalab-csv/2014/full.csv.gz
COPY 2516688

real	0m16,176s
user	0m3,405s
sys	0m0,655s
-rw-r--r-- 1 romulus romulus 94128331 mai    7 16:13 ./contrib/etalab-csv/2017/full.csv.gz
COPY 3361073

real	0m20,651s
user	0m4,477s
sys	0m0,903s
```

On a autant de données qu'avant, mais c'est un peu plus gros...
```
-- Schema |       Name       | Type  |  Owner  |  Size   | Description 
-- --------+------------------+-------+---------+---------+-------------
--  public | etalab           | table | romulus | 3345 MB | 
--  public | valeursfoncieres | table | romulus | 2052 MB | 
```

```sql
select count(*) from etalab;
--   count   
-- ----------
--  13903117
-- (1 row)

VACUUM FULL VERBOSE ANALYZE etalab ;
-- INFO:  vacuuming "cadastre.etalab"
-- INFO:  "etalab": found 0 removable, 13903117 nonremovable row versions in 328805 pages
-- DETAIL:  0 dead row versions cannot be removed yet.
-- CPU: user: 12.74 s, system: 4.87 s, elapsed: 43.97 s.
-- INFO:  analyzing "cadastre.etalab"
-- INFO:  "etalab": scanned 30000 of 328805 pages, containing 1268674 live rows and 0 dead rows; 30000 rows in sample, 13904878 estimated total rows

```

On va ajouter les extensions géographique de PostGIS

```bash
sudo -u postgres psql -d cadastre -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```


```sql
-- exemple pour voir
SELECT ST_PointFromText('POINT(' || longitude || ' ' || latitude ||')', 4326)
FROM etalab TABLESAMPLE BERNOULLI (1)
LIMIT 10;

\timing

ALTER TABLE etalab ADD COLUMN geom geometry;
UPDATE etalab SET geom = ST_PointFromText('POINT(' || longitude || ' ' || latitude ||')', 4326) WHERE longitude IS NOT NULL AND latitude IS NOT NULL ;
-- UPDATE 13374336
-- Time: 209007,235 ms (03:29,007)

CREATE INDEX etalab_geom_idx ON etalab USING GIST (geom);
-- CREATE INDEX
-- Time: 243066,451 ms (04:03,066)
CREATE INDEX etalab_code_commune_idx ON etalab (code_commune);
-- CREATE INDEX
-- Time: 30419,072 ms (00:30,419)

-- Pas d'index !
EXPLAIN SELECT *
FROM etalab
WHERE EXTRACT(YEAR FROM date_mutation) = 2014
      AND geom IS NOT NULL
      AND nature_mutation = 'Vente'
      AND type_local IN ('Maison', 'Appartement')
      AND st_DistanceSphere(geom, ST_PointFromText('POINT(4.824879 45.745267)', 4326)) < 1000;

-- INDEX !
EXPLAIN SELECT *
FROM etalab 
WHERE ST_DWithin(geom, ST_PointFromText('POINT(4.824879 45.745267)', 4326), 0.01)
      AND EXTRACT(YEAR FROM date_mutation) = 2014
      AND nature_mutation = 'Vente'
      AND type_local IN ('Maison', 'Appartement')
      AND st_DistanceSphere(geom, ST_PointFromText('POINT(4.824879 45.745267)', 4326)) < 1000;



SELECT qua.nom,
        qua.wkb_geometry,
        EXTRACT(YEAR FROM cad.date_mutation)  as annee,
        count(id_mutation),
        count(distinct id_mutation),
        AVG(cad.valeur_fonciere/cad.surface_reelle_bati),
        array_agg(cad.valeur_fonciere)
FROM  grand_lyon.quartier qua  JOIN cadastre.etalab cad ON ST_Intersects(qua.wkb_geometry, cad.geom)
WHERE nature_mutation = 'Vente'
      AND type_local IN ('Maison', 'Appartement')
      AND cad.valeur_fonciere BETWEEN 10000 AND 10000000
      AND cad.surface_reelle_bati IS NOT NULL
GROUP BY qua.ogc_fid, annee;

```
