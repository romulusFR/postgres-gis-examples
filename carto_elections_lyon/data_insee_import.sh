#!/bin/bash

DIR=data_insee
PORT=5432
USER=gis
DB=gis
HOST=localhost
PWD=pwdGIS0
SCHEMA=insee

ogr2ogr -progress -f "PostgreSQL" PG:"dbname='$DB' port='$PORT' user='$USER' host='$HOST' password='$PWD'" -nln $SCHEMA.iris $DIR/iris.json
