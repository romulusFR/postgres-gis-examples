#!/bin/bash
mkdir -p data_grand_lyon
cd data_grand_lyon

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adrcarrefour&SRSNAME=urn:ogc:def:crs:EPSG::4326" > adrcarrefour.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adraxevoie&SRSNAME=urn:ogc:def:crs:EPSG::4326" > adraxevoie.json

curl "https://download.data.grandlyon.com/wfs/rdata?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=sit_sitra.sittourisme&SRSNAME=urn:ogc:def:crs:EPSG::4326" > sittourisme.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=65000&request=GetFeature&typename=adr_voie_lieu.adrquartier&SRSNAME=urn:ogc:def:crs:EPSG::4326" > adrquartier.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=adr_voie_lieu.adrdebouche&SRSNAME=urn:ogc:def:crs:EPSG::4326" > adrdebouche.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=adr_voie_lieu.adrlieusurf&SRSNAME=urn:ogc:def:crs:EPSG::4326" > adrlieusurf.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=vdl_vie_citoyenne.contour_de_bureau_de_vote&SRSNAME=urn:ogc:def:crs:EPSG::4326" > contour_de_bureau_de_vote.json

curl "https://download.data.grandlyon.com/wfs/grandlyon?SERVICE=WFS&VERSION=2.0.0&outputformat=GEOJSON&maxfeatures=300000&request=GetFeature&typename=vdl_vie_citoyenne.bureau_de_vote&SRSNAME=urn:ogc:def:crs:EPSG::4326" > bureau_de_vote.json