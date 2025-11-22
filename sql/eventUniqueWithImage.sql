-- ================================================
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