-- ================================================
-- TABLE : type_evenement
-- ================================================
CREATE TABLE type_evenement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- ================================================
-- TABLE : lieu
-- ================================================
CREATE TABLE lieu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(150) NOT NULL,
    adresse TEXT NOT NULL,
    ville VARCHAR(100) NOT NULL,
    capacite INT CHECK (capacite >= 0)
);

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
-- TABLE : type_place
-- ================================================
CREATE TABLE type_place (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    avantages TEXT
);

-- ================================================
-- TABLE : etat_place
-- ================================================
CREATE TABLE etat_place (
    code VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL
);

-- Insertion des états prédéfinis
INSERT INTO etat_place (code, description) VALUES
('disponible', 'Place disponible à la vente'),
('reservee', 'Place réservée temporairement'),
('vendue', 'Place vendue'),
('annulee', 'Place annulée/invalide'),
('maintenance', 'Place en maintenance');

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

-- ================================================
-- TABLE : place
-- ================================================
CREATE TABLE place (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero VARCHAR(50) NOT NULL,
    etat_code VARCHAR(20) NOT NULL DEFAULT 'disponible',
    tarif_id UUID NOT NULL,
    CONSTRAINT fk_place_tarif
        FOREIGN KEY (tarif_id) REFERENCES tarif(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_place_etat
        FOREIGN KEY (etat_code) REFERENCES etat_place(code)
        ON DELETE RESTRICT,
    CONSTRAINT uq_place_numero_tarif UNIQUE (tarif_id, numero)
);

-- ================================================
-- TABLE : audit_place (pour le suivi des changements)
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


-- ================================================
-- INDEX pour les performances
-- ================================================
CREATE INDEX idx_evenement_dates ON evenement(date_debut, date_fin);
CREATE INDEX idx_evenement_lieu ON evenement(lieu_id);
CREATE INDEX idx_evenement_type ON evenement(type_id);
CREATE INDEX idx_place_etat ON place(etat_code);
CREATE INDEX idx_tarif_evenement ON tarif(evenement_id);
CREATE INDEX idx_tarif_type_place ON tarif(type_place_id);
CREATE INDEX idx_place_tarif ON place(tarif_id);
CREATE INDEX idx_audit_place_id ON audit_place(place_id);
CREATE INDEX idx_audit_date ON audit_place(date_changement);




-- ================================================
-- FONCTION : Vérification de capacité
-- ================================================
CREATE OR REPLACE FUNCTION verifier_capacite_lieu(
    p_evenement_id UUID, 
    p_nouvelles_places INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    capacite_lieu INTEGER;
    places_existantes INTEGER;
    places_actuelles_tarif INTEGER := 0;
BEGIN
    -- Récupérer la capacité du lieu
    SELECT l.capacite INTO capacite_lieu
    FROM evenement e
    JOIN lieu l ON e.lieu_id = l.id
    WHERE e.id = p_evenement_id;
    
    -- Compter les places déjà créées pour cet événement
    SELECT COUNT(p.id) INTO places_existantes
    FROM place p
    JOIN tarif t ON p.tarif_id = t.id
    WHERE t.evenement_id = p_evenement_id;
    
    -- ✅ AJOUT : Vérifier si assez de capacité
    RETURN (places_existantes + p_nouvelles_places) <= capacite_lieu;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Génération de numéros de place
-- ================================================
CREATE OR REPLACE FUNCTION generer_numero_place(
    p_type_place_id UUID, 
    p_numero INTEGER
) RETURNS VARCHAR(50) AS $$
DECLARE
    nom_type VARCHAR(50);
BEGIN
    -- Récupérer le nom du type de place
    SELECT nom INTO nom_type FROM type_place WHERE id = p_type_place_id;
    
    -- Créer un prefixe intelligent (3 premières lettres en majuscule)
    RETURN CONCAT(UPPER(SUBSTRING(nom_type FROM 1 FOR 3)), '-', LPAD(p_numero::TEXT, 3, '0'));
END;
$$ LANGUAGE plpgsql;



-- ================================================
-- TRIGGER 1 : Validation avant création d'événement
-- ================================================
CREATE OR REPLACE FUNCTION valider_nouvel_evenement()
RETURNS TRIGGER AS $$
BEGIN

    IF NEW.date_debut <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La date de début doit être dans le futur';
    END IF;
    

    IF EXISTS (
        SELECT 1 FROM evenement e
        WHERE e.lieu_id = NEW.lieu_id
        AND e.id != NEW.id
        AND e.date_debut < NEW.date_fin
        AND e.date_fin > NEW.date_debut
    ) THEN
        RAISE EXCEPTION 'Le lieu est déjà réservé sur cette plage horaire';
    END IF;
    
 
    IF (NEW.date_fin - NEW.date_debut) < INTERVAL '30 minutes' THEN
        RAISE EXCEPTION 'La durée minimum est de 30 minutes';
    END IF;
    
 
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_valider_evenement
    BEFORE INSERT ON evenement
    FOR EACH ROW
    EXECUTE FUNCTION valider_nouvel_evenement();

-- ================================================
-- TRIGGER 2 : Création automatique des places
-- ================================================
CREATE OR REPLACE FUNCTION creer_places_automatiquement()
RETURNS TRIGGER AS $$
DECLARE
    compteur INTEGER := 1;
    numero_place VARCHAR(100);
    nom_type_place VARCHAR(50);
    uuid_evenement_sans_tirets TEXT;
    places_deja_creees INTEGER;
BEGIN
    -- Récupérer l'UUID de l'événement et le nom du type de place
    SELECT e.id, tp.nom 
    INTO uuid_evenement_sans_tirets, nom_type_place
    FROM evenement e, type_place tp
    WHERE e.id = NEW.evenement_id AND tp.id = NEW.type_place_id;
    
    uuid_evenement_sans_tirets := REPLACE(uuid_evenement_sans_tirets::text, '-', '');
    
    -- ✅ COMPTER les places DÉJÀ CRÉÉES pour ce type de place dans cet événement
    SELECT COUNT(p.id) INTO places_deja_creees
    FROM place p
    JOIN tarif t ON p.tarif_id = t.id
    WHERE t.evenement_id = NEW.evenement_id 
    AND t.type_place_id = NEW.type_place_id;
    
    -- Vérifier la capacité
    IF NOT verifier_capacite_lieu(NEW.evenement_id, NEW.nombre_places) THEN
        RAISE EXCEPTION 'Capacité du lieu insuffisante. Places existantes: %, Nouvelles: %, Capacité: %', 
            places_existantes, NEW.nombre_places, capacite_lieu;
    END IF;
    
    -- Créer les places en CONTINUANT la numérotation
    WHILE compteur <= NEW.nombre_places LOOP
        numero_place := CONCAT(
            UPPER(SUBSTRING(nom_type_place FROM 1 FOR 3)), 
            '-',
            uuid_evenement_sans_tirets,
            '-',
            LPAD((places_deja_creees + compteur)::TEXT, 4, '0')  -- ✅ CONTINUE la numérotation
        );
        
        INSERT INTO place (numero, etat_code, tarif_id)
        VALUES (numero_place, 'disponible', NEW.id);
        
        compteur := compteur + 1;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- TRIGGER 3 : Audit des changements d'état des places
-- ================================================
CREATE OR REPLACE FUNCTION auditer_changement_etat()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.etat_code IS DISTINCT FROM NEW.etat_code THEN
        INSERT INTO audit_place (place_id, ancien_etat, nouvel_etat, utilisateur)
        VALUES (NEW.id, OLD.etat_code, NEW.etat_code, CURRENT_USER);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_place
    AFTER UPDATE ON place
    FOR EACH ROW
    EXECUTE FUNCTION auditer_changement_etat();


-- ================================================
-- FONCTION PRINCIPALE : Création complète avec fichiers
-- ================================================
CREATE OR REPLACE FUNCTION creer_evenement_complet(
    p_titre VARCHAR(150),
    p_description TEXT,
    p_date_debut TIMESTAMP,
    p_date_fin TIMESTAMP,
    p_type_id UUID,
    p_lieu_nom VARCHAR(150),
    p_lieu_adresse TEXT,
    p_lieu_ville VARCHAR(100),
    p_lieu_capacite INT,
    p_tarifs JSONB,
    p_fichiers JSONB DEFAULT '[]'::JSONB
) 
RETURNS UUID
AS $$
DECLARE
    nouveau_lieu_id UUID;
    nouvel_evenement_id UUID;
    tarif_record JSONB;
    fichier_record JSONB;
BEGIN
    -- VALIDATION des paramètres obligatoires
    IF p_titre IS NULL OR p_titre = '' THEN
        RAISE EXCEPTION 'Le titre est obligatoire';
    END IF;
    
    IF p_tarifs IS NULL OR jsonb_array_length(p_tarifs) = 0 THEN
        RAISE EXCEPTION 'Au moins un tarif doit être spécifié';
    END IF;
    
    -- ÉTAPE 1 : Création du lieu
    INSERT INTO lieu (nom, adresse, ville, capacite)
    VALUES (p_lieu_nom, p_lieu_adresse, p_lieu_ville, p_lieu_capacite)
    RETURNING id INTO nouveau_lieu_id;
    
    -- ÉTAPE 2 : Création de l'événement
    INSERT INTO evenement (titre, description, date_debut, date_fin, type_id, lieu_id)
    VALUES (p_titre, p_description, p_date_debut, p_date_fin, p_type_id, nouveau_lieu_id)
    RETURNING id INTO nouvel_evenement_id;
    
    -- ÉTAPE 3 : Création des tarifs
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        INSERT INTO tarif (prix, nombre_places, evenement_id, type_place_id)
        VALUES (
            (tarif_record->>'prix')::DECIMAL,
            (tarif_record->>'nombre_places')::INTEGER,
            nouvel_evenement_id,
            (tarif_record->>'type_place_id')::UUID
        );
    END LOOP;
    
    -- ÉTAPE 4 : Création des fichiers (si présents)
    IF p_fichiers IS NOT NULL AND jsonb_array_length(p_fichiers) > 0 THEN
        FOR fichier_record IN SELECT * FROM jsonb_array_elements(p_fichiers) 
        LOOP
            INSERT INTO fichier_evenement (
                evenement_id, 
                nom_fichier, 
                type_mime, 
                taille_bytes, 
                type_fichier, 
                donnees_binaire
            )
            VALUES (
                nouvel_evenement_id,
                fichier_record->>'nom_fichier',
                fichier_record->>'type_mime',
                octet_length((fichier_record->>'donnees_binaire')::bytea),
                fichier_record->>'type_fichier',
                decode(fichier_record->>'donnees_binaire', 'base64')
            );
        END LOOP;
    END IF;
    
    -- RETOUR de l'ID de l'événement créé
    RETURN nouvel_evenement_id;
    
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Erreur lors de la création de l''événement: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- INSERT_INITIAL

INSERT INTO type_evenement (nom, description) VALUES
('Concert', 'Événement musical avec artistes sur scène'),
('Conference', 'Événement de présentation et d''échanges'),
('Spectacle', 'Représentation théâtrale ou artistique'),
('Foire', 'Compétition ou événement sportif'),
('Seminaire', 'Seminaire'),
('Exposition', 'Présentation d''œuvres ou de produits');

INSERT INTO type_place (nom, description, avantages) VALUES
('VIP', 'Place premium avec avantages exclusifs', 'Accès lounge, parking dédié, restauration incluse'),
('Standard', 'Place classique standard', 'Accès à l''événement, siège standard'),
('Économique', 'Place à prix réduit', 'Accès basique à l''événement'),
('Premium', 'Premium');
