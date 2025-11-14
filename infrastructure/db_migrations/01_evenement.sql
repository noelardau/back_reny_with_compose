-- ================================================
-- TABLE : evenement
-- ================================================

CREATE TABLE evenement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    date_debut TIMESTAMP NOT NULL,
    date_fin TIMESTAMP NOT NULL,
    type_id UUID NOT NULL,
    lieu_id UUID NOT NULL,
    CONSTRAINT fk_evenement_type
        FOREIGN KEY (type_id) REFERENCES type_evenement(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_evenement_lieu
        FOREIGN KEY (lieu_id) REFERENCES lieu(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_dates
        CHECK (date_fin >= date_debut)
);

-- ================================================
-- TABLE : tarif
-- ================================================

CREATE TABLE tarif (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prix DECIMAL(10,2) NOT NULL CHECK (prix >= 0),
    nombre_places INT NOT NULL CHECK (nombre_places >= 0),
    evenement_id UUID NOT NULL,
    type_place_id UUID NOT NULL,
    CONSTRAINT fk_tarif_evenement
        FOREIGN KEY (evenement_id) REFERENCES evenement(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tarif_type_place
        FOREIGN KEY (type_place_id) REFERENCES type_place(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_tarif UNIQUE (evenement_id, type_place_id)
);