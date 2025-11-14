-- ================================================
-- TABLES DE BASE
-- ================================================

CREATE TABLE type_evenement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE lieu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(150) NOT NULL,
    adresse TEXT NOT NULL,
    ville VARCHAR(100) NOT NULL,
    capacite INT CHECK (capacite >= 0 OR capacite IS NULL)
);

CREATE TABLE type_place (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    avantages TEXT
);

CREATE TABLE etat_place (
    code VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL
);