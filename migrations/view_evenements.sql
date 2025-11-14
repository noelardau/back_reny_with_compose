CREATE OR REPLACE VIEW vue_evenement_complet AS
SELECT 
    e.id as evenement_id,
    e.titre,
    e.description as description_evenement,
    e.date_debut,
    e.date_fin,
    
    -- Type d'événement (format JSON)
    json_build_object(
        'id', te.id,
        'nom', te.nom,
        'description', te.description
    ) as type_evenement,
    
    -- Lieu (format JSON)
    json_build_object(
        'id', l.id,
        'nom', l.nom,
        'adresse', l.adresse,
        'ville', l.ville,
        'capacite', l.capacite
    ) as lieu,
    
    -- Tarifs avec statistiques (agrégation JSON)
    (
        SELECT json_agg(
            json_build_object(
                'id', t_inner.id,
                'prix', t_inner.prix,
                'nombre_places', t_inner.nombre_places,
                'type_place', json_build_object(
                    'id', tp_inner.id,
                    'nom', tp_inner.nom,
                    'description', tp_inner.description,
                    'avantages', tp_inner.avantages
                ),
                'statistiques', (
                    SELECT json_build_object(
                        'total', COUNT(p_inner.id),
                        'disponibles', COUNT(CASE WHEN p_inner.etat_code = 'disponible' THEN 1 END),
                        'reservees', COUNT(CASE WHEN p_inner.etat_code = 'reservee' THEN 1 END),
                        'vendues', COUNT(CASE WHEN p_inner.etat_code = 'vendue' THEN 1 END),
                        'inactives', COUNT(CASE WHEN p_inner.etat_code IN ('annulee', 'maintenance') THEN 1 END)
                    )
                    FROM place p_inner
                    WHERE p_inner.tarif_id = t_inner.id
                )
            )
        )
        FROM tarif t_inner
        JOIN type_place tp_inner ON t_inner.type_place_id = tp_inner.id
        WHERE t_inner.evenement_id = e.id
    ) as tarifs,
    
    -- Fichiers avec URLs de contenu (agrégation JSON) - DATES FORMATÉES EN ISO
    COALESCE(
        (
            SELECT json_agg(
                json_build_object(
                    'id', fe.id,
                    'nom_fichier', fe.nom_fichier,
                    'type_mime', fe.type_mime,
                    'type_fichier', fe.type_fichier,
                    'taille_bytes', fe.taille_bytes,
                    'date_upload', to_char(fe.date_upload, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), -- FORMAT ISO
                    'url_contenu', '/v1/evenements/' || e.id || '/fichiers/' || fe.id || '/contenu'
                )
                ORDER BY fe.date_upload DESC
            )
            FROM fichier_evenement fe
            WHERE fe.evenement_id = e.id
        ),
        '[]'::json
    ) as fichiers,
    
    -- Statistiques globales de l'événement
    (
        SELECT json_build_object(
            'total_places', COUNT(DISTINCT p_stats.id),
            'places_disponibles', COUNT(DISTINCT CASE WHEN p_stats.etat_code = 'disponible' THEN p_stats.id END),
            'places_reservees', COUNT(DISTINCT CASE WHEN p_stats.etat_code = 'reservee' THEN p_stats.id END),
            'places_vendues', COUNT(DISTINCT CASE WHEN p_stats.etat_code = 'vendue' THEN p_stats.id END),
            'taux_occupation', 
                CASE 
                    WHEN COUNT(DISTINCT p_stats.id) > 0 THEN 
                        ROUND(COUNT(DISTINCT CASE WHEN p_stats.etat_code IN ('vendue', 'reservee') THEN p_stats.id END) * 100.0 / COUNT(DISTINCT p_stats.id), 2)
                    ELSE 0 
                END
        )
        FROM place p_stats
        JOIN tarif t_stats ON p_stats.tarif_id = t_stats.id
        WHERE t_stats.evenement_id = e.id
    ) as statistiques

FROM evenement e
JOIN type_evenement te ON e.type_id = te.id
JOIN lieu l ON e.lieu_id = l.id;