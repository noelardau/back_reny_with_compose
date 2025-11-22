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
    capacite INT CHECK (capacite >= 0 OR capacite IS NULL)
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
    numero VARCHAR(100) NOT NULL,
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
-- TABLE : fichier_evenement (avec stockage BYTEA)
-- ================================================
CREATE TABLE fichier_evenement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evenement_id UUID NOT NULL,
    nom_fichier VARCHAR(255) NOT NULL,
    type_mime VARCHAR(100) NOT NULL,
    taille_bytes BIGINT NOT NULL CHECK (taille_bytes > 0),
    type_fichier VARCHAR(50) NOT NULL CHECK (type_fichier IN ('photo', 'affiche', 'document')),
    donnees_binaire BYTEA NOT NULL,
    date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_fichier_evenement
        FOREIGN KEY (evenement_id) REFERENCES evenement(id)
        ON DELETE CASCADE
);


-- Insertion des états de place prédéfinis
INSERT INTO etat_place (code, description) VALUES
('disponible', 'Place disponible à la vente'),
('reservee', 'Place réservée temporairement'),
('vendue', 'Place vendue'),
('annulee', 'Place annulée/invalide'),
('maintenance', 'Place en maintenance');

-- Insertion des types d'événement
INSERT INTO type_evenement (nom, description) VALUES
('Concert', 'Événement musical avec artistes sur scène'),
('Conference', 'Événement de présentation et d''échanges'),
('Spectacle', 'Représentation théâtrale ou artistique'),
('Foire', 'Événement commercial avec exposants'),
('Seminaire', 'Séminaire professionnel'),
('Exposition', 'Présentation d''œuvres ou de produits');

-- Insertion des types de place
INSERT INTO type_place (nom, description, avantages) VALUES
('VIP', 'Place premium avec avantages exclusifs', 'Accès lounge, parking dédié, restauration incluse'),
('Standard', 'Place classique standard', 'Accès à l''événement, siège standard'),
('Économique', 'Place à prix réduit', 'Accès basique à l''événement'),
('Premium', 'Place premium confort', 'Sièges plus larges, service prioritaire');



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
CREATE INDEX idx_place_numero ON place(numero);
CREATE INDEX idx_evenement_titre ON evenement(titre);
CREATE INDEX idx_audit_place_id ON audit_place(place_id);
CREATE INDEX idx_audit_date ON audit_place(date_changement);
CREATE INDEX idx_fichier_evenement_id ON fichier_evenement(evenement_id);
CREATE INDEX idx_fichier_type ON fichier_evenement(type_fichier);




-- ================================================
-- FONCTION : Validation des paramètres de création
-- ================================================
CREATE OR REPLACE FUNCTION valider_parametres_creation(
    p_titre VARCHAR(150),
    p_description TEXT,
    p_date_debut TIMESTAMP,
    p_date_fin TIMESTAMP,
    p_type_id UUID,
    p_tarifs JSONB
) RETURNS VOID AS $$
BEGIN
    -- Validation du titre
    IF p_titre IS NULL OR trim(p_titre) = '' THEN
        RAISE EXCEPTION 'Le titre est obligatoire';
    END IF;
    
    IF length(trim(p_titre)) > 150 THEN
        RAISE EXCEPTION 'Le titre ne peut pas dépasser 150 caractères';
    END IF;
    
    -- Validation des dates
    IF p_date_debut IS NULL OR p_date_fin IS NULL THEN
        RAISE EXCEPTION 'Les dates de début et fin sont obligatoires';
    END IF;
    
    IF p_date_debut >= p_date_fin THEN
        RAISE EXCEPTION 'La date de début doit être avant la date de fin';
    END IF;
    
    -- Validation du type d'événement
    IF p_type_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM type_evenement WHERE id = p_type_id
    ) THEN
        RAISE EXCEPTION 'Le type d''événement est invalide';
    END IF;
    
    -- Validation des tarifs
    IF p_tarifs IS NULL OR jsonb_array_length(p_tarifs) = 0 THEN
        RAISE EXCEPTION 'Au moins un tarif doit être spécifié';
    END IF;
    
    -- Validation de la structure JSON des tarifs
    IF NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(p_tarifs) AS tarif
        WHERE tarif ? 'type_place_id' 
          AND tarif ? 'prix' 
          AND tarif ? 'nombre_places'
    ) THEN
        RAISE EXCEPTION 'Structure JSON des tarifs invalide. Champs requis: type_place_id, prix, nombre_places';
    END IF;
    
    -- Validation détaillée des tarifs
    PERFORM valider_tarifs(p_tarifs);
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Calcul du total des places demandées
-- ================================================
CREATE OR REPLACE FUNCTION calculer_total_places(p_tarifs JSONB)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER := 0;
    tarif_record JSONB;
BEGIN
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        total := total + COALESCE((tarif_record->>'nombre_places')::INTEGER, 0);
    END LOOP;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Validation détaillée des tarifs
-- ================================================
CREATE OR REPLACE FUNCTION valider_tarifs(p_tarifs JSONB)
RETURNS VOID AS $$
DECLARE
    tarif_record JSONB;
    type_place_id UUID;
    prix DECIMAL(10,2);
    nombre_places INTEGER;
BEGIN
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        -- Extraction des valeurs
        type_place_id := (tarif_record->>'type_place_id')::UUID;
        prix := (tarif_record->>'prix')::DECIMAL;
        nombre_places := (tarif_record->>'nombre_places')::INTEGER;
        
        -- Validation du type de place
        IF type_place_id IS NULL OR NOT EXISTS (
            SELECT 1 FROM type_place WHERE id = type_place_id
        ) THEN
            RAISE EXCEPTION 'Type de place invalide: %', type_place_id;
        END IF;
        
        -- Validation du prix
        IF prix IS NULL OR prix < 0 THEN
            RAISE EXCEPTION 'Le prix doit être positif ou nul. Valeur reçue: %', prix;
        END IF;
        
        IF prix > 100000 THEN
            RAISE EXCEPTION 'Le prix ne peut pas dépasser 100000';
        END IF;
        
        -- Validation du nombre de places
        IF nombre_places IS NULL OR nombre_places <= 0 THEN
            RAISE EXCEPTION 'Le nombre de places doit être positif. Valeur reçue: %', nombre_places;
        END IF;
        
        IF nombre_places > 100000 THEN
            RAISE EXCEPTION 'Le nombre de places ne peut pas dépasser 100000';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Création d'un lieu
-- ================================================
CREATE OR REPLACE FUNCTION creer_lieu(
    p_nom VARCHAR(150),
    p_adresse TEXT,
    p_ville VARCHAR(100),
    p_capacite INT
) RETURNS UUID AS $$
DECLARE
    nouveau_lieu_id UUID;
BEGIN
    INSERT INTO lieu (nom, adresse, ville, capacite)
    VALUES (
        p_nom, 
        p_adresse, 
        p_ville, 
        CASE WHEN p_capacite <= 0 THEN NULL ELSE p_capacite END
    )
    RETURNING id INTO nouveau_lieu_id;
    
    RETURN nouveau_lieu_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Création d'un événement
-- ================================================
CREATE OR REPLACE FUNCTION creer_evenement(
    p_titre VARCHAR(150),
    p_description TEXT,
    p_date_debut TIMESTAMP,
    p_date_fin TIMESTAMP,
    p_type_id UUID,
    p_lieu_id UUID
) RETURNS UUID AS $$
DECLARE
    nouvel_evenement_id UUID;
BEGIN
    INSERT INTO evenement (titre, description, date_debut, date_fin, type_id, lieu_id)
    VALUES (p_titre, p_description, p_date_debut, p_date_fin, p_type_id, p_lieu_id)
    RETURNING id INTO nouvel_evenement_id;
    
    RETURN nouvel_evenement_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Création des tarifs pour un événement
-- ================================================
CREATE OR REPLACE FUNCTION creer_tarifs(
    p_evenement_id UUID,
    p_tarifs JSONB
) RETURNS VOID AS $$
DECLARE
    tarif_record JSONB;
BEGIN
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        INSERT INTO tarif (prix, nombre_places, evenement_id, type_place_id)
        VALUES (
            (tarif_record->>'prix')::DECIMAL,
            (tarif_record->>'nombre_places')::INTEGER,
            p_evenement_id,
            (tarif_record->>'type_place_id')::UUID
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Création des fichiers pour un événement
-- ================================================
CREATE OR REPLACE FUNCTION creer_fichiers(
    p_evenement_id UUID,
    p_fichiers JSONB
) RETURNS VOID AS $$
DECLARE
    fichier_record JSONB;
    donnees_binaires BYTEA;
    taille_calculee BIGINT;
BEGIN
    FOR fichier_record IN SELECT * FROM jsonb_array_elements(p_fichiers) 
    LOOP
        -- Conversion base64 vers BYTEA avec gestion d'erreur
        BEGIN
            donnees_binaires := decode(
                REPLACE(REPLACE(fichier_record->>'donnees_binaire', ' ', '+'), '\n', ''), 
                'base64'
            );
        EXCEPTION
            WHEN others THEN
                RAISE EXCEPTION 'Données base64 invalides pour le fichier: %', 
                    fichier_record->>'nom_fichier';
        END;
        
        -- Calcul de la taille
        taille_calculee := octet_length(donnees_binaires);
        
        -- Validation de la taille
        IF taille_calculee = 0 THEN
            RAISE EXCEPTION 'Le fichier % est vide', fichier_record->>'nom_fichier';
        END IF;
        
        IF taille_calculee > 10485760 THEN -- 10MB max
            RAISE EXCEPTION 'Le fichier % dépasse la taille maximale de 10MB', 
                fichier_record->>'nom_fichier';
        END IF;
        
        -- Validation du type de fichier
        IF (fichier_record->>'type_fichier') NOT IN ('photo', 'affiche', 'document') THEN
            RAISE EXCEPTION 'Type de fichier invalide: %', fichier_record->>'type_fichier';
        END IF;
        
        -- Insertion du fichier
        INSERT INTO fichier_evenement (
            evenement_id, 
            nom_fichier, 
            type_mime, 
            taille_bytes, 
            type_fichier, 
            donnees_binaire
        )
        VALUES (
            p_evenement_id,
            fichier_record->>'nom_fichier',
            fichier_record->>'type_mime',
            taille_calculee,
            fichier_record->>'type_fichier',
            donnees_binaires
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- ================================================
-- FONCTION PRINCIPALE : Création complète d'événement
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
    total_places_demandees INTEGER := 0;
BEGIN
    -- ÉTAPE 1: Validation des paramètres
    PERFORM valider_parametres_creation(
        p_titre, p_description, p_date_debut, p_date_fin,
        p_type_id, p_tarifs
    );
    
    -- ÉTAPE 2: Vérification capacité
    total_places_demandees := calculer_total_places(p_tarifs);
    
    IF p_lieu_capacite IS NOT NULL AND total_places_demandees > p_lieu_capacite THEN
        RAISE EXCEPTION 
            'Capacité du lieu insuffisante. Places demandées: %, Capacité: %', 
            total_places_demandees, p_lieu_capacite;
    END IF;
    
    -- ÉTAPE 3: Création du lieu
    nouveau_lieu_id := creer_lieu(
        p_lieu_nom, p_lieu_adresse, p_lieu_ville, p_lieu_capacite
    );
    
    -- ÉTAPE 4: Création de l'événement
    nouvel_evenement_id := creer_evenement(
        p_titre, p_description, p_date_debut, p_date_fin,
        p_type_id, nouveau_lieu_id
    );
    
    -- ÉTAPE 5: Création des tarifs (déclenche automatiquement la création des places)
    PERFORM creer_tarifs(nouvel_evenement_id, p_tarifs);
    
    -- ÉTAPE 6: Création des fichiers (optionnel)
    IF p_fichiers IS NOT NULL AND jsonb_array_length(p_fichiers) > 0 THEN
        PERFORM creer_fichiers_bytea(nouvel_evenement_id, p_fichiers);
    END IF;
    
    RETURN nouvel_evenement_id;
END;
$$ LANGUAGE plpgsql;


-- ================================================
-- TRIGGER : Validation création/mise à jour d'événement
-- ================================================
CREATE OR REPLACE FUNCTION valider_nouvel_evenement()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Vérification que la date de début est dans le futur (pour INSERT seulement)
    IF TG_OP = 'INSERT' AND NEW.date_debut <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La date de début doit être dans le futur';
    END IF;
    
    -- 2. Vérification que la date de fin est après la date de début
    IF NEW.date_debut >= NEW.date_fin THEN
        RAISE EXCEPTION 'La date de début doit être avant la date de fin';
    END IF;
    
    -- 3. Vérification des chevauchements de réservation du lieu
    IF EXISTS (
        SELECT 1 FROM evenement e
        WHERE e.lieu_id = NEW.lieu_id
        AND e.id != NEW.id
        AND e.date_debut < NEW.date_fin
        AND e.date_fin > NEW.date_debut
    ) THEN
        RAISE EXCEPTION 'Le lieu est déjà réservé sur cette plage horaire';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_valider_evenement
    BEFORE INSERT OR UPDATE ON evenement
    FOR EACH ROW
    EXECUTE FUNCTION valider_nouvel_evenement();

-- ================================================
-- TRIGGER : Création automatique des places
-- ================================================
CREATE OR REPLACE FUNCTION creer_places_automatiquement()
RETURNS TRIGGER AS $$
DECLARE
    compteur INTEGER := 1;
    numero_place VARCHAR(100);
    nom_type_place VARCHAR(50);
    uuid_evenement TEXT;
BEGIN
    -- Récupérer le nom du type de place et l'UUID de l'événement
    SELECT tp.nom, e.id
    INTO nom_type_place, uuid_evenement
    FROM type_place tp
    JOIN evenement e ON e.id = NEW.evenement_id
    WHERE tp.id = NEW.type_place_id;
    
    -- Vérifier que les données existent
    IF nom_type_place IS NULL OR uuid_evenement IS NULL THEN
        RAISE EXCEPTION 'Type de place ou événement non trouvé';
    END IF;

    -- Création des places avec le format demandé
    WHILE compteur <= NEW.nombre_places LOOP
        -- Format: TypePlace-UUIDEvenement-NuméroAuto
        numero_place := CONCAT(
            UPPER(nom_type_place),
            '-', 
            uuid_evenement,
            '-', 
            LPAD(compteur::TEXT, 3, '0')
        );
        
        -- Insérer la place
        INSERT INTO place (numero, etat_code, tarif_id)
        VALUES (numero_place, 'disponible', NEW.id);
        
        compteur := compteur + 1;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_creer_places
    AFTER INSERT ON tarif
    FOR EACH ROW
    EXECUTE FUNCTION creer_places_automatiquement();

-- ================================================
-- TRIGGER : Audit des changements d'état des places
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
-- FONCTION : Vérification de capacité (version simplifiée)
-- ================================================
CREATE OR REPLACE FUNCTION verifier_capacite_lieu(
    p_lieu_capacite INT,
    p_tarifs JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    total_places_demandees INTEGER := 0;
    tarif_record JSONB;
BEGIN
    -- Si capacité NULL = illimité → toujours valide
    IF p_lieu_capacite IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- Calculer le TOTAL des nouvelles places demandées
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        total_places_demandees := total_places_demandees + 
            COALESCE((tarif_record->>'nombre_places')::INTEGER, 0);
    END LOOP;
    
    -- Vérifier si la capacité est suffisante
    RETURN total_places_demandees <= p_lieu_capacite;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : Génération de numéros de place (optionnelle)
-- ================================================
CREATE OR REPLACE FUNCTION generer_numero_place(
    p_type_place_id UUID, 
    p_numero INTEGER
) RETURNS VARCHAR(50) AS $$
DECLARE
    nom_type VARCHAR(50);
BEGIN
    SELECT nom INTO nom_type FROM type_place WHERE id = p_type_place_id;
    RETURN CONCAT(UPPER(SUBSTRING(nom_type FROM 1 FOR 3)), '-', LPAD(p_numero::TEXT, 3, '0'));
END;
$$ LANGUAGE plpgsql;


-- APRES MODIF /

ALTER TABLE place DROP CONSTRAINT IF EXISTS uq_place_numero_tarif;


CREATE OR REPLACE FUNCTION creer_fichiers_bytea(
    p_evenement_id UUID,
    p_fichiers JSONB
) RETURNS VOID AS $$
DECLARE
    fichier_record JSONB;
    donnees_binaires BYTEA;
    taille_calculee BIGINT;
BEGIN
    FOR fichier_record IN SELECT * FROM jsonb_array_elements(p_fichiers) 
    LOOP
        -- ✅ Conversion directe depuis le JSON (supposant que c'est déjà en hex/bytea)
        -- Si vos données sont encodées d'une manière spécifique dans le JSON
        donnees_binaires := decode(fichier_record->>'donnees_bytea', 'hex');
        
        -- Calcul de la taille
        taille_calculee := octet_length(donnees_binaires);
        
        IF taille_calculee = 0 OR taille_calculee IS NULL THEN
            RAISE EXCEPTION 'Le fichier % est vide ou invalide', fichier_record->>'nom_fichier';
        END IF;
        
        INSERT INTO fichier_evenement (
            evenement_id, nom_fichier, type_mime, taille_bytes, type_fichier, donnees_binaire
        )
        VALUES (
            p_evenement_id,
            fichier_record->>'nom_fichier',
            fichier_record->>'type_mime',
            taille_calculee,
            fichier_record->>'type_fichier',
            donnees_binaires
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;



-- VUE EVENEMENT 

-- ================================================
-- VUE : vue_evenement_complet
-- ================================================
CREATE OR REPLACE VIEW vue_evenement_complet AS
WITH statistiques_places AS (
    SELECT 
        t.id AS tarif_id,
        COUNT(p.id) AS total_places,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'disponible') AS places_disponibles,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue') AS places_vendues,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'reservee') AS places_reservees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'annulee') AS places_annulees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'maintenance') AS places_maintenance
    FROM tarif t
    LEFT JOIN place p ON t.id = p.tarif_id
    GROUP BY t.id
),
statistiques_globales_par_evenement AS (
    SELECT 
        t.evenement_id,
        COUNT(p.id) AS total_places,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'disponible') AS places_disponibles,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue') AS places_vendues,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'reservee') AS places_reservees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'annulee') AS places_annulees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'maintenance') AS places_maintenance,
        CASE 
            WHEN COUNT(p.id) > 0 THEN 
                ROUND((COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue')::DECIMAL / COUNT(p.id)::DECIMAL) * 100, 2)
            ELSE 0 
        END AS taux_occupation
    FROM tarif t
    LEFT JOIN place p ON t.id = p.tarif_id
    GROUP BY t.evenement_id
),
liste_places_par_tarif AS (
    SELECT 
        p.tarif_id,
        jsonb_agg(
            jsonb_build_object(
                'place_id', p.id,
                'numero_place', p.numero,
                'etat', jsonb_build_object(
                    'etat_code', p.etat_code,
                    'etat_description', ep.description
                )
            )
            ORDER BY p.numero
        ) AS liste_places
    FROM place p
    JOIN etat_place ep ON p.etat_code = ep.code
    GROUP BY p.tarif_id
),
fichiers_par_evenement AS (
    SELECT 
        evenement_id,
        jsonb_agg(
            jsonb_build_object(
                'fichier_id', id,
                'nom_fichier', nom_fichier,
                'type_mime', type_mime,
                'taille_bytes', taille_bytes,
                'type_fichier', type_fichier,
                'date_upload', date_upload
            )
            ORDER BY 
                CASE type_fichier
                    WHEN 'affiche' THEN 1
                    WHEN 'photo' THEN 2
                    WHEN 'document' THEN 3
                    ELSE 4
                END,
                nom_fichier
        ) AS fichiers_metadata
    FROM fichier_evenement
    GROUP BY evenement_id
)
SELECT 
    -- Informations de base de l'événement
    e.id AS evenement_id,
    e.titre,
    e.description AS description_evenement,
    e.date_debut,
    e.date_fin,
    
    -- Type d'événement
    te.id AS type_evenement_id,
    te.nom AS type_evenement_nom,
    te.description AS type_evenement_description,
    
    -- Lieu
    l.id AS lieu_id,
    l.nom AS lieu_nom,
    l.adresse AS lieu_adresse,
    l.ville AS lieu_ville,
    l.capacite AS lieu_capacite,
    
    -- Agrégation des tarifs et places par type de place
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'tarif_id', t.id,
                'type_place_id', tp.id,
                'type_place_nom', tp.nom,
                'type_place_description', tp.description,
                'type_place_avantages', tp.avantages,
                'prix', t.prix,
                'nombre_places_total', t.nombre_places,
                'statistiques_etat', jsonb_build_object(
                    'places_disponibles', COALESCE(sp.places_disponibles, 0),
                    'places_vendues', COALESCE(sp.places_vendues, 0),
                    'places_reservees', COALESCE(sp.places_reservees, 0),
                    'places_annulees', COALESCE(sp.places_annulees, 0),
                    'places_maintenance', COALESCE(sp.places_maintenance, 0)
                ),
                'places', COALESCE(lp.liste_places, '[]'::jsonb)
            )
            ORDER BY t.prix DESC
        )
        FROM tarif t
        JOIN type_place tp ON t.type_place_id = tp.id
        LEFT JOIN statistiques_places sp ON t.id = sp.tarif_id
        LEFT JOIN liste_places_par_tarif lp ON t.id = lp.tarif_id
        WHERE t.evenement_id = e.id
    ) AS tarifs_et_places,
    
    -- Statistiques globales des places
    jsonb_build_object(
        'total_places', COALESCE(sg.total_places, 0),
        'places_disponibles', COALESCE(sg.places_disponibles, 0),
        'places_vendues', COALESCE(sg.places_vendues, 0),
        'places_reservees', COALESCE(sg.places_reservees, 0),
        'places_annulees', COALESCE(sg.places_annulees, 0),
        'places_maintenance', COALESCE(sg.places_maintenance, 0),
        'taux_occupation', COALESCE(sg.taux_occupation, 0),
        'capacite_restante', 
            CASE 
                WHEN l.capacite IS NOT NULL THEN 
                    l.capacite - COALESCE(sg.places_vendues, 0) - COALESCE(sg.places_reservees, 0)
                ELSE NULL 
            END,
        'pourcentage_remplissage',
            CASE 
                WHEN l.capacite > 0 THEN 
                    ROUND(((COALESCE(sg.places_vendues, 0) + COALESCE(sg.places_reservees, 0))::DECIMAL / l.capacite::DECIMAL) * 100, 2)
                ELSE 0 
            END
    ) AS statistiques_globales,
    
    -- Fichiers associés
    COALESCE(fe.fichiers_metadata, '[]'::jsonb) AS fichiers_metadata

FROM evenement e
JOIN type_evenement te ON e.type_id = te.id
JOIN lieu l ON e.lieu_id = l.id
LEFT JOIN statistiques_globales_par_evenement sg ON e.id = sg.evenement_id
LEFT JOIN fichiers_par_evenement fe ON e.id = fe.evenement_id;



-- ================================================
-- FONCTION : obtenir_evenement_par_id
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_evenement_par_id(p_evenement_id UUID)
RETURNS JSONB AS $$
DECLARE
    event_data RECORD;
    result JSONB;
    duree_minutes INTEGER;
    jours_restants INTEGER;
    prix_min DECIMAL(10,2);
    prix_max DECIMAL(10,2);
    nombre_types_places INTEGER;
BEGIN
    -- Récupérer les données de base depuis la vue
    SELECT * INTO event_data 
    FROM vue_evenement_complet 
    WHERE evenement_id = p_evenement_id;
    
    -- Vérifier si l'événement existe
    IF event_data IS NULL THEN
        RETURN jsonb_build_object(
            'erreur', true,
            'message', 'Événement non trouvé',
            'evenement_id', p_evenement_id
        );
    END IF;
    
    -- Calculs temporels
    duree_minutes := EXTRACT(EPOCH FROM (event_data.date_fin - event_data.date_debut)) / 60;
    jours_restants := GREATEST(0, EXTRACT(EPOCH FROM (event_data.date_debut - CURRENT_TIMESTAMP)) / 86400)::INTEGER;
    
    -- Calcul des prix min/max et nombre de types de places
    SELECT 
        MIN((tarif->>'prix')::DECIMAL),
        MAX((tarif->>'prix')::DECIMAL),
        COUNT(*)
    INTO prix_min, prix_max, nombre_types_places
    FROM jsonb_array_elements(event_data.tarifs_et_places) AS tarif;
    
    -- Si aucun tarif, valeurs par défaut
    IF prix_min IS NULL THEN
        prix_min := 0;
        prix_max := 0;
        nombre_types_places := 0;
    END IF;
    
    -- Construire le JSON complet et structuré
    result := jsonb_build_object(
        'evenement_id', event_data.evenement_id,
        'titre', event_data.titre,
        'description_evenement', event_data.description_evenement,
        'date_debut', event_data.date_debut,
        'date_fin', event_data.date_fin,
        
        'type_evenement', jsonb_build_object(
            'type_evenement_id', event_data.type_evenement_id,
            'type_evenement_nom', event_data.type_evenement_nom,
            'type_evenement_description', event_data.type_evenement_description
        ),
        
        'lieu', jsonb_build_object(
            'lieu_id', event_data.lieu_id,
            'lieu_nom', event_data.lieu_nom,
            'lieu_adresse', event_data.lieu_adresse,
            'lieu_ville', event_data.lieu_ville,
            'lieu_capacite', event_data.lieu_capacite
        ),
        
        'tarifs_et_places', event_data.tarifs_et_places,
        'statistiques_globales', event_data.statistiques_globales,
        'fichiers', event_data.fichiers_metadata,
        
        'informations_complementaires', jsonb_build_object(
            'duree_evenement_minutes', duree_minutes,
            'jours_restants', jours_restants,
            'est_passe', event_data.date_fin < CURRENT_TIMESTAMP,
            'est_actuel', CURRENT_TIMESTAMP BETWEEN event_data.date_debut AND event_data.date_fin,
            'est_futur', event_data.date_debut > CURRENT_TIMESTAMP,
            'prix_minimum', prix_min,
            'prix_maximum', prix_max,
            'nombre_types_places', nombre_types_places,
            'statut', 
                CASE 
                    WHEN event_data.date_fin < CURRENT_TIMESTAMP THEN 'termine'
                    WHEN CURRENT_TIMESTAMP BETWEEN event_data.date_debut AND event_data.date_fin THEN 'en_cours'
                    ELSE 'a_venir'
                END
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE INDEX idx_place_etat_tarif ON place(etat_code, tarif_id);
CREATE INDEX idx_tarif_evenement_type ON tarif(evenement_id, type_place_id);



--======================RESERVATION ==================



-- public.reservation definition

-- Drop table

-- DROP TABLE public.reservation;

CREATE TABLE public.reservation (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	reference_paiement varchar(100) NULL,
	date_reservation timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	email varchar(255) NOT NULL,
	etat_code varchar(20) DEFAULT 'en_attente'::character varying NOT NULL,
	etat varchar(20) DEFAULT 'en_attente'::character varying NOT NULL,
	CONSTRAINT reservation_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_reservation_reference_paiement ON public.reservation USING btree (reference_paiement);

-- public.reservation_place definition

-- Drop table

-- DROP TABLE public.reservation_place;

CREATE TABLE public.reservation_place (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	reservation_id uuid NOT NULL,
	place_id uuid NOT NULL,
	CONSTRAINT reservation_place_pkey PRIMARY KEY (id),
	CONSTRAINT uq_reservation_place UNIQUE (place_id)
);
CREATE INDEX idx_reservation_place_place ON public.reservation_place USING btree (place_id);
CREATE INDEX idx_reservation_place_reservation ON public.reservation_place USING btree (reservation_id);


-- public.reservation_place foreign keys

ALTER TABLE public.reservation_place ADD CONSTRAINT fk_reservation_place_place FOREIGN KEY (place_id) REFERENCES public.place(id) ON DELETE CASCADE;
ALTER TABLE public.reservation_place ADD CONSTRAINT fk_reservation_place_reservation FOREIGN KEY (reservation_id) REFERENCES public.reservation(id) ON DELETE CASCADE;
-- Ajout de la colonne email si elle n'existe pas
ALTER TABLE reservation ADD COLUMN IF NOT EXISTS email VARCHAR(255) NOT NULL;

-- Ajout de la colonne etat_code si elle n'existe pas
ALTER TABLE reservation ADD COLUMN IF NOT EXISTS etat VARCHAR(20) NOT NULL DEFAULT 'en_attente';


CREATE OR REPLACE FUNCTION reserver_places(
    p_email VARCHAR(255),
    p_evenement_id UUID,
    p_places_demandees JSONB
) RETURNS UUID AS $$
DECLARE
    nouvelle_reservation_id UUID;
    item JSONB;
    v_type_place_id UUID;
    v_nombre_demande INTEGER;
    v_tarif_id UUID;
    place_id UUID;
    compteur INTEGER;
BEGIN
    -- Validation basique
    IF p_email IS NULL OR trim(p_email) = '' THEN
        RAISE EXCEPTION 'Email invalide';
    END IF;
    
    -- Vérifier que l'événement existe
    IF NOT EXISTS (SELECT 1 FROM evenement WHERE id = p_evenement_id) THEN
        RAISE EXCEPTION 'Événement non trouvé';
    END IF;
    
    -- Créer la réservation
    INSERT INTO reservation (email, etat)
    VALUES (p_email, 'en_attente')
    RETURNING id INTO nouvelle_reservation_id;
    
    -- Parcourir chaque type de place demandé dans le JSON
    FOR item IN SELECT * FROM jsonb_array_elements(p_places_demandees)
    LOOP
        v_type_place_id := (item->>'type_place_id')::UUID;
        v_nombre_demande := (item->>'nombre')::INTEGER;
        
        -- Vérifier que le type de place existe
        IF NOT EXISTS (SELECT 1 FROM type_place WHERE id = v_type_place_id) THEN
            RAISE EXCEPTION 'Type de place invalide: %', v_type_place_id;
        END IF;
        
        -- Trouver le tarif
        SELECT id INTO v_tarif_id
        FROM tarif
        WHERE evenement_id = p_evenement_id 
          AND type_place_id = v_type_place_id;
        
        IF v_tarif_id IS NULL THEN
            RAISE EXCEPTION 'Aucun tarif trouvé pour cet événement et type de place %', v_type_place_id;
        END IF;
        
        -- Vérifier qu'il y a assez de places disponibles
        IF (
            SELECT COUNT(*) 
            FROM place 
            WHERE tarif_id = v_tarif_id 
            AND etat_code = 'disponible'
        ) < v_nombre_demande THEN
            RAISE EXCEPTION 'Places insuffisantes pour le type de place % (demandé: %, disponible: %)', 
                v_type_place_id, 
                v_nombre_demande,
                (SELECT COUNT(*) FROM place WHERE tarif_id = v_tarif_id AND etat_code = 'disponible');
        END IF;
        
        -- Réserver les places pour ce type (approche avec CTE pour éviter les conflits)
        WITH places_a_reserver AS (
            SELECT id
            FROM place
            WHERE tarif_id = v_tarif_id
              AND etat_code = 'disponible'
            LIMIT v_nombre_demande
            FOR UPDATE SKIP LOCKED  -- Verrouille les lignes sélectionnées
        ),
        update_places AS (
            UPDATE place
            SET etat_code = 'reservee'
            FROM places_a_reserver
            WHERE place.id = places_a_reserver.id
            RETURNING place.id
        )
        INSERT INTO reservation_place (reservation_id, place_id)
        SELECT nouvelle_reservation_id, id
        FROM update_places;
        
    END LOOP;
    
    RETURN nouvelle_reservation_id;
    
EXCEPTION
    WHEN others THEN
        IF nouvelle_reservation_id IS NOT NULL THEN
            DELETE FROM reservation WHERE id = nouvelle_reservation_id;
        END IF;
        RAISE;
END;
$$ LANGUAGE plpgsql;


-- ================================================
-- FONCTION : obtenir_reservations_evenement
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_reservations_evenement(p_evenement_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'evenement_id', p_evenement_id,
        'evenement_titre', (SELECT titre FROM evenement WHERE id = p_evenement_id),
        'total_reservations', COUNT(DISTINCT vre.reservation_id),
        'reservations', COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'reservation_id', vre.reservation_id,
                    'email', vre.email,
                    'etat_reservation', vre.etat_reservation,
                    'nombre_places_reservees', vre.nombre_places_reservees,
                    'total_reservation', vre.total_reservation,
                    'details_places', vre.details_places
                )
                ORDER BY vre.reservation_id
            ),
            '[]'::jsonb
        )
    )
    INTO result
    FROM vue_reservations_evenement vre
    WHERE vre.evenement_id = p_evenement_id
    GROUP BY vre.evenement_id, vre.evenement_titre;
    

    IF result IS NULL THEN
        result := jsonb_build_object(
            'evenement_id', p_evenement_id,
            'evenement_titre', (SELECT titre FROM evenement WHERE id = p_evenement_id),
            'total_reservations', 0,
            'reservations', '[]'::jsonb
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- VUE : vue_reservations_evenement 
-- ================================================
CREATE OR REPLACE VIEW vue_reservations_evenement AS
WITH reservations_details AS (
    SELECT 
        e.id AS evenement_id,
        e.titre AS evenement_titre,
        r.id AS reservation_id,
        r.email,
        r.etat AS etat_reservation,
        p.id AS place_id,
        p.numero AS numero_place,
        tp.id AS type_place_id,
        tp.nom AS type_place_nom,
        t.prix AS tarif,
        p.etat_code,
        ep.description AS etat_description
    FROM evenement e
    JOIN tarif t ON e.id = t.evenement_id
    JOIN place p ON t.id = p.tarif_id
    JOIN reservation_place rp ON p.id = rp.place_id
    JOIN reservation r ON rp.reservation_id = r.id
    JOIN type_place tp ON t.type_place_id = tp.id
    JOIN etat_place ep ON p.etat_code = ep.code
)
SELECT 
    evenement_id,
    evenement_titre,
    reservation_id,
    email,
    etat_reservation,
    COUNT(place_id) AS nombre_places_reservees,
    SUM(tarif) AS total_reservation,
    
    -- Détails des places réservées
    jsonb_agg(
        jsonb_build_object(
            'place_id', place_id,
            'numero_place', numero_place,
            'type_place_id', type_place_id,
            'type_place_nom', type_place_nom,
            'tarif', tarif,
            'etat_place', jsonb_build_object(
                'code', etat_code,
                'description', etat_description
            )
        )
        ORDER BY type_place_nom, numero_place
    ) AS details_places,
    
    -- Résumé par type de place (sans imbrication d'agrégats)
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'type_place_id', type_place_id,
                'type_place_nom', type_place_nom,
                'nombre_places', nombre_places,
                'prix_unitaire', prix_unitaire,
                'sous_total', sous_total
            )
        )
        FROM (
            SELECT 
                type_place_id,
                type_place_nom,
                COUNT(*) AS nombre_places,
                AVG(tarif) AS prix_unitaire,
                SUM(tarif) AS sous_total
            FROM reservations_details rd2
            WHERE rd2.reservation_id = rd1.reservation_id
            GROUP BY type_place_id, type_place_nom
        ) AS resume
    ) AS resume_par_type

FROM reservations_details rd1
GROUP BY 
    evenement_id, evenement_titre,
    reservation_id, email, etat_reservation;


    -- ================================================
-- FONCTION : obtenir_details_reservation_par_id
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_details_reservation_par_id(p_reservation_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH reservation_details AS (
        SELECT 
            -- Informations de la réservation
            r.id AS reservation_id,
            r.email,
            r.date_reservation,
            r.etat AS etat_reservation,
            
            -- Informations de l'événement
            e.titre AS evenement_nom,
            l.nom AS lieu_nom,
            e.date_debut,
            e.date_fin,
            
            -- Agrégation des places et prix
            COUNT(p.id) AS nombre_places,
            ARRAY_AGG(p.numero ORDER BY p.numero) AS numeros_places,
            ARRAY_AGG(DISTINCT t.prix) AS prix_places,
            SUM(t.prix) AS total_reservation
            
        FROM reservation r
        JOIN reservation_place rp ON r.id = rp.reservation_id
        JOIN place p ON rp.place_id = p.id
        JOIN tarif t ON p.tarif_id = t.id
        JOIN evenement e ON t.evenement_id = e.id
        JOIN lieu l ON e.lieu_id = l.id
        
        WHERE r.id = p_reservation_id
        GROUP BY 
            r.id, r.email, r.date_reservation, r.etat,
            e.titre, l.nom, e.date_debut, e.date_fin
    )
    SELECT 
        jsonb_build_object(
            'reservation_id', rd.reservation_id,
            'email', rd.email,
            'date_reservation', rd.date_reservation,
            'etat_reservation', rd.etat_reservation,
            'evenement', jsonb_build_object(
                'nom', rd.evenement_nom,
                'lieu', rd.lieu_nom,
                'date_debut', rd.date_debut,
                'date_fin', rd.date_fin
            ),
            'details_places', jsonb_build_object(
                'nombre_places', rd.nombre_places,
                'numeros_places', rd.numeros_places,
                'prix_par_place', rd.prix_places,
                'total_reservation', rd.total_reservation
            )
        )
    INTO result
    FROM reservation_details rd;
    
    -- Si aucune réservation trouvée
    IF result IS NULL THEN
        result := jsonb_build_object(
            'erreur', true,
            'message', 'Réservation non trouvée',
            'reservation_id', p_reservation_id
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;



------------------------------------GET EVENTS



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


CREATE OR REPLACE FUNCTION obtenir_reservation_par_id(p_reservation_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'reservation_id', r.id,
        'email', r.email,
        'date_reservation', to_char(r.date_reservation, 'YYYY-MM-DD"T"HH24:MI:SS'),
        'etat', r.etat,
        'evenement', jsonb_build_object(
            'id', e.id,
            'titre', e.titre,
            'description', e.description,
            'date_debut', to_char(e.date_debut, 'YYYY-MM-DD"T"HH24:MI:SS'),
            'date_fin', to_char(e.date_fin, 'YYYY-MM-DD"T"HH24:MI:SS'),
            'type_evenement', jsonb_build_object(
                'id', te.id,
                'nom', te.nom
            ),
            'lieu', jsonb_build_object(
                'id', l.id,
                'nom', l.nom,
                'ville', l.ville
            )
        ),
        'places', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'place_id', p.id,
                    'numero', p.numero,
                    'tarif', t.prix,
                    'type_place', jsonb_build_object(
                        'id', tp.id,
                        'nom', tp.nom
                    )
                )
            )
            FROM reservation_place rp
            JOIN place p ON rp.place_id = p.id
            JOIN tarif t ON p.tarif_id = t.id
            JOIN type_place tp ON t.type_place_id = tp.id
            WHERE rp.reservation_id = r.id
        ),
        'total', (
            SELECT SUM(t.prix)
            FROM reservation_place rp
            JOIN place p ON rp.place_id = p.id
            JOIN tarif t ON p.tarif_id = t.id
            WHERE rp.reservation_id = r.id
        )
    )
    INTO result
    FROM reservation r
    JOIN reservation_place rp ON r.id = rp.reservation_id
    JOIN place p ON rp.place_id = p.id
    JOIN tarif t ON p.tarif_id = t.id
    JOIN evenement e ON t.evenement_id = e.id
    JOIN type_evenement te ON e.type_id = te.id
    JOIN lieu l ON e.lieu_id = l.id
    WHERE r.id = p_reservation_id
    GROUP BY r.id, e.id, te.id, l.id;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION obtenir_tous_types_places()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'nom', nom,
            'description', description,
            'avantages', avantages
        )
        ORDER BY nom
    )
    INTO result
    FROM type_place;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION obtenir_tous_types_evenements()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'nom', nom,
            'description', description
        )
        ORDER BY nom
    )
    INTO result
    FROM type_evenement;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION obtenir_reservation_par_id(p_reservation_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'reservation_id', r.id,
        'email', r.email,
        'reference_paiement', r.reference_paiement,
        'date_reservation', to_char(r.date_reservation, 'YYYY-MM-DD"T"HH24:MI:SS'),
        'etat', r.etat,
        'etat_code', r.etat_code,
        'evenement', jsonb_build_object(
            'id', e.id,
            'titre', e.titre,
            'description', e.description,
            'date_debut', to_char(e.date_debut, 'YYYY-MM-DD"T"HH24:MI:SS'),
            'date_fin', to_char(e.date_fin, 'YYYY-MM-DD"T"HH24:MI:SS'),
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
            )
        ),
        'places', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'place_id', p.id,
                    'numero', p.numero,
                    'etat_code', p.etat_code,
                    'etat_description', ep.description,
                    'tarif', jsonb_build_object(
                        'id', t.id,
                        'prix', t.prix,
                        'type_place', jsonb_build_object(
                            'id', tp.id,
                            'nom', tp.nom,
                            'description', tp.description,
                            'avantages', tp.avantages
                        )
                    )
                )
                ORDER BY p.numero
            )
            FROM reservation_place rp
            JOIN place p ON rp.place_id = p.id
            JOIN tarif t ON p.tarif_id = t.id
            JOIN type_place tp ON t.type_place_id = tp.id
            JOIN etat_place ep ON p.etat_code = ep.code
            WHERE rp.reservation_id = r.id
        ),
        'total', (
            SELECT SUM(t.prix)
            FROM reservation_place rp
            JOIN place p ON rp.place_id = p.id
            JOIN tarif t ON p.tarif_id = t.id
            WHERE rp.reservation_id = r.id
        ),
        'nombre_places', (
            SELECT COUNT(*)
            FROM reservation_place rp
            WHERE rp.reservation_id = r.id
        )
    )
    INTO result
    FROM reservation r
    JOIN reservation_place rp ON r.id = rp.reservation_id
    JOIN place p ON rp.place_id = p.id
    JOIN tarif t ON p.tarif_id = t.id
    JOIN evenement e ON t.evenement_id = e.id
    JOIN type_evenement te ON e.type_id = te.id
    JOIN lieu l ON e.lieu_id = l.id
    WHERE r.id = p_reservation_id
    GROUP BY r.id, e.id, te.id, l.id;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;


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

================================================
-- FONCTION : obtenir_evenement_par_id (AVEC DONNÉES BINAIRES)
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_evenement_par_id(p_evenement_id UUID)
RETURNS JSONB AS $$
DECLARE
    event_data RECORD;
    result JSONB;
    duree_minutes INTEGER;
    jours_restants INTEGER;
    prix_min DECIMAL(10,2);
    prix_max DECIMAL(10,2);
    nombre_types_places INTEGER;
    fichiers_avec_donnees JSONB;
    nombre_fichiers INTEGER;
    a_affiche BOOLEAN;
    a_photos BOOLEAN;
BEGIN
    -- Récupérer les données de base depuis la vue
    SELECT * INTO event_data 
    FROM vue_evenement_complet 
    WHERE evenement_id = p_evenement_id;
    
    -- Vérifier si l'événement existe
    IF event_data IS NULL THEN
        RETURN jsonb_build_object(
            'erreur', true,
            'message', 'Événement non trouvé',
            'evenement_id', p_evenement_id
        );
    END IF;
    
    -- Compter les fichiers et vérifier la présence d'affiche et de photos
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE type_fichier = 'affiche') > 0,
        COUNT(*) FILTER (WHERE type_fichier = 'photo') > 0
    INTO nombre_fichiers, a_affiche, a_photos
    FROM fichier_evenement 
    WHERE evenement_id = p_evenement_id;
    
    -- Récupérer les fichiers avec leurs données binaires encodées en base64
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'fichier_id', fe.id,
                'nom_fichier', fe.nom_fichier,
                'type_mime', fe.type_mime,
                'taille_bytes', fe.taille_bytes,
                'type_fichier', fe.type_fichier,
                'date_upload', fe.date_upload,
                'donnees_binaire_base64', encode(fe.donnees_binaire, 'base64'),
                'url_data', CASE 
                    WHEN fe.type_mime LIKE 'image/%' THEN 
                        'data:' || fe.type_mime || ';base64,' || encode(fe.donnees_binaire, 'base64')
                    ELSE NULL
                END
            )
            ORDER BY 
                CASE fe.type_fichier
                    WHEN 'affiche' THEN 1
                    WHEN 'photo' THEN 2
                    WHEN 'document' THEN 3
                    ELSE 4
                END,
                fe.nom_fichier
        ),
        '[]'::jsonb
    ) INTO fichiers_avec_donnees
    FROM fichier_evenement fe
    WHERE fe.evenement_id = p_evenement_id;
    
    -- Calculs temporels
    duree_minutes := EXTRACT(EPOCH FROM (event_data.date_fin - event_data.date_debut)) / 60;
    jours_restants := GREATEST(0, EXTRACT(EPOCH FROM (event_data.date_debut - CURRENT_TIMESTAMP)) / 86400)::INTEGER;
    
    -- Calcul des prix min/max et nombre de types de places
    SELECT 
        MIN((tarif->>'prix')::DECIMAL),
        MAX((tarif->>'prix')::DECIMAL),
        COUNT(*)
    INTO prix_min, prix_max, nombre_types_places
    FROM jsonb_array_elements(event_data.tarifs_et_places) AS tarif;
    
    -- Si aucun tarif, valeurs par défaut
    IF prix_min IS NULL THEN
        prix_min := 0;
        prix_max := 0;
        nombre_types_places := 0;
    END IF;
    
    -- Construire le JSON complet et structuré
    result := jsonb_build_object(
        'evenement_id', event_data.evenement_id,
        'titre', event_data.titre,
        'description_evenement', event_data.description_evenement,
        'date_debut', event_data.date_debut,
        'date_fin', event_data.date_fin,
        
        'type_evenement', jsonb_build_object(
            'type_evenement_id', event_data.type_evenement_id,
            'type_evenement_nom', event_data.type_evenement_nom,
            'type_evenement_description', event_data.type_evenement_description
        ),
        
        'lieu', jsonb_build_object(
            'lieu_id', event_data.lieu_id,
            'lieu_nom', event_data.lieu_nom,
            'lieu_adresse', event_data.lieu_adresse,
            'lieu_ville', event_data.lieu_ville,
            'lieu_capacite', event_data.lieu_capacite
        ),
        
        'tarifs_et_places', event_data.tarifs_et_places,
        'statistiques_globales', event_data.statistiques_globales,
        
        -- Fichiers avec données binaires encodées
        'fichiers', fichiers_avec_donnees,
        
        'informations_complementaires', jsonb_build_object(
            'duree_evenement_minutes', duree_minutes,
            'jours_restants', jours_restants,
            'est_passe', event_data.date_fin < CURRENT_TIMESTAMP,
            'est_actuel', CURRENT_TIMESTAMP BETWEEN event_data.date_debut AND event_data.date_fin,
            'est_futur', event_data.date_debut > CURRENT_TIMESTAMP,
            'prix_minimum', prix_min,
            'prix_maximum', prix_max,
            'nombre_types_places', nombre_types_places,
            'statut', 
                CASE 
                    WHEN event_data.date_fin < CURRENT_TIMESTAMP THEN 'termine'
                    WHEN CURRENT_TIMESTAMP BETWEEN event_data.date_debut AND event_data.date_fin THEN 'en_cours'
                    ELSE 'a_venir'
                END,
            -- Nouvelles informations sur les fichiers
            'nombre_fichiers', nombre_fichiers,
            'a_affiche', a_affiche,
            'a_photos', a_photos
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;



