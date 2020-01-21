#!/bin/bash
PORT=5432
USER=gis
DB=gis
HOST=localhost


sudo -i -u postgres createuser -e -p $PORT -P $USER
# type password 2 times : pwdGIS0
sudo -i -u postgres createdb -p $PORT $DB -O $USER
sudo -i -u postgres psql -p $PORT -d $DB -c "DROP SCHEMA public;"

psql -p $PORT -h $HOST -U $USER -d $DB -c "CREATE SCHEMA IF NOT EXISTS postgis;"
psql -p $PORT -h $HOST -U $USER -d $DB -c "CREATE SCHEMA IF NOT EXISTS grand_lyon;"
psql -p $PORT -h $HOST -U $USER -d $DB -c "CREATE SCHEMA IF NOT EXISTS election;"
psql -p $PORT -h $HOST -U $USER -d $DB -c "CREATE SCHEMA IF NOT EXISTS insee;"
psql -p $PORT -h $HOST -U $USER -d $DB -c "ALTER DATABASE gis SET search_path TO \"\$user\",grand_lyon,election,insee,postgis";

sudo -i -u postgres psql -p $PORT -d $DB -c "CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA postgis;"

# dropdb -p $PORT gis
# dropuser -p $PORT gis