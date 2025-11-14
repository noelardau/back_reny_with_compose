-- ================================================
-- TABLE : fichier_evenement (avec stockage BYTEA)
-- ================================================
CREATE TABLE fichier_evenement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evenement_id UUID NOT NULL,
    nom_fichier VARCHAR(255) NOT NULL,
    type_mime VARCHAR(100) NOT NULL,
    taille_bytes BIGINT NOT NULL CHECK (taille_bytes > 0),
    type_fichier VARCHAR(50) NOT NULL CHECK (type_fichier IN ('photo', 'affiche', 'document')),
    donnees_binaire BYTEA NOT NULL,  -- ✅ Changé en BYTEA
    date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_fichier_evenement
        FOREIGN KEY (evenement_id) REFERENCES evenement(id)
        ON DELETE CASCADE
);

-- Index pour les performances
CREATE INDEX idx_fichier_evenement_id ON fichier_evenement(evenement_id);
CREATE INDEX idx_fichier_type ON fichier_evenement(type_fichier);