#!/bin/bash

DIR=data_election
PORT=5432
USER=gis
DB=gis
HOST=localhost
PWD=pwdGIS0
SCHEMA=election

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.europeennes $DIR/elections_europeennes.json

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.legislatives1  $DIR/elections_legislatives_tour_1.json

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.legislatives2  $DIR/elections_legislatives_tour_2.json

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.presidentielle1  $DIR/elections_presidentielle_tour_1.json

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.presidentielle2  $DIR/elections_presidentielle_tour_2.json

