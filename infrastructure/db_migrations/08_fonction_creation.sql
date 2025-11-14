

-- ================================================
-- FONCTIONS : Création
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
-- FONCTION : Création des fichiers pour un événement (VERSION HEXADÉCIMALE)
-- ================================================
CREATE OR REPLACE FUNCTION creer_fichiers_bytea(
    p_evenement_id UUID,
    p_fichiers JSONB
) RETURNS VOID AS $$
DECLARE
    fichier_record JSONB;
    donnees_binaires BYTEA;
    taille_calculee BIGINT;
    donnees_hex TEXT;
BEGIN
    FOR fichier_record IN SELECT * FROM jsonb_array_elements(p_fichiers) 
    LOOP
        -- Récupération des données hexadécimales depuis le JSON
        donnees_hex := fichier_record->>'donnees_hex';
        
        -- Validation des données hexadécimales
        IF donnees_hex IS NULL OR trim(donnees_hex) = '' THEN
            RAISE EXCEPTION 'Les données hexadécimales sont vides pour le fichier: %', 
                fichier_record->>'nom_fichier';
        END IF;
        
        -- Vérification du format hexadécimal (caractères valides: 0-9, a-f, A-F)
        IF NOT donnees_hex ~ '^[0-9a-fA-F]*$' THEN
            RAISE EXCEPTION 'Format hexadécimal invalide pour le fichier: %', 
                fichier_record->>'nom_fichier';
        END IF;
        
        -- Vérification que la longueur est paire (format hexadécimal valide)
        IF length(donnees_hex) % 2 != 0 THEN
            RAISE EXCEPTION 'Longueur hexadécimale invalide (doit être paire) pour le fichier: %', 
                fichier_record->>'nom_fichier';
        END IF;
        
        -- Conversion hexadécimal vers BYTEA
        BEGIN
            donnees_binaires := decode(donnees_hex, 'hex');
        EXCEPTION
            WHEN others THEN
                RAISE EXCEPTION 'Conversion hexadécimale échouée pour le fichier: %', 
                    fichier_record->>'nom_fichier';
        END;
        
        -- Calcul de la taille
        taille_calculee := octet_length(donnees_binaires);
        
        IF taille_calculee = 0 OR taille_calculee IS NULL THEN
            RAISE EXCEPTION 'Le fichier % est vide ou invalide', fichier_record->>'nom_fichier';
        END IF;
        
        -- Validation de la taille maximale (10MB)
        IF taille_calculee > 10485760 THEN
            RAISE EXCEPTION 'Le fichier % dépasse la taille maximale de 10MB. Taille: % bytes', 
                fichier_record->>'nom_fichier', taille_calculee;
        END IF;
        
        -- Validation du type de fichier
        IF (fichier_record->>'type_fichier') NOT IN ('photo', 'affiche', 'document') THEN
            RAISE EXCEPTION 'Type de fichier invalide: %. Types autorisés: photo, affiche, document', 
                fichier_record->>'type_fichier';
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
-- FONCTION PRINCIPALE : Création complète d'événement (MISE À JOUR)
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
    
    -- ÉTAPE 6: Création des fichiers (optionnel) - APPEL CORRIGÉ
    IF p_fichiers IS NOT NULL AND jsonb_array_length(p_fichiers) > 0 THEN
        PERFORM creer_fichiers_bytea(nouvel_evenement_id, p_fichiers);
    END IF;
    
    RETURN nouvel_evenement_id;
END;
$$ LANGUAGE plpgsql;