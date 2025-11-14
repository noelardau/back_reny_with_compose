-- ================================================
-- INDEX pour les performances
-- ================================================

-- Evenements
CREATE INDEX idx_evenement_dates ON evenement(date_debut, date_fin);
CREATE INDEX idx_evenement_lieu ON evenement(lieu_id);
CREATE INDEX idx_evenement_type ON evenement(type_id);
CREATE INDEX idx_evenement_titre ON evenement(titre);

-- Places
CREATE INDEX idx_place_etat ON place(etat_code);
CREATE INDEX idx_place_tarif ON place(tarif_id);
CREATE INDEX idx_place_numero ON place(numero);
CREATE INDEX idx_place_etat_tarif ON place(etat_code, tarif_id);

-- Tarifs
CREATE INDEX idx_tarif_evenement ON tarif(evenement_id);
CREATE INDEX idx_tarif_type_place ON tarif(type_place_id);
CREATE INDEX idx_tarif_evenement_type ON tarif(evenement_id, type_place_id);

-- Audit
CREATE INDEX idx_audit_place_id ON audit_place(place_id);
CREATE INDEX idx_audit_date ON audit_place(date_changement);

-- Fichiers
CREATE INDEX idx_fichier_evenement_id ON fichier_evenement(evenement_id);
CREATE INDEX idx_fichier_type ON fichier_evenement(type_fichier);

-- Réservations
CREATE INDEX idx_reservation_reference_paiement ON reservation(reference_paiement);
CREATE INDEX idx_reservation_place_place ON reservation_place(place_id);
CREATE INDEX idx_reservation_place_reservation ON reservation_place(reservation_id);