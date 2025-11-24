
-- ================================================
-- FONCTION : reserver_places (VERSION CORRIGÉE)
-- ================================================
CREATE OR REPLACE FUNCTION reserver_places(
    p_email VARCHAR(255),
    p_evenement_id UUID,
    p_places_demandees JSONB,
    p_reference_paiement VARCHAR(100) DEFAULT NULL  -- Nouveau paramètre
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
    
    -- Créer la réservation AVEC la référence de paiement
    INSERT INTO reservation (email, etat, reference_paiement)
    VALUES (p_email, 'en_attente', p_reference_paiement)
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