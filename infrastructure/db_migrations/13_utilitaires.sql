-- ================================================
-- FONCTIONS UTILITAIRES : Gestion hexadécimale
-- ================================================

-- Convertir un fichier en hexadécimal pour affichage
CREATE OR REPLACE FUNCTION fichier_vers_hex(p_fichier_id UUID)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    SELECT encode(donnees_binaire, 'hex')
    INTO result
    FROM fichier_evenement
    WHERE id = p_fichier_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Vérifier si une chaîne est un hexadécimal valide
CREATE OR REPLACE FUNCTION est_hexadecimal_valide(p_donnees TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_donnees ~ '^[0-9a-fA-F]*$' AND length(p_donnees) % 2 = 0;
END;
$$ LANGUAGE plpgsql;

-- Calculer la taille d'un fichier à partir de l'hexadécimal
CREATE OR REPLACE FUNCTION calculer_taille_hex(p_donnees_hex TEXT)
RETURNS BIGINT AS $$
BEGIN
    IF NOT est_hexadecimal_valide(p_donnees_hex) THEN
        RETURN 0;
    END IF;
    
    RETURN length(p_donnees_hex) / 2;
END;
$$ LANGUAGE plpgsql;