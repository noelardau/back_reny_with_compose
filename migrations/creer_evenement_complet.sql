

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
            UPPER(nom_type_place),           -- Type de place en majuscule
            '-', 
            uuid_evenement,                  -- UUID complet de l'événement
            '-', 
            LPAD(compteur::TEXT, 3, '0')    -- Numéro auto sur 3 chiffres
        );
        
        -- Insérer la place
        INSERT INTO place (numero, etat_code, tarif_id)
        VALUES (numero_place, 'disponible', NEW.id);
        
        compteur := compteur + 1;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger
DROP TRIGGER IF EXISTS trigger_creer_places ON tarif;
CREATE TRIGGER trigger_creer_places
    AFTER INSERT ON tarif
    FOR EACH ROW
    EXECUTE FUNCTION creer_places_automatiquement();

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
    -- ✅ TOUT SE PASSE DANS UNE SEULE TRANSACTION IMPLICITE
    -- En cas d'erreur, PostgreSQL rollback tout automatiquement
    
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
        PERFORM creer_fichiers(nouvel_evenement_id, p_fichiers);
    END IF;
    
    -- ✅ RETOUR DE L'ID SI TOUT EST RÉUSSI
    RETURN nouvel_evenement_id;
    
    -- ❌ EN CAS D'ERREUR, POSTGRESQL FAIT UN ROLLBACK AUTOMATIQUE
END;
$$ LANGUAGE plpgsql;