package models

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type ReservationCompleteT struct {
    ReservationID     uuid.UUID          `json:"reservation_id"`
    Email             string             `json:"email"`
    ReferencePaiement string             `json:"reference_paiement"`
    DateReservation   CustomTime         `json:"date_reservation"`  // Changé ici
    Etat              string             `json:"etat"`
    EtatCode          string             `json:"etat_code"`
    Evenement         EvenementReservationT `json:"evenement"`
    Places            []PlaceReservationT   `json:"places"`
    Total             float64            `json:"total"`
    NombrePlaces      int                `json:"nombre_places"`
}

type EvenementReservationT struct {
    ID            uuid.UUID     `json:"id"`
    Titre         string        `json:"titre"`
    Description   string        `json:"description"`
    DateDebut     CustomTime    `json:"date_debut"`  // Changé ici
    DateFin       CustomTime    `json:"date_fin"`    // Changé ici
    TypeEvenement TypeEvenement `json:"type_evenement"`
    Lieu          Lieu          `json:"lieu"`
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


type CustomTime time.Time

const customTimeFormat = "2006-01-02T15:04:05"

func (ct *CustomTime) UnmarshalJSON(b []byte) error {
    s := strings.Trim(string(b), "\"")
    if s == "null" {
        *ct = CustomTime(time.Time{})
        return nil
    }
    t, err := time.Parse(customTimeFormat, s)
    if err != nil {
        return err
    }
    *ct = CustomTime(t)
    return nil
}

func (ct CustomTime) MarshalJSON() ([]byte, error) {
    return []byte(`"` + time.Time(ct).Format(customTimeFormat) + `"`), nil
}

func (ct CustomTime) Time() time.Time {
    return time.Time(ct)
}