-- ================================================
-- TABLES : Réservations
-- ================================================

CREATE TABLE reservation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reference_paiement varchar(100) NULL,
    date_reservation timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email varchar(255) NOT NULL,
    etat_code varchar(20) DEFAULT 'en_attente'::character varying NOT NULL,
    etat varchar(20) DEFAULT 'en_attente'::character varying NOT NULL,
    CONSTRAINT reservation_pkey PRIMARY KEY (id)
);

CREATE TABLE reservation_place (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reservation_id uuid NOT NULL,
    place_id uuid NOT NULL,
    CONSTRAINT reservation_place_pkey PRIMARY KEY (id),
    CONSTRAINT uq_reservation_place UNIQUE (place_id)
);

-- Foreign Keys
ALTER TABLE reservation_place 
    ADD CONSTRAINT fk_reservation_place_place 
    FOREIGN KEY (place_id) REFERENCES place(id) ON DELETE CASCADE;

ALTER TABLE reservation_place 
    ADD CONSTRAINT fk_reservation_place_reservation 
    FOREIGN KEY (reservation_id) REFERENCES reservation(id) ON DELETE CASCADE;