package interfaces

import (
	"net/http"

	"github.com/J2d6/reny_event/domain/models"
	"github.com/google/uuid"
)


var TypeEvenementIDMap = map[string]string{
    "Concert": "a30b8d7c-8b25-4a91-9e59-0d6f443f4d1b",
    "Conference": "97d2b239-39cb-4f3f-a196-4b4d3e39dd0a",
	"Spectacle": "b688869b-f36f-4fad-bcd9-27fe25785ecb",
    "Seminaire": "00e2256b-af80-43be-8d65-b1cddc115917",
    "Foire": "2a487da3-dd91-4f31-a655-56c9c5162c3b",
	"Exposition": "fff610de-686f-40a2-a50d-b535f8a822fd",
}

var TypePlaceIDMap = map[string]string{
	"VIP":"ecfd1152-91c5-4ca6-8aa6-d006e1b1f662",
	"Standard":"6ebe3b37-01bc-462a-a37e-cc3fb3cb5e11",
	"Premium":"a1f361de-ca05-42bd-9509-d2c20f77a05f",
	"Economique":"14467104-6d39-445c-a2d1-4dd1f697ac68",
}


type EvenementService interface {
	CreateNewEvenement(req *http.Request) (*models.CreationEvenementResponse, error)
	GetEvenementByID(id_evenement uuid.UUID) (*models.EvenementComplet, error)
	Reserver(req *http.Request) (string, error)
	GetAllReservationsFor(evenement_id uuid.UUID) ([]byte, error)
	ValidateReservation(id_Evenement uuid.UUID) error
	GetAllEvents() ([]models.EvenementCompletGet, error)
	GetReservationByID(reservationID uuid.UUID) (*models.ReservationCompleteT, error)
	GetTypePlaces()([]models.TypePlaceGet, error)
	GetAllTypeEvenements() ([]models.TypeEvenementGet, error)
	MarkReservation(id_reservation uuid.UUID) (error)
}


type EvenementRepository interface {
	CreateNewEvenement(request models.CreationEvenementRequest) (uuid.UUID, error)
	GetEvenementByID(id uuid.UUID) ([]byte, error)
	Reserver(models.ReservationRequest) (string, error)
	GetAllReservationsFor(id_evenement uuid.UUID)([]byte, error)
	ValidateReservation(id_Evenement uuid.UUID) error
	GetAllEvents() ([]models.EvenementCompletGet, error)
	GetReservationByID(reservationID uuid.UUID) (*models.ReservationCompleteT, error)
	GetTypePlaces()([]models.TypePlaceGet, error)
	GetAllTypeEvenements() ([]models.TypeEvenementGet, error)
	MarkReservation(id_reservation uuid.UUID) (uuid.UUID, error)
}


