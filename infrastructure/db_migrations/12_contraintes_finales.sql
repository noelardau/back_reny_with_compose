-- ================================================
-- CONTRAINTES FINALES ET AJUSTEMENTS
-- ================================================

-- Contrainte d'unicité pour les places
ALTER TABLE place ADD CONSTRAINT uq_place_numero_tarif UNIQUE (tarif_id, numero);

-- Ajustements de colonnes
ALTER TABLE reservation ADD COLUMN IF NOT EXISTS email VARCHAR(255) NOT NULL;
ALTER TABLE reservation ADD COLUMN IF NOT EXISTS etat VARCHAR(20) NOT NULL DEFAULT 'en_attente';