
Imports de données Grand lyon, électorale et démographique pour un exemple de diagnostic de terrain
===================================================================================================

Introduction
------------

### Versions

```
gdal-bin/bionic,now 2.4.2+dfsg-1~bionic0 amd64 [installed,automatic]
postgresql-11/bionic-pgdg,now 11.6-1.pgdg18.04+1 amd64 [installed]
qgis/bionic,now 3.4.11+dfsg-2~bionic1 amd64 [installed]
postgresql-11-postgis-3/bionic-pgdg,now 3.0.0+dfsg-2~exp1.pgdg18.04+1 amd64 [installed,automatic]
```

### Documentation


#### GDAL
 * <https://launchpad.net/~ubuntugis/+archive/ubuntu/ppa>
 * <https://launchpad.net/~ubuntugis/+archive/ubuntu/ubuntugis-unstable>

 * <https://gdal.org/>
 * <https://gdal.org/drivers/vector/pg.html#vector-pg>
 * <https://gdal.org/drivers/vector/pg_advanced.html#vector-pg-advanced>


### **Important !**

* BUG with PG 12 pour ogr2ogr GDAL ?
   - https://github.com/OSGeo/homebrew-osgeo4mac/issues/1291
   - https://gis.stackexchange.com/questions/342246/ogr2ogr-from-file-to-postgresql-12-table-fails
  
* ne PAS utiliser le "web service" grand lyon pour les données géo mais le WFS
* les URLs générées sont moisies en v beta




Database setup
--------------

Voir fichier [pg_create_db.sh](./pg_create_db.sh)

Pour tester la connection, changer les variables pour votre instance

```
psql -p 5433 -U gis -d gis -h localhost

gis@~=> \dn
  List of schemas
    Name    | Owner 
------------+-------
 election   | gis
 grand_lyon | gis
 insee      | gis
 postgis    | gis
(4 rows)

gis@~=> \dx postgis 
                                   List of installed extensions
  Name   | Version | Schema  |                             Description                             
---------+---------+---------+---------------------------------------------------------------------
 postgis | 3.0.0   | postgis | PostGIS geometry, geography, and raster spatial types and functions
(1 row)


```

Import des données
------------------

### Data grand lyon

<https://data.grandlyon.com/jeux-de-donnees/>


Voir fichiers [data_grand_lyon_download.sh](./data_grand_lyon_download.sh) et [data_grand_lyon_import.sh](data_grand_lyon_import.sh)

### Data data.gouv.fr : résultats électoraux

<https://public.opendatasoft.com/> (éviter <static.data.gouv.fr>)


Voir fichiers [data_election_download.sh](./data_election_download.sh) et [data_election_import.sh](data_election_import.sh). **Limité ici au département du Rhône.**


### Data INSEE : IRIS et démographie

* <https://www.insee.fr/fr/information/2383389>
* <https://www.insee.fr/fr/statistiques/4271564?sommaire=2500477#consulter>


Voir fichiers [data_insee_download.sh](./data_insee_download.sh) et [data_insee_import.sh](data_insee_import.sh) **Limité ici au département du Rhône.**



Analyse des données
-------------------

### Countour de bureaux de votes incorrects

Sur les 294 bureaux, 39 erreurs de géométrie.

```sql
select (ST_IsValidDetail(bdv.wkb_geometry )).reason,
       (ST_IsValidDetail(bdv.wkb_geometry)).location,
       ST_MakeValid(wkb_geometry),
       ST_IsValid(ST_MakeValid(wkb_geometry))
from bdv_countour bdv
where NOT ST_IsValid(bdv.wkb_geometry);
```

39 erreurs que l'on peut toutes corriger automatiquement (nfin, on va laisser PostGIS se débrouiller).

```sql
-- https://gis.stackexchange.com/questions/165151/postgis-update-multipolygon-with-st-makevalid-gives-error/165152
BEGIN;

ALTER TABLE bdv_countour ADD COLUMN wkb_multi_geometry geometry (multipolygon,4326);

UPDATE bdv_countour
SET wkb_multi_geometry =  st_multi(st_collectionextract(st_makevalid(wkb_geometry),3));

COMMIT;


select (ST_IsValidDetail(bdv.wkb_multi_geometry )).reason,
       (ST_IsValidDetail(bdv.wkb_multi_geometry)).location,
       ST_MakeValid(wkb_multi_geometry)
from bdv_countour bdv
where NOT ST_IsValid(bdv.wkb_multi_geometry);
```

### Calculer les overlap des iris/bdv

On va faire le produite cartésien des IRIS par les BdV et calculer les intersections 2 à 2.

```sql
CREATE OR REPLACE VIEW grand_lyon.iris_bdv AS (
  select i.code_iris AS code_iris,
         -- i.wkb_geometry AS iris_geom,
         bdv.num_bureau  AS num_bureau,
         -- bdv.wkb_multi_geometry AS bureau_geom,
         round(1000*ST_Area(ST_Intersection(i.wkb_geometry, bdv.wkb_multi_geometry))/ST_Area(i.wkb_geometry)) AS pm_iris,
         round(1000*ST_Area(ST_Intersection(i.wkb_geometry, bdv.wkb_multi_geometry))/ST_Area(bdv.wkb_multi_geometry)) AS pm_bdv,
         ST_Intersect(i.wkb_geometry, bdv.wkb_multi_geometry) AS geom
  from insee.iris i  INNER JOIN bdv_countour bdv 
       on st_intersects(i.wkb_geometry, bdv.wkb_multi_geometry)
);

-- pour tester, la somme à 1000

SELECT num_bureau, sum(pm_bdv)
FROM iris_bdv
GROUP BY num_bureau
ORDER BY num_bureau;

-- les intersections de plus de 1000 m carrés

SELECT ROUND(ST_area(geom::geography)) AS area_sm, *
FROM iris_bdv
WHERE ROUND(ST_area(geom::geography)) > 1000
ORDER BY ROUND(ST_area(geom::geography)) ASC;

```


Projection/cloropleth
---------------------

Européennnes

```sql
CREATE OR REPLACE VIEW bdv_europe_fi AS (
  SELECT bd.num_bureau, e.votants, e.voix, ROUND(100*e.voix/e.votants)
  FROM election.europeennes e INNER JOIN bdv_countour bd 
       ON e.code_du_b_vote::int4 = bd.num_bureau
  WHERE e.code_insee::int4  = 69123 
  AND e.libelle_abrege_liste = 'LA FRANCE INSOUMISE'
  ORDER BY bd.num_bureau
);
```