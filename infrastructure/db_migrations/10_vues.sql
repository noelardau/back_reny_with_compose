-- ================================================
-- VUES
-- ================================================

CREATE OR REPLACE VIEW vue_evenement_complet AS
WITH statistiques_places AS (
    SELECT 
        t.id AS tarif_id,
        COUNT(p.id) AS total_places,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'disponible') AS places_disponibles,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue') AS places_vendues,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'reservee') AS places_reservees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'annulee') AS places_annulees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'maintenance') AS places_maintenance
    FROM tarif t
    LEFT JOIN place p ON t.id = p.tarif_id
    GROUP BY t.id
),
statistiques_globales_par_evenement AS (
    SELECT 
        t.evenement_id,
        COUNT(p.id) AS total_places,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'disponible') AS places_disponibles,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue') AS places_vendues,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'reservee') AS places_reservees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'annulee') AS places_annulees,
        COUNT(p.id) FILTER (WHERE p.etat_code = 'maintenance') AS places_maintenance,
        CASE 
            WHEN COUNT(p.id) > 0 THEN 
                ROUND((COUNT(p.id) FILTER (WHERE p.etat_code = 'vendue')::DECIMAL / COUNT(p.id)::DECIMAL) * 100, 2)
            ELSE 0 
        END AS taux_occupation
    FROM tarif t
    LEFT JOIN place p ON t.id = p.tarif_id
    GROUP BY t.evenement_id
),
liste_places_par_tarif AS (
    SELECT 
        p.tarif_id,
        jsonb_agg(
            jsonb_build_object(
                'place_id', p.id,
                'numero_place', p.numero,
                'etat', jsonb_build_object(
                    'etat_code', p.etat_code,
                    'etat_description', ep.description
                )
            )
            ORDER BY p.numero
        ) AS liste_places
    FROM place p
    JOIN etat_place ep ON p.etat_code = ep.code
    GROUP BY p.tarif_id
),
fichiers_par_evenement AS (
    SELECT 
        evenement_id,
        jsonb_agg(
            jsonb_build_object(
                'fichier_id', id,
                'nom_fichier', nom_fichier,
                'type_mime', type_mime,
                'taille_bytes', taille_bytes,
                'type_fichier', type_fichier,
                'date_upload', date_upload
            )
            ORDER BY 
                CASE type_fichier
                    WHEN 'affiche' THEN 1
                    WHEN 'photo' THEN 2
                    WHEN 'document' THEN 3
                    ELSE 4
                END,
                nom_fichier
        ) AS fichiers_metadata
    FROM fichier_evenement
    GROUP BY evenement_id
)
SELECT 
    -- Informations de base de l'événement
    e.id AS evenement_id,
    e.titre,
    e.description AS description_evenement,
    e.date_debut,
    e.date_fin,
    
    -- Type d'événement
    te.id AS type_evenement_id,
    te.nom AS type_evenement_nom,
    te.description AS type_evenement_description,
    
    -- Lieu
    l.id AS lieu_id,
    l.nom AS lieu_nom,
    l.adresse AS lieu_adresse,
    l.ville AS lieu_ville,
    l.capacite AS lieu_capacite,
    
    -- Agrégation des tarifs et places par type de place
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'tarif_id', t.id,
                'type_place_id', tp.id,
                'type_place_nom', tp.nom,
                'type_place_description', tp.description,
                'type_place_avantages', tp.avantages,
                'prix', t.prix,
                'nombre_places_total', t.nombre_places,
                'statistiques_etat', jsonb_build_object(
                    'places_disponibles', COALESCE(sp.places_disponibles, 0),
                    'places_vendues', COALESCE(sp.places_vendues, 0),
                    'places_reservees', COALESCE(sp.places_reservees, 0),
                    'places_annulees', COALESCE(sp.places_annulees, 0),
                    'places_maintenance', COALESCE(sp.places_maintenance, 0)
                ),
                'places', COALESCE(lp.liste_places, '[]'::jsonb)
            )
            ORDER BY t.prix DESC
        )
        FROM tarif t
        JOIN type_place tp ON t.type_place_id = tp.id
        LEFT JOIN statistiques_places sp ON t.id = sp.tarif_id
        LEFT JOIN liste_places_par_tarif lp ON t.id = lp.tarif_id
        WHERE t.evenement_id = e.id
    ) AS tarifs_et_places,
    
    -- Statistiques globales des places
    jsonb_build_object(
        'total_places', COALESCE(sg.total_places, 0),
        'places_disponibles', COALESCE(sg.places_disponibles, 0),
        'places_vendues', COALESCE(sg.places_vendues, 0),
        'places_reservees', COALESCE(sg.places_reservees, 0),
        'places_annulees', COALESCE(sg.places_annulees, 0),
        'places_maintenance', COALESCE(sg.places_maintenance, 0),
        'taux_occupation', COALESCE(sg.taux_occupation, 0),
        'capacite_restante', 
            CASE 
                WHEN l.capacite IS NOT NULL THEN 
                    l.capacite - COALESCE(sg.places_vendues, 0) - COALESCE(sg.places_reservees, 0)
                ELSE NULL 
            END,
        'pourcentage_remplissage',
            CASE 
                WHEN l.capacite > 0 THEN 
                    ROUND(((COALESCE(sg.places_vendues, 0) + COALESCE(sg.places_reservees, 0))::DECIMAL / l.capacite::DECIMAL) * 100, 2)
                ELSE 0 
            END
    ) AS statistiques_globales,
    
    -- Fichiers associés
    COALESCE(fe.fichiers_metadata, '[]'::jsonb) AS fichiers_metadata

FROM evenement e
JOIN type_evenement te ON e.type_id = te.id
JOIN lieu l ON e.lieu_id = l.id
LEFT JOIN statistiques_globales_par_evenement sg ON e.id = sg.evenement_id
LEFT JOIN fichiers_par_evenement fe ON e.id = fe.evenement_id;

-- ================================================
-- FONCTION : obtenir_evenement_par_id
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
        'fichiers', event_data.fichiers_metadata,
        
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
                END
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- VUE : vue_reservations_evenement 
-- ================================================
CREATE OR REPLACE VIEW vue_reservations_evenement AS
WITH reservations_details AS (
    SELECT 
        e.id AS evenement_id,
        e.titre AS evenement_titre,
        r.id AS reservation_id,
        r.email,
        r.etat AS etat_reservation,
        p.id AS place_id,
        p.numero AS numero_place,
        tp.id AS type_place_id,
        tp.nom AS type_place_nom,
        t.prix AS tarif,
        p.etat_code,
        ep.description AS etat_description
    FROM evenement e
    JOIN tarif t ON e.id = t.evenement_id
    JOIN place p ON t.id = p.tarif_id
    JOIN reservation_place rp ON p.id = rp.place_id
    JOIN reservation r ON rp.reservation_id = r.id
    JOIN type_place tp ON t.type_place_id = tp.id
    JOIN etat_place ep ON p.etat_code = ep.code
)
SELECT 
    evenement_id,
    evenement_titre,
    reservation_id,
    email,
    etat_reservation,
    COUNT(place_id) AS nombre_places_reservees,
    SUM(tarif) AS total_reservation,
    
    -- Détails des places réservées
    jsonb_agg(
        jsonb_build_object(
            'place_id', place_id,
            'numero_place', numero_place,
            'type_place_id', type_place_id,
            'type_place_nom', type_place_nom,
            'tarif', tarif,
            'etat_place', jsonb_build_object(
                'code', etat_code,
                'description', etat_description
            )
        )
        ORDER BY type_place_nom, numero_place
    ) AS details_places,
    
    -- Résumé par type de place (sans imbrication d'agrégats)
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'type_place_id', type_place_id,
                'type_place_nom', type_place_nom,
                'nombre_places', nombre_places,
                'prix_unitaire', prix_unitaire,
                'sous_total', sous_total
            )
        )
        FROM (
            SELECT 
                type_place_id,
                type_place_nom,
                COUNT(*) AS nombre_places,
                AVG(tarif) AS prix_unitaire,
                SUM(tarif) AS sous_total
            FROM reservations_details rd2
            WHERE rd2.reservation_id = rd1.reservation_id
            GROUP BY type_place_id, type_place_nom
        ) AS resume
    ) AS resume_par_type

FROM reservations_details rd1
GROUP BY 
    evenement_id, evenement_titre,
    reservation_id, email, etat_reservation;

-- ================================================
-- FONCTION : obtenir_reservations_evenement
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_reservations_evenement(p_evenement_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'evenement_id', p_evenement_id,
        'evenement_titre', (SELECT titre FROM evenement WHERE id = p_evenement_id),
        'total_reservations', COUNT(DISTINCT vre.reservation_id),
        'reservations', COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'reservation_id', vre.reservation_id,
                    'email', vre.email,
                    'etat_reservation', vre.etat_reservation,
                    'nombre_places_reservees', vre.nombre_places_reservees,
                    'total_reservation', vre.total_reservation,
                    'details_places', vre.details_places
                )
                ORDER BY vre.reservation_id
            ),
            '[]'::jsonb
        )
    )
    INTO result
    FROM vue_reservations_evenement vre
    WHERE vre.evenement_id = p_evenement_id
    GROUP BY vre.evenement_id, vre.evenement_titre;
    

    IF result IS NULL THEN
        result := jsonb_build_object(
            'evenement_id', p_evenement_id,
            'evenement_titre', (SELECT titre FROM evenement WHERE id = p_evenement_id),
            'total_reservations', 0,
            'reservations', '[]'::jsonb
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FONCTION : obtenir_details_reservation_par_id
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_details_reservation_par_id(p_reservation_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH reservation_details AS (
        SELECT 
            -- Informations de la réservation
            r.id AS reservation_id,
            r.email,
            r.date_reservation,
            r.etat AS etat_reservation,
            
            -- Informations de l'événement
            e.titre AS evenement_nom,
            l.nom AS lieu_nom,
            e.date_debut,
            e.date_fin,
            
            -- Agrégation des places et prix
            COUNT(p.id) AS nombre_places,
            ARRAY_AGG(p.numero ORDER BY p.numero) AS numeros_places,
            ARRAY_AGG(DISTINCT t.prix) AS prix_places,
            SUM(t.prix) AS total_reservation
            
        FROM reservation r
        JOIN reservation_place rp ON r.id = rp.reservation_id
        JOIN place p ON rp.place_id = p.id
        JOIN tarif t ON p.tarif_id = t.id
        JOIN evenement e ON t.evenement_id = e.id
        JOIN lieu l ON e.lieu_id = l.id
        
        WHERE r.id = p_reservation_id
        GROUP BY 
            r.id, r.email, r.date_reservation, r.etat,
            e.titre, l.nom, e.date_debut, e.date_fin
    )
    SELECT 
        jsonb_build_object(
            'reservation_id', rd.reservation_id,
            'email', rd.email,
            'date_reservation', rd.date_reservation,
            'etat_reservation', rd.etat_reservation,
            'evenement', jsonb_build_object(
                'nom', rd.evenement_nom,
                'lieu', rd.lieu_nom,
                'date_debut', rd.date_debut,
                'date_fin', rd.date_fin
            ),
            'details_places', jsonb_build_object(
                'nombre_places', rd.nombre_places,
                'numeros_places', rd.numeros_places,
                'prix_par_place', rd.prix_places,
                'total_reservation', rd.total_reservation
            )
        )
    INTO result
    FROM reservation_details rd;
    
    -- Si aucune réservation trouvée
    IF result IS NULL THEN
        result := jsonb_build_object(
            'erreur', true,
            'message', 'Réservation non trouvée',
            'reservation_id', p_reservation_id
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;


-- ================================================
-- FONCTION UTILITAIRE : Récupérer les fichiers en hexadécimal
-- ================================================
CREATE OR REPLACE FUNCTION obtenir_fichiers_hex(p_evenement_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'fichier_id', id,
            'nom_fichier', nom_fichier,
            'type_mime', type_mime,
            'taille_bytes', taille_bytes,
            'type_fichier', type_fichier,
            'date_upload', date_upload,
            'donnees_hex', encode(donnees_binaire, 'hex')
        )
        ORDER BY 
            CASE type_fichier
                WHEN 'affiche' THEN 1
                WHEN 'photo' THEN 2
                WHEN 'document' THEN 3
                ELSE 4
            END,
            nom_fichier
    )
    INTO result
    FROM fichier_evenement
    WHERE evenement_id = p_evenement_id;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;