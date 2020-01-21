#!/bin/bash
mkdir -p data_insee
cd data_insee

curl "https://public.opendatasoft.com/explore/dataset/contours-iris/download/?format=geojson&refine.nom_dep=RHONE&timezone=Europe/Berlin" > iris.json
