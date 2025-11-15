package models

import (
    "time"
    "github.com/google/uuid"
)

// Structures pour mapper la réponse JSON de la fonction SQL
type EvenementCompletGet struct {
    EvenementID  uuid.UUID     `json:"evenement_id"`
    Titre        string        `json:"titre"`
    Description  string        `json:"description"`
    DateDebut    time.Time     `json:"date_debut"`
    DateFin      time.Time     `json:"date_fin"`
    TypeEvenement TypeEvenement `json:"type_evenement"`
    Lieu         Lieu          `json:"lieu"`
    Tarifs       []TarifComplet `json:"tarifs"`
}

type TypeEvenementGet struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
}

type LieuGet struct {
    ID       uuid.UUID `json:"id"`
    Nom      string    `json:"nom"`
    Adresse  string    `json:"adresse"`
    Ville    string    `json:"ville"`
    Capacite int       `json:"capacite"`
}

type TarifComplet struct {
    TarifID      uuid.UUID  `json:"tarif_id"`
    Prix         float64    `json:"prix"`
    NombrePlaces int        `json:"nombre_places"`
    TypePlace    TypePlace  `json:"type_place"`
}

type TypePlace struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
    Avantages   string    `json:"avantages"`
}

