-- ================================================
-- VUE : Détails des places d'un événement
-- ================================================
CREATE OR REPLACE VIEW vue_places_evenement AS
SELECT 
    p.id as place_id,
    p.numero,
    p.etat_code,
    ep.description as etat_description,
    
 
    t.id as tarif_id,
    t.prix,
    
 
    tp.id as type_place_id,
    tp.nom as type_place_nom,
    tp.avantages,
    

    e.id as evenement_id,
    e.titre as evenement_titre,
    e.date_debut,

    l.nom as lieu_nom,
    l.ville as lieu_ville

FROM place p
JOIN etat_place ep ON p.etat_code = ep.code
JOIN tarif t ON p.tarif_id = t.id
JOIN type_place tp ON t.type_place_id = tp.id
JOIN evenement e ON t.evenement_id = e.id
JOIN lieu l ON e.lieu_id = l.id;