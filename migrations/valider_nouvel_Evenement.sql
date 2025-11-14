-- ================================================
-- TRIGGER : Validation création/mise à jour d'événement
-- ================================================
CREATE OR REPLACE FUNCTION valider_nouvel_evenement()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Vérification que la date de début est dans le futur (pour INSERT seulement)
    -- Pour UPDATE, on permet de modifier les événements passés (pour corrections)
    IF TG_OP = 'INSERT' AND NEW.date_debut <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La date de début doit être dans le futur';
    END IF;
    
    -- 2. Vérification que la date de fin est après la date de début
    IF NEW.date_debut >= NEW.date_fin THEN
        RAISE EXCEPTION 'La date de début doit être avant la date de fin';
    END IF;
    
    -- 3. Vérification des chevauchements de réservation du lieu
    -- Exclut l'événement courant pour les UPDATE
    IF EXISTS (
        SELECT 1 FROM evenement e
        WHERE e.lieu_id = NEW.lieu_id
        AND e.id != NEW.id  -- Exclut l'événement en cours de modification
        AND e.date_debut < NEW.date_fin
        AND e.date_fin > NEW.date_debut
    ) THEN
        RAISE EXCEPTION 'Le lieu est déjà réservé sur cette plage horaire';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recréation du trigger pour INSERT et UPDATE
DROP TRIGGER IF EXISTS trigger_valider_evenement ON evenement;
CREATE TRIGGER trigger_valider_evenement
    BEFORE INSERT OR UPDATE ON evenement
    FOR EACH ROW
    EXECUTE FUNCTION valider_nouvel_evenement();