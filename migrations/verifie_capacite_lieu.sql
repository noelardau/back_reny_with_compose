-- ================================================
-- FONCTION : Vérification de capacité (NOUVELLES PLACES SEULEMENT)
-- ================================================
CREATE OR REPLACE FUNCTION verifier_capacite_lieu(
    p_lieu_capacite INT,           -- Capacité directe du lieu
    p_tarifs JSONB                 -- JSON avec tous les types de places
) RETURNS BOOLEAN AS $$
DECLARE
    total_places_demandees INTEGER := 0;
    tarif_record JSONB;
BEGIN
    -- 1. Si capacité NULL = illimité → toujours valide
    IF p_lieu_capacite IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- 2. Calculer le TOTAL des nouvelles places demandées
    FOR tarif_record IN SELECT * FROM jsonb_array_elements(p_tarifs) 
    LOOP
        total_places_demandees := total_places_demandees + 
            COALESCE((tarif_record->>'nombre_places')::INTEGER, 0);
    END LOOP;
    
    -- 3. Vérifier si la capacité est suffisante
    IF total_places_demandees > p_lieu_capacite THEN
        RAISE NOTICE 'Capacité insuffisante. Places demandées: %, Capacité du lieu: %', 
            total_places_demandees, p_lieu_capacite;
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;