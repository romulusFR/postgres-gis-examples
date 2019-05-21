-- Update après chargement

-- Ajout de colonne
ALTER TABLE dvf ADD COLUMN section_prefixe char(5);
UPDATE dvf SET section_prefixe = substr(id_parcelle, 6, 5) ;

-- Données géométriques
ALTER TABLE dvf ADD COLUMN geom geometry;
UPDATE dvf SET geom = ST_PointFromText('POINT(' || longitude || ' ' || latitude ||')', 4326)
WHERE longitude IS NOT NULL AND latitude IS NOT NULL ;

-- Patch en attendant la correction dans la base initiale
UPDATE dvf SET nature_culture = 'Terrain à bâtir' WHERE code_nature_culture = 'AB';
UPDATE dvf SET nature_culture_speciale = 'Abreuvoirs' WHERE code_nature_culture_speciale = 'ABREU';

-- Ajout d'index
CREATE INDEX idx_sectionPrefixe ON dvf(section_prefixe) ;
CREATE INDEX idx_commune ON dvf(code_commune) ;
CREATE INDEX idx_date ON dvf(date_mutation) ;
CREATE INDEX idx_parcelle ON dvf(id_parcelle) ;
CREATE INDEX idx_section_commune ON dvf(code_commune, section_prefixe) ;
CREATE INDEX idx_id_mutation ON dvf(id_mutation) ;

CREATE INDEX idx_geom ON dvf USING GIST (geom);
