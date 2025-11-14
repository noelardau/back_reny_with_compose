-- ================================================
-- TABLE : place
-- ================================================

CREATE TABLE place (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero VARCHAR(100) NOT NULL,
    etat_code VARCHAR(20) NOT NULL DEFAULT 'disponible',
    tarif_id UUID NOT NULL,
    CONSTRAINT fk_place_tarif
        FOREIGN KEY (tarif_id) REFERENCES tarif(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_place_etat
        FOREIGN KEY (etat_code) REFERENCES etat_place(code)
        ON DELETE RESTRICT
);

-- ================================================
-- TABLE : audit_place
-- ================================================

CREATE TABLE audit_place (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID NOT NULL,
    ancien_etat VARCHAR(20),
    nouvel_etat VARCHAR(20) NOT NULL,
    date_changement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilisateur VARCHAR(100),
    FOREIGN KEY (place_id) REFERENCES place(id) ON DELETE CASCADE,
    FOREIGN KEY (ancien_etat) REFERENCES etat_place(code),
    FOREIGN KEY (nouvel_etat) REFERENCES etat_place(code)
);