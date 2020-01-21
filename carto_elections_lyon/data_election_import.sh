#!/bin/bash

DIR=data_grand_lyon
PORT=5432
USER=gis
DB=gis
HOST=localhost
PWD=pwdGIS0
SCHEMA=grand_lyon

ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.carrefour $DIR/adrcarrefour.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.troncon $DIR/adraxevoie.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.tourisme $DIR/sittourisme.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.quartier $DIR/adrquartier.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.adresse $DIR/adrdebouche.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.surface $DIR/adrlieusurf.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.bdv_countour $DIR/contour_de_bureau_de_vote.json
ogr2ogr -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.bdv_point $DIR/bureau_de_vote.json

