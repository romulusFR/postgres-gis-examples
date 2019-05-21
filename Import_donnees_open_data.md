---
header-includes:
    <meta name="keywords" content="PostgreSQL, PostGIS, Grand Lyon, Open Data, Open Street Map"/>
    <meta name="description" content="Documentation l'import de jeux de données dans PostegreSQL avec les extensions PostGIS." />
    <meta charset="UTF-8">
lang:
    fr
pagetitle:
    Imports de données open data dans PostgreSQL
author:
    Romuald THION
---

Imports de données open data dans PostgreSQL
============================================

Ce document décrit comment importer un ensemble de données public de l'open data dans une base PostgreSQL que l'on suppose installée et configurée sur `localhost`.

Installations PostgreSQL et extensions
--------------------------------------

### PostgreSQL

* <https://www.postgresql.org/download/linux/ubuntu/>
* <https://www.postgresql.org/docs/current/>

PostGIS

* <https://postgis.net/docs/>
* <https://postgis.net/docs/reference.html>

pgRouting

* <http://pgrouting.org/>
* <http://docs.pgrouting.org/latest/en/index.html>
* Pour un tuto <https://workshop.pgrouting.org/2.5/en/index.html>

### Base de données et extensions


```bash
sudo apt install postgresql-11-pgrouting
sudo apt install postgis

# avec le compte du dba
sudo -s -u postgres
psql -c "CREATE USER romulus with encrypted password 'pass'";
createdb gis -O romulus

psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis'
# psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis_topology'
psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS pgrouting'
psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS hstore'

# sudo service postgresql restart
```

### Schémas pour accueillir les données

```sql
-- avec le compte non privilégié
-- psql -U romulus -d gis
CREATE SCHEMA IF NOT EXISTS grand_lyon;
CREATE SCHEMA IF NOT EXISTS osm;
CREATE SCHEMA IF NOT EXISTS data_gouv;
CREATE SCHEMA IF NOT EXISTS parcoursup;
CREATE SCHEMA IF NOT EXISTS elections;
CREATE SCHEMA IF NOT EXISTS cadastre;

-- chemins de recherche dans les schemas
ALTER DATABASE gis SET search_path TO "$user", grand_lyon, osm, data_gouv, parcoursup, elections, cadastre, public;
```

### Résultats du setup et test

```sql
select extname, extversion 
from pg_extension ;
--   extname  | extversion 
-- -----------+------------
--  plpgsql   | 1.0
--  postgis   | 2.5.2
--  pgrouting | 2.6.2
--  hstore    | 1.5
--  unaccent  | 1.1
```

```bash
> qgis --help
QGIS - 3.6.2-Noosa 'Noosa' (656500e)

> ogr2ogr --version
GDAL 2.2.3, released 2017/11/20

> psql -d gis -c "SELECT version();"
PostgreSQL 11.2 (Ubuntu 11.2-1.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.3.0-27ubuntu1~18.04) 7.3.0, 64-bit

> psql -d gis -c "SELECT PostGIS_full_version();"
POSTGIS="2.5.2 r17328" [EXTENSION] PGSQL="110" GEOS="3.6.2-CAPI-1.10.2 4d2925d6" PROJ="Rel. 4.9.3, 15 August 2016" GDAL="GDAL 2.2.3, released 2017/11/20" LIBXML="2.9.4" LIBJSON="0.12.1" LIBPROTOBUF="1.2.1" RASTER

> psql -d gis -c "SELECT pgr_version();"
(2.6.2,v2.6.2,b14f4d56b,master,1.65.1)
```



Un petit test sur la table postGIS : les coordonnées epsg4326, <http://spatialreference.org/ref/epsg/4326/>, voir <https://postgis.net/workshops/postgis-intro/projection.html> pour le spheroid associé

```sql
SELECT * FROM spatial_ref_sys WHERE srid = 4326;

-- GEOGCS["WGS 84",
--   DATUM["WGS_1984",
--     SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],
--     AUTHORITY["EPSG","6326"]],
--   PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],
--   UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],
--   AUTHORITY["EPSG","4326"]]
```


Datasets Grand Lyon
-------------------

"FUV" = Fichier Unique des Voies, voir <https://www.data.gouv.fr/fr/datasets/denomination-des-voies-de-la-metropole-de-lyon/>. 
Page générale <https://data.grandlyon.com/search/?Q=Lieux+et+points+d%27int%C3%A9r%C3%AAt+de+la+M%C3%A9tropole+de+Lyon> ou [ici pour lafiche détaillée](https://download.data.grandlyon.com/catalogue/srv/fre/catalog.search#/metadata/32b2024e-1bba-44e2-8eab-6b4fa6f361da)

Liste des datasets d'intérêt

* Noeuds de la trame viaire <https://data.grandlyon.com/localisation/noeuds-de-la-trame-viaire-de-la-mftropole-de-lyon/>
* Troncons de la trame viaire <https://data.grandlyon.com/localisation/tronfons-de-la-trame-viaire-de-la-mftropole-de-lyon/>. Voir plus loin avec <https://data.grandlyon.com/localisation/dfnomination-des-voies-de-la-mftropole-de-lyon/> et <https://data.grandlyon.com/localisation/table-des-noeuds-et-des-tronfons-de-voies-y-aboutissant-de-la-mftropole-de-lyon/>
* Quartiers <https://data.grandlyon.com/citoyennete/quartiers-des-communes-de-la-mftropole-de-lyon/>
* Adresses <https://data.grandlyon.com/localisation/points-de-dfbouchf-dune-adresse-de-la-mftropole-de-lyon/>

* Points d'intérêt touristiques <https://data.grandlyon.com/culture/points-dintfrft-touristiques-de-la-mftropole-de-lyon/>

* Réseau metro et funi <https://data.grandlyon.com/equipements/lignes-de-mftro-et-funiculaire-du-rfseau-transports-en-commun-lyonnais/>
* Réseau bus <https://data.grandlyon.com/equipements/lignes-de-bus-du-rfseau-transports-en-commun-lyonnais/>
* Réseau tram <https://data.grandlyon.com/equipements/lignes-de-tramway-du-rfseau-transports-en-commun-lyonnais/>


### Download

```bash
curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adrcarrefour&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_carrefour.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adraxevoie&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_troncon.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adrquartier&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_quartier.json

curl "https://download.data.grandlyon.com/wfs/rdata?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=sit_sitra.sittourisme&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_tourisme.json

curl "https://download.data.grandlyon.com/wfs/rdata?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=tcl_sytral.tcllignemf&SRSNAME=urn:ogc:def:crs:EPSG::4326"> data_metro_funi.json

curl "https://download.data.grandlyon.com/wfs/rdata?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=30000&request=GetFeature&typename=tcl_sytral.tcllignebus&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_bus.json

curl "https://download.data.grandlyon.com/wfs/rdata?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=tcl_sytral.tcllignetram&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_tram.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=adr_voie_lieu.adrdebouche&SRSNAME=urn:ogc:def:crs:EPSG::4326" > data_adresse.json
```

### Import et test

```bash
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "data_carrefour.json" -nln grand_lyon.carrefour
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "data_troncon.json" -nln grand_lyon.troncon
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "data_tourisme.json" -nln grand_lyon.tourisme
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "data_quartier.json" -nln grand_lyon.quartier
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "data_adresse.json" -nln grand_lyon.adresse

```

```bash
psql -d gis -c "SELECT COUNT(*) FROM troncon"
psql -d gis -c "SELECT COUNT(*) FROM tourisme"
psql -d gis -c "SELECT COUNT(*) FROM carrefour"
psql -d gis -c "SELECT COUNT(*) FROM quartier"
psql -d gis -c "SELECT COUNT(*) FROM adresse"
# 37593 troncons, 5280 POI touristiques, 26547 noeuds, 203 quartiers et 156919 adresse
```


Attention, le code troncon n'est pas un identifiant global sur la métropole, ni même sur une commune !

```sql
SELECT t1.codetroncon, count (*), array_agg(t1.ogc_fid), array_agg(t1.nomcommune) 
FROM troncon t1 JOIN troncon t2 on t1.codetroncon = t2.codetroncon
WHERE t1.ogc_fid <> t2.ogc_fid
GROUP BY t1.codetroncon
HAVING count(*) > 1 AND count(distinct t1.nomcommune) = 1;
```

Sur les troncons, on vérifie qu'ils sont bien "atomiques"

```sql
SELECT ST_NumPoints(wkb_geometry) as np, ST_NumGeometries(wkb_geometry) as n, wkb_geometry
FROM troncon
ORDER BY ST_NumGeometries(wkb_geometry) DESC;
```



Datasets data.gouv.fr
---------------------

### Extractions OSM

* <https://www.data.gouv.fr/fr/datasets/contours-des-regions-francaises-sur-openstreetmap/>
* <https://www.data.gouv.fr/fr/datasets/contours-des-departements-francais-issus-d-openstreetmap/>
* <https://www.data.gouv.fr/fr/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/>
* Exports <http://osm13.openstreetmap.fr/%7Ecquest/openfla/export/>

#### Import des fichiers au format shapefile

```bash
# en accédant dirtectement au zip 
# https://www.gdal.org/gdal_virtual_file_systems.html#gdal_virtual_file_systems_drivers
ogrinfo /vsizip/departements-20190101-shp.zip/departements-20190101.shp  -ro

ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" -progress -nlt PROMOTE_TO_MULTI -nln data_gouv.departements /vsizip/departements-20190101-shp.zip/departements-20190101.shp

ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" -progress -nlt PROMOTE_TO_MULTI -nln data_gouv.regions /vsizip/regions-20190101-shp.zip/regions-20190101.shp

ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" -progress -nlt PROMOTE_TO_MULTI -nln data_gouv.communes /vsizip/communes-20190101-shp.zip/communes-20190101.shp
```


```bash
psql -d gis -c "SELECT COUNT(*) FROM departements"
psql -d gis -c "SELECT COUNT(*) FROM regions"
psql -d gis -c "SELECT COUNT(*) FROM communes"
# 102, 18 et 34970
```

#### Un test sur lyon

On doit trouver 59 communes <https://www.grandlyon.com/metropole/59-communes.html>. La relation `ST_Within` utilise les index : <https://postgis.net/docs/ST_Within.html>

```sql
SELECT co.* 
FROM  departements de 
      INNER JOIN communes co
        ON ST_Within(co.wkb_geometry, de.wkb_geometry)
WHERE de.code_insee ~ '69M' ;
```


### Résultats électoraux

* Législatives 2017, 1er tour <https://public.opendatasoft.com/explore/dataset/elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-1/table/?disjunctive.libelle_de_la_commune>

```bash
ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" "elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-1-69.geojson" -nln elections.legislatives_1
```

### Dataset parcoursp

Script python pour transformation, repris de <https://gis.stackexchange.com/questions/73756/is-it-possible-to-convert-regular-json-to-geojson>

```bash
curl "https://carte.parcoursup.fr/data/psupdata.1.1.0.zip"

./json2geojson psupdata.1.1.0.json psupdata.1.1.0.geojson

ogr2ogr -f "PostgreSQL" PG:"dbname=gis user=romulus" psupdata.1.1.0.geojson -nln parcoursup.psupdata
```


Données OpenStreetMap
---------------------

### Import des données

* Généralités <https://www.openstreetmap.fr/donnees/>
* Extraction Région Rhône-Alpes <https://download.openstreetmap.fr/extracts/europe/france/rhone_alpes/>
* Outil de chargement <https://wiki.openstreetmap.org/wiki/Osmosis>
* Install Osmosis <https://wiki.openstreetmap.org/wiki/Osmosis/PostGIS_Setup>
* Schema de BD <https://wiki.openstreetmap.org/wiki/Databases_and_data_access_APIs#Database_Schemas> et le schema pgsnaphsot pour osmosis <https://wiki.openstreetmap.org/wiki/Osmosis/pgsnapshot>

Autres outils

* avec un autre schema, <https://github.com/openstreetmap/osm2pgsql>
* pour traiter les .osm <https://wiki.openstreetmap.org/wiki/Osmconvert>


```bash
sudo apt install osmosis
# sudo apt install osmctools
# sudo apt install osm2pgsql

curl https://download.openstreetmap.fr/extracts/europe/france/rhone_alpes/rhone.state.txt > rhone.state.txt

curl https://download.openstreetmap.fr/extracts/europe/france/rhone_alpes/rhone-latest.osm.pbf --output rhone-latest.osm.pbf

# temporairement, pour éviter la string "dbname=gis options=--search_path=osm"
psql -d gis -c "ALTER DATABASE gis SET search_path TO osm, public;"

# on crée les schemas voir /usr/share/doc/osmosis/examples/
psql -d gis -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
psql -d gis -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_action.sql
psql -d gis -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_bbox.sql
psql -d gis -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql

osmosis --read-pbf rhone-latest.osm.pbf --log-progress --write-pgsql database=gis  user="romulus" password="pass"
# INFO: Total execution time: 464762 milliseconds.

psql -d gis -c "ALTER DATABASE gis SET search_path TO grand_lyon, data_gouv, osm, parcoursup, pgr, public;"
```

```sql
-- index pour les hstore
-- https://www.postgresql.org/docs/current/hstore.html#id-1.11.7.25.6
CREATE INDEX relations_tags_idx ON relations USING GIN(tags);
CREATE INDEX nodes_tags_idx ON nodes USING GIN(tags);
CREATE INDEX ways_tags_idx ON ways USING GIN(tags);

explain select *, tags->'name', tags ->'admin_level'
from relations
where tags ?& ARRAY['boundary', 'type', 'admin_level'] AND tags->'name' ~ 'Lyon' ;
```

### Pour éditer

<https://josm.openstreetmap.de/>

Extraction du sous-ensemble sur la bouding box de Lyon


```bash
osmconvert -b=4.7718134,45.7073666,4.8983774,45.808262  rhone-latest.osm.pbf --out-pbf > lyon.osm.pbf
```

### Tests

```sql
-- Limites administratives de Lyon

select *, tags->'name', tags ->'admin_level'
from relations
where tags->'boundary' = 'administrative' AND  tags->'type' = 'boundary' and tags->'name' ~ 'Lyon' ;

select relations.id, ST_Linemerge(ST_Union(array_agg(linestring)))
from relations JOIN relation_members ON relations.id = relation_members.relation_id
JOIN ways ON relation_members.member_id = ways.id
where relations.tags ?& ARRAY['boundary', 'type', 'admin_level']
group by relations.id;
```

Données de valeurs foncières
----------------------------

* Description whttps://cadastre.data.gouv.fr/dvf>
* L'application <https://app.dvf.etalab.gouv.fr/>
* Ses sources <https://github.com/etalab/DVF-app/tree/master/db>
* Les data <https://cadastre.data.gouv.fr/data/hackathon-dgfip-dvf/>
* 

Pour tout prendre, avec les fichiers par département et par commune, en plus des gros ensembles. Attention à bien prendre les données nétoyyées par <https://www.data.gouv.fr/en/organizations/etalab/>.

```bash
wget --recursive --no-parent -e robots=off https://cadastre.data.gouv.fr/data/hackathon-dgfip-dvf/contrib/etalab-csv/
```

Le plus simple étant de regarder la source du projet qui fait déjà un import dans Postgres et de l'adapter.

* Pour le schéma des données, voir [./cadastre_dvf_schema.sql](`cadastre_dvf_schema.sql`), où on renomme juste [https://raw.githubusercontent.com/etalab/DVF-app/master/db/create_table.sql](la définition de base de la table)
* Pour [le script d'import](https://raw.githubusercontent.com/etalab/DVF-app/master/db/build_db.sh), on l'adapte légèrement. On va éviter la décompression et la création de la base qui a déja été faite., voir [./cadastre_dvf_build_db.sh](cadastre_dvf_build_db.sh)
* Enfin, on [change un peu l'alter table de base](https://raw.githubusercontent.com/etalab/DVF-app/master/db/alter_table.sql), voir [./cadastre_dvf_alter_table.sql](`cadastre_dvf_alter_table.sql`), notamment pour y mettre une colonne Postgis et un index géographique dessus.



```bash
psql -d gis -f "cadastre_dvf_schema.sql"
./cadastre_dvf_build_db.sh

# Running import from .
# -rw-r--r-- 1 romulus romulus 71732630 mai    7 18:27 data/full_2014.csv.gz
# COPY 2516688

# real	0m13,513s
# user	0m3,327s
# sys	0m0,449s
# -rw-r--r-- 1 romulus romulus 77832978 mai    7 17:43 data/full_2015.csv.gz
# COPY 2749830

# real	0m15,286s
# user	0m3,576s
# sys	0m0,581s
# -rw-r--r-- 1 romulus romulus 83195688 mai    7 16:59 data/full_2016.csv.gz
# COPY 2936524

# real	0m17,871s
# user	0m3,846s
# sys	0m0,719s
# -rw-r--r-- 1 romulus romulus 94128331 mai    7 16:13 data/full_2017.csv.gz
# COPY 3361073

# real	0m19,133s
# user	0m4,482s
# sys	0m0,684s
# -rw-r--r-- 1 romulus romulus 66464368 mai    7 15:26 data/full_2018.csv.gz
# COPY 2339002

# real	0m13,425s
# user	0m3,093s
# sys	0m0,608s
```

Dans `psql`


```sql
\dt+ dvf
--                      List of relations
--   Schema  | Name | Type  |  Owner  |  Size   | Description 
-- ----------+------+-------+---------+---------+-------------
--  cadastre | dvf  | table | romulus | 2567 MB | 

select count(*) from dvf;
--   count   
-- ----------
--  13903117
-- (1 row)

-- Time: 11453,394 ms (00:11,453)
```

Puis l'alter table

```bash
psql -d gis -f "cadastre_dvf_alter_table.sql"
```

C'est quand même long et ça fait doubler temporairement la taille de la BD.
Mettre bien les UPDATEs avant les index pour éviter de les mettre à jour inutilement.


```sql
SELECT
    pg_size_pretty (
        pg_total_relation_size ('dvf')
    ),
    pg_size_pretty (
        pg_indexes_size ('dvf')
    ),
    pg_size_pretty (
        pg_relation_size ('dvf')
    )
;

--  pg_size_pretty | pg_size_pretty | pg_size_pretty 
-- ----------------+----------------+----------------
--  5951 MB        | 2912 MB        | 3038 MB

```

Finalisation
------------

### VACUUM

Toujours, pour finir des imports, on utilise ici `FULL` pour réorganiser physiquement et `FREEZE` pour éviter les auto-vacuum (les données étant en fait en lecture seule moralement)

```sql
VACUUM FULL FREEZE VERBOSE ANALYZE;
```

### Liste des tables

```
gis=# \dt+
                            List of relations
   Schema   |       Name       | Type  |  Owner   |  Size   | Description 
------------+------------------+-------+----------+---------+-------------
 cadastre   | dvf              | table | romulus  | 2567 MB | 
 data_gouv  | communes         | table | romulus  | 332 MB  | 
 data_gouv  | departements     | table | romulus  | 30 MB   | 
 data_gouv  | regions          | table | romulus  | 16 MB   | 
 grand_lyon | adresse          | table | romulus  | 18 MB   | 
 grand_lyon | carrefour        | table | romulus  | 4472 kB | 
 grand_lyon | quartier         | table | romulus  | 768 kB  | 
 grand_lyon | tourisme         | table | romulus  | 2200 kB | 
 grand_lyon | troncon          | table | romulus  | 13 MB   | 
 osm        | actions          | table | romulus  | 0 bytes | 
 osm        | nodes            | table | romulus  | 645 MB  | 
 osm        | relation_members | table | romulus  | 21 MB   | 
 osm        | relations        | table | romulus  | 3048 kB | 
 osm        | schema_info      | table | romulus  | 40 kB   | 
 osm        | users            | table | romulus  | 168 kB  | 
 osm        | way_nodes        | table | romulus  | 409 MB  | 
 osm        | ways             | table | romulus  | 496 MB  | 
 parcoursup | psupdata         | table | romulus  | 5560 kB | 
 public     | spatial_ref_sys  | table | postgres | 4624 kB | 
(19 rows)
```


Misc
----

* Voir <https://abelvm.github.io/sql/contour/>

