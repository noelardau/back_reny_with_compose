-- ================================================
-- TRIGGERS
-- ================================================

-- Validation événement
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

-- Création automatique des places
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

-- Audit des changements d'état des places
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