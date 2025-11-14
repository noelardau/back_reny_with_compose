package models

import "github.com/google/uuid"

type TarifInput struct {
    TypePlaceID  uuid.UUID `json:"type_place_id"`
    Prix         float64   `json:"prix"`
    NombrePlaces int       `json:"nombre_places"`
}



