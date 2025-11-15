package models

import (
    "time"
    "github.com/google/uuid"
)

type ReservationCompleteT struct {
    ReservationID     uuid.UUID          `json:"reservation_id"`
    Email             string             `json:"email"`
    ReferencePaiement string             `json:"reference_paiement"`
    DateReservation   time.Time          `json:"date_reservation"`
    Etat              string             `json:"etat"`
    EtatCode          string             `json:"etat_code"`
    Evenement         EvenementReservationT `json:"evenement"`
    Places            []PlaceReservationT   `json:"places"`
    Total             float64            `json:"total"`
    NombrePlaces      int                `json:"nombre_places"`
}

type EvenementReservationT struct {
    ID            uuid.UUID        `json:"id"`
    Titre         string           `json:"titre"`
    Description   string           `json:"description"`
    DateDebut     time.Time        `json:"date_debut"`
    DateFin       time.Time        `json:"date_fin"`
    TypeEvenement TypeEvenement    `json:"type_evenement"`
    Lieu          Lieu             `json:"lieu"`
}

type PlaceReservationT struct {
    PlaceID         uuid.UUID     `json:"place_id"`
    Numero          string        `json:"numero"`
    EtatCode        string        `json:"etat_code"`
    EtatDescription string        `json:"etat_description"`
    Tarif           TarifPlaceT    `json:"tarif"`
}

type TarifPlaceT struct {
    ID        uuid.UUID   `json:"id"`
    Prix      float64     `json:"prix"`
    TypePlace TypePlace   `json:"type_place"`
}