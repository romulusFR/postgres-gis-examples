#!/bin/bash
mkdir -p data_election
cd data_election

curl "https://public.opendatasoft.com/explore/dataset/resultats-elections-europeennes-2019-bureau-de-vote/download/?format=geojson&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin" > elections_europeennes.json

curl "https://public.opendatasoft.com/explore/dataset/elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-2/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin" > elections_legislatives_tour_2.json

curl "https://public.opendatasoft.com/explore/dataset/elections-legislatives-2017-resultats-par-bureaux-de-vote-tour-1/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_legislatives_tour_1.json

curl "https://public.opendatasoft.com/explore/dataset/election-presidentielle-2017-resultats-par-bureaux-de-vote-tour-1/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_presidentielle_tour_1.json

curl "https://public.opendatasoft.com/explore/dataset/election-presidentielle-2017-resultats-par-bureaux-de-vote-tour-2/download/?format=geojson&disjunctive.libelle_de_la_commune=true&refine.libelle_du_departement=Rh%C3%B4ne&timezone=Europe/Berlin"  > elections_presidentielle_tour_2.json

# curl "https://public.opendatasoft.com/explore/dataset/codes-nuances-listes-municipales-2014/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true&csv_separator=%3B" > municipales-2014-codes-nuances-listes.csv

# curl "https://public.opendatasoft.com/explore/dataset/les-elus-municipaux-2014/download/?format=csv&refine.coddpt=69&timezone=Europe/Berlin&use_labels_for_header=true&csv_separator=%3B" > municipaux-2014-les-elus.csv

# curl "https://public.opendatasoft.com/explore/dataset/resultats-des-elections-municipales-2014/download/?format=csv&refine.code_departement=69&timezone=Europe/Berlin&use_labels_for_header=true&csv_separator=%3B" > municipales-2014-resultats-des-elections.csv


curl "https://public.opendatasoft.com/explore/dataset/codes-nuances-listes-municipales-2014/download/?format=geojson&timezone=Europe/Berlin" > municipales-2014-codes-nuances-listes.json

curl "https://public.opendatasoft.com/explore/dataset/les-elus-municipaux-2014/download/?format=geojson&refine.coddpt=69&timezone=Europe/Berlin" > municipaux-2014-les-elus.json

curl "https://public.opendatasoft.com/explore/dataset/resultats-des-elections-municipales-2014/download/?format=geojson&refine.code_departement=69&timezone=Europe/Berlin" > municipales-2014-resultats-des-elections.json