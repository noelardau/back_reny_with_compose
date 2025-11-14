-- ================================================
-- FONCTIONS : Validation
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