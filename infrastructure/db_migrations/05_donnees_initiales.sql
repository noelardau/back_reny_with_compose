-- ================================================
-- DONNÉES INITIALES
-- ================================================

-- États de place
INSERT INTO etat_place (code, description) VALUES
('disponible', 'Place disponible à la vente'),
('reservee', 'Place réservée temporairement'),
('vendue', 'Place vendue'),
('annulee', 'Place annulée/invalide'),
('maintenance', 'Place en maintenance');

-- Types d'événement
INSERT INTO type_evenement (nom, description) VALUES
('Concert', 'Événement musical avec artistes sur scène'),
('Conference', 'Événement de présentation et d''échanges'),
('Spectacle', 'Représentation théâtrale ou artistique'),
('Foire', 'Événement commercial avec exposants'),
('Seminaire', 'Séminaire professionnel'),
('Exposition', 'Présentation d''œuvres ou de produits');

-- Types de place
INSERT INTO type_place (nom, description, avantages) VALUES
('VIP', 'Place premium avec avantages exclusifs', 'Accès lounge, parking dédié, restauration incluse'),
('Standard', 'Place classique standard', 'Accès à l''événement, siège standard'),
('Économique', 'Place à prix réduit', 'Accès basique à l''événement'),
('Premium', 'Place premium confort', 'Sièges plus larges, service prioritaire');