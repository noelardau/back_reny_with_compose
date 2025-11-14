-- ================================================
-- TRIGGER : Création automatique des places (VERSION FINALE)
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