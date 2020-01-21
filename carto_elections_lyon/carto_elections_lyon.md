
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

```sql
select (ST_IsValidDetail(bdv.wkb_geometry )).reason,
       (ST_IsValidDetail(bdv.wkb_geometry)).location,
       ST_MakeValid(wkb_geometry),
       ST_IsValid(ST_MakeValid(wkb_geometry))
from bdv_countour bdv
where NOT ST_IsValid(bdv.wkb_geometry);
```

39 erreurs que l'on peut toutes corriger.



### Unification des données des bureaux de vote du grand Lyon


```sql
CREATE OR REPLACE VIEW grand_lyon.bdv AS (
  SELECT  bc.num_bureau,
          CAST(bp.arrondissement AS int) AS arrondissement,
          bp.nom AS nom,
          bp.adresse AS adresse,
          bp.wkb_geometry as bdv_point,
          bc.wkb_geometry AS bdv_contour
  FROM grand_lyon.bdv_countour bc
       INNER JOIN grand_lyon.bdv_point bp
        ON bc.num_bureau =  CAST(bp.num_bureau AS int));
```



### Calculer les overlap des iris/bdv


with iris2 AS (
select * from iris
where nom_com ~* 'lyon' and nom_com ~* '2e')
select 100*ST_Area(ST_Intersection(iris2.wkb_geometry, bdv.bdv_contour))/ST_Area(iris2.wkb_geometry) AS pc_iris ,
   *
from iris2 INNER JOIN bdv 
     on st_intersects(iris2.wkb_geometry, bdv.bdv_contour)
Where 100*ST_Area(ST_Intersection(iris2.wkb_geometry, bdv.bdv_contour))/ST_Area(iris2.wkb_geometry) > 1
ORDER by 100*ST_Area(ST_Intersection(iris2.wkb_geometry, bdv.bdv_contour))/ST_Area(iris2.wkb_geometry);

