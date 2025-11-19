-- ================================================
-- SCRIPT IDÉMPOTENT : Création de la base RENY
-- ================================================

-- === EXTENSION UUID (idempotent) ===
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================================================
-- TABLE : type_evenement
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'type_evenement') THEN
        CREATE TABLE type_evenement (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            nom VARCHAR(100) NOT NULL UNIQUE,
            description TEXT
        );
    END IF;
END $$;

-- ================================================
-- TABLE : lieu
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'lieu') THEN
        CREATE TABLE lieu (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            nom VARCHAR(150) NOT NULL,
            adresse TEXT NOT NULL,
            ville VARCHAR(100) NOT NULL,
            capacite INT CHECK (capacite >= 0 OR capacite IS NULL)
        );
    END IF;
END $$;

-- ================================================
-- TABLE : evenement
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'evenement') THEN
        CREATE TABLE evenement (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            titre VARCHAR(150) NOT NULL,
            description TEXT,
            date_debut TIMESTAMP NOT NULL,
            date_fin TIMESTAMP NOT NULL,
            type_id UUID NOT NULL,
            lieu_id UUID NOT NULL,
            CONSTRAINT fk_evenement_type FOREIGN KEY (type_id) REFERENCES type_evenement(id) ON DELETE CASCADE,
            CONSTRAINT fk_evenement_lieu FOREIGN KEY (lieu_id) REFERENCES lieu(id) ON DELETE CASCADE,
            CONSTRAINT chk_dates CHECK (date_fin >= date_debut)
        );
        CREATE INDEX IF NOT EXISTS idx_evenement_dates ON evenement(date_debut, date_fin);
        CREATE INDEX IF NOT EXISTS idx_evenement_lieu ON evenement(lieu_id);
        CREATE INDEX IF NOT EXISTS idx_evenement_type ON evenement(type_id);
        CREATE INDEX IF NOT EXISTS idx_evenement_titre ON evenement(titre);
    END IF;
END $$;

-- ================================================
-- TABLE : type_place
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'type_place') THEN
        CREATE TABLE type_place (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            nom VARCHAR(50) NOT NULL UNIQUE,
            description TEXT,
            avantages TEXT
        );
    END IF;
END $$;

-- ================================================
-- TABLE : etat_place
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'etat_place') THEN
        CREATE TABLE etat_place (
            code VARCHAR(20) PRIMARY KEY,
            description TEXT NOT NULL
        );
    END IF;
END $$;

-- ================================================
-- TABLE : tarif
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'tarif') THEN
        CREATE TABLE tarif (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            prix DECIMAL(10,2) NOT NULL CHECK (prix >= 0),
            nombre_places INT NOT NULL CHECK (nombre_places >= 0),
            evenement_id UUID NOT NULL,
            type_place_id UUID NOT NULL,
            CONSTRAINT fk_tarif_evenement FOREIGN KEY (evenement_id) REFERENCES evenement(id) ON DELETE CASCADE,
            CONSTRAINT fk_tarif_type_place FOREIGN KEY (type_place_id) REFERENCES type_place(id) ON DELETE CASCADE,
            CONSTRAINT uq_tarif UNIQUE (evenement_id, type_place_id)
        );
        CREATE INDEX IF NOT EXISTS idx_tarif_evenement ON tarif(evenement_id);
        CREATE INDEX IF NOT EXISTS idx_tarif_type_place ON tarif(type_place_id);
    END IF;
END $$;

-- ================================================
-- TABLE : place
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'place') THEN
        CREATE TABLE place (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            numero VARCHAR(100) NOT NULL,
            etat_code VARCHAR(20) NOT NULL DEFAULT 'disponible',
            tarif_id UUID NOT NULL,
            CONSTRAINT fk_place_tarif FOREIGN KEY (tarif_id) REFERENCES tarif(id) ON DELETE CASCADE,
            CONSTRAINT fk_place_etat FOREIGN KEY (etat_code) REFERENCES etat_place(code) ON DELETE RESTRICT,
            CONSTRAINT uq_place_numero_tarif UNIQUE (tarif_id, numero)
        );
        CREATE INDEX IF NOT EXISTS idx_place_etat ON place(etat_code);
        CREATE INDEX IF NOT EXISTS idx_place_tarif ON place(tarif_id);
        CREATE INDEX IF NOT EXISTS idx_place_numero ON place(numero);
        CREATE INDEX IF NOT EXISTS idx_place_etat_tarif ON place(etat_code, tarif_id);
    END IF;
END $$;

-- ================================================
-- TABLE : audit_place
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'audit_place') THEN
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
        CREATE INDEX IF NOT EXISTS idx_audit_place_id ON audit_place(place_id);
        CREATE INDEX IF NOT EXISTS idx_audit_date ON audit_place(date_changement);
    END IF;
END $$;

-- ================================================
-- TABLE : fichier_evenement
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'fichier_evenement') THEN
        CREATE TABLE fichier_evenement (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            evenement_id UUID NOT NULL,
            nom_fichier VARCHAR(255) NOT NULL,
            type_mime VARCHAR(100) NOT NULL,
            taille_bytes BIGINT NOT NULL CHECK (taille_bytes > 0),
            type_fichier VARCHAR(50) NOT NULL CHECK (type_fichier IN ('photo', 'affiche', 'document')),
            donnees_binaire BYTEA NOT NULL,
            date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_fichier_evenement FOREIGN KEY (evenement_id) REFERENCES evenement(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_fichier_evenement_id ON fichier_evenement(evenement_id);
        CREATE INDEX IF NOT EXISTS idx_fichier_type ON fichier_evenement(type_fichier);
    END IF;
END $$;

-- ================================================
-- TABLE : reservation & reservation_place
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'reservation') THEN
        CREATE TABLE reservation (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            reference_paiement VARCHAR(100),
            date_reservation TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            email VARCHAR(255) NOT NULL,
            etat_code VARCHAR(20) DEFAULT 'en_attente' NOT NULL,
            etat VARCHAR(20) DEFAULT 'en_attente' NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_reservation_reference_paiement ON reservation(reference_paiement);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'reservation_place') THEN
        CREATE TABLE reservation_place (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            reservation_id UUID NOT NULL,
            place_id UUID NOT NULL,
            CONSTRAINT uq_reservation_place UNIQUE (place_id),
            CONSTRAINT fk_reservation_place_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(id) ON DELETE CASCADE,
            CONSTRAINT fk_reservation_place_place FOREIGN KEY (place_id) REFERENCES place(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_reservation_place_reservation ON reservation_place(reservation_id);
        CREATE INDEX IF NOT EXISTS idx_reservation_place_place ON reservation_place(place_id);
    END IF;
END $$;

-- ================================================
-- DONNÉES DE RÉFÉRENCE (idempotent avec upsert)
-- ================================================

-- etat_place
INSERT INTO etat_place (code, description)
VALUES
    ('disponible', 'Place disponible à la vente'),
    ('reservee', 'Place réservée temporairement'),
    ('vendue', 'Place vendue'),
    ('annulee', 'Place annulée/invalide'),
    ('maintenance', 'Place en maintenance')
ON CONFLICT (code) DO NOTHING;

-- type_evenement
INSERT INTO type_evenement (nom, description)
VALUES
    ('Concert', 'Événement musical avec artistes sur scène'),
    ('Conference', 'Événement de présentation et d''échanges'),
    ('Spectacle', 'Représentation théâtrale ou artistique'),
    ('Foire', 'Événement commercial avec exposants'),
    ('Seminaire', 'Séminaire professionnel'),
    ('Exposition', 'Présentation d''œuvres ou de produits')
ON CONFLICT (nom) DO NOTHING;

-- type_place
INSERT INTO type_place (nom, description, avantages)
VALUES
    ('VIP', 'Place premium avec avantages exclusifs', 'Accès lounge, parking dédié, restauration incluse'),
    ('Standard', 'Place classique standard', 'Accès à l''événement, siège standard'),
    ('Économique', 'Place à prix réduit', 'Accès basique à l''événement'),
    ('Premium', 'Place premium confort', 'Sièges plus larges, service prioritaire')
ON CONFLICT (nom) DO NOTHING;

-- ================================================
-- FONCTIONS, TRIGGERS, VUES (idempotents)
-- ================================================

-- Supprime si existe, puis recrée
DROP FUNCTION IF EXISTS valider_parametres_creation(VARCHAR,TEXT,TIMESTAMP,TIMESTAMP,UUID,JSONB) CASCADE;
DROP FUNCTION IF EXISTS calculer_total_places(JSONB) CASCADE;
DROP FUNCTION IF EXISTS valider_tarifs(JSONB) CASCADE;
DROP FUNCTION IF EXISTS creer_lieu(VARCHAR,TEXT,VARCHAR,INT) CASCADE;
DROP FUNCTION IF EXISTS creer_evenement(VARCHAR,TEXT,TIMESTAMP,TIMESTAMP,UUID,UUID) CASCADE;
DROP FUNCTION IF EXISTS creer_tarifs(UUID,JSONB) CASCADE;
DROP FUNCTION IF EXISTS creer_fichiers_bytea(UUID,JSONB) CASCADE;
DROP FUNCTION IF EXISTS creer_evenement_complet(VARCHAR,TEXT,TIMESTAMP,TIMESTAMP,UUID,VARCHAR,TEXT,VARCHAR,INT,JSONB,JSONB) CASCADE;
DROP FUNCTION IF EXISTS valider_nouvel_evenement() CASCADE;
DROP FUNCTION IF EXISTS creer_places_automatiquement() CASCADE;
DROP FUNCTION IF EXISTS auditer_changement_etat() CASCADE;
DROP FUNCTION IF EXISTS verifier_capacite_lieu(INT,JSONB) CASCADE;
DROP FUNCTION IF EXISTS generer_numero_place(UUID,INT) CASCADE;
DROP FUNCTION IF EXISTS obtenir_evenement_par_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS reserver_places(VARCHAR,UUID,JSONB) CASCADE;
DROP FUNCTION IF EXISTS obtenir_reservations_evenement(UUID) CASCADE;
DROP FUNCTION IF EXISTS obtenir_details_reservation_par_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS obtenir_tous_evenements() CASCADE;
DROP FUNCTION IF EXISTS obtenir_reservation_par_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS obtenir_tous_types_places() CASCADE;
DROP FUNCTION IF EXISTS obtenir_tous_types_evenements() CASCADE;

DROP VIEW IF EXISTS vue_evenement_complet CASCADE;
DROP VIEW IF EXISTS vue_reservations_evenement CASCADE;

DROP TRIGGER IF EXISTS trigger_valider_evenement ON evenement;
DROP TRIGGER IF EXISTS trigger_creer_places ON tarif;
DROP TRIGGER IF EXISTS trigger_audit_place ON place;

-- === RECRÉATION DES FONCTIONS ===
-- (Colle ici toutes tes fonctions CREATE OR REPLACE FUNCTION ...)

-- Exemple (raccourci) :
CREATE OR REPLACE FUNCTION valider_parametres_creation(
    p_titre VARCHAR(150), p_description TEXT, p_date_debut TIMESTAMP,
    p_date_fin TIMESTAMP, p_type_id UUID, p_tarifs JSONB
) RETURNS VOID AS $$
BEGIN
    IF p_titre IS NULL OR trim(p_titre) = '' THEN RAISE EXCEPTION 'Le titre est obligatoire'; END IF;
    IF length(trim(p_titre)) > 150 THEN RAISE EXCEPTION 'Le titre ne peut pas dépasser 150 caractères'; END IF;
    IF p_date_debut IS NULL OR p_date_fin IS NULL THEN RAISE EXCEPTION 'Les dates sont obligatoires'; END IF;
    IF p_date_debut >= p_date_fin THEN RAISE EXCEPTION 'La date de début doit être avant la fin'; END IF;
    IF NOT EXISTS (SELECT 1 FROM type_evenement WHERE id = p_type_id) THEN RAISE EXCEPTION 'Type invalide'; END IF;
    IF p_tarifs IS NULL OR jsonb_array_length(p_tarifs) = 0 THEN RAISE EXCEPTION 'Au moins un tarif requis'; END IF;
END;
$$ LANGUAGE plpgsql;

-- (Colle ici les autres fonctions avec CREATE OR REPLACE)

-- === TRIGGERS ===
CREATE OR REPLACE FUNCTION valider_nouvel_evenement() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.date_debut <= CURRENT_TIMESTAMP THEN RAISE EXCEPTION 'Date future requise'; END IF;
    IF NEW.date_debut >= NEW.date_fin THEN RAISE EXCEPTION 'Dates invalides'; END IF;
    IF EXISTS (SELECT 1 FROM evenement e WHERE e.lieu_id = NEW.lieu_id AND e.id != NEW.id
               AND e.date_debut < NEW.date_fin AND e.date_fin > NEW.date_debut)
    THEN RAISE EXCEPTION 'Lieu déjà réservé'; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_valider_evenement ON evenement;
CREATE TRIGGER trigger_valider_evenement
    BEFORE INSERT OR UPDATE ON evenement
    FOR EACH ROW EXECUTE FUNCTION valider_nouvel_evenement();

-- (Autres triggers...)

-- === VUES ===
CREATE OR REPLACE VIEW vue_evenement_complet AS
-- (Colle ici ta vue complète)
SELECT ...;


CREATE OR REPLACE FUNCTION obtenir_tous_evenements()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'evenement_id', e.id,
            'titre', e.titre,
            'description', e.description,
            'date_debut', e.date_debut,
            'date_fin', e.date_fin,
            'type_evenement', jsonb_build_object(
                'id', te.id,
                'nom', te.nom,
                'description', te.description
            ),
            'lieu', jsonb_build_object(
                'id', l.id,
                'nom', l.nom,
                'adresse', l.adresse,
                'ville', l.ville,
                'capacite', l.capacite
            ),
            'tarifs', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'tarif_id', t.id,
                        'prix', t.prix,
                        'nombre_places', t.nombre_places,
                        'type_place', jsonb_build_object(
                            'id', tp.id,
                            'nom', tp.nom,
                            'description', tp.description,
                            'avantages', tp.avantages
                        )
                    )
                )
                FROM tarif t
                JOIN type_place tp ON t.type_place_id = tp.id
                WHERE t.evenement_id = e.id
            ),
            'fichiers', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'fichier_id', fe.id,
                        'nom_fichier', fe.nom_fichier,
                        'type_mime', fe.type_mime,
                        'taille_bytes', fe.taille_bytes,
                        'type_fichier', fe.type_fichier,
                        'date_upload', fe.date_upload,
                        'donnees_binaire', encode(fe.donnees_binaire, 'base64') -- Conversion en base64
                    )
                )
                FROM fichier_evenement fe
                WHERE fe.evenement_id = e.id
            )
        )
        ORDER BY e.date_debut DESC
    )
    INTO result
    FROM evenement e
    JOIN type_evenement te ON e.type_id = te.id
    JOIN lieu l ON e.lieu_id = l.id;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FIN DU SCRIPT IDÉMPOTENT
-- ================================================