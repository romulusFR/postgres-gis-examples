#!/bin/bash
mkdir -p data_election
cd data_election

curl "https://public.opendatasoft.com/explore/dataset/resultats-elections-europeennes-2019-bureau-de-vote/download/?format=geojson&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin" > elections_europeennes.json

curl "https://public.opendatasoft.com/explore/dataset/elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-2/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin" > elections_legislatives_tour_2.json

curl "https://public.opendatasoft.com/explore/dataset/elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-1/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_legislatives_tour_1.json

curl "https://public.opendatasoft.com/explore/dataset/election-presidentielle-2017-resultats-par-bureaux-de-vote-tour-1/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_presidentielle_tour_1.json

curl "https://public.opendatasoft.com/explore/dataset/election-presidentielle-2017-resultats-par-bureaux-de-vote-tour-2/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_presidentielle_tour_2.json