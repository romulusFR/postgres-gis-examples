#!/bin/bash
# Script de creation de la base de donnees PostgreSQL 
DIR=$(echo $(dirname $0))
DATADIR="data"
cd $DIR

# psql -d gis -f "cadastre_dvf_schema.sql"

echo Running import from $DIR
mkdir -p $DATADIR

for YEAR in 2014 2015 2016 2017 2018
do
  [ ! -f $DATADIR/full_$YEAR.csv.gz ] && wget -r -nc -np -nH --cut-dirs 5  https://cadastre.data.gouv.fr/data/etalab-dvf/latest/csv/$YEAR/full.csv.gz -O $DATADIR/full_$YEAR.csv.gz
done

DATAPATH=$( cd $DATADIR ; pwd -P )
for YEAR in 2014 2015 2016 2017 2018
do
  ls -al $DATADIR/full_$YEAR.csv.gz
  time psql -d gis -c "\copy dvf FROM program 'zcat $DATADIR/full_$YEAR.csv.gz' DELIMITER ',' CSV HEADER  ENCODING 'UTF8';"
done

# Ajout de colonnes et d'index - Assez long
# psql -d gis -f "cadastre_dvf_alter_table.sql"
