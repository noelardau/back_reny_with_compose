package models

import "time"

type ReservationRequest struct {
    Email           string                   `json:"email"`
    EvenementID     string                   `json:"evenement_id"`
    PlacesDemandees []TypePlaceDemande       `json:"places_demandees"`
}

type TypePlaceDemande struct {
    TypePlaceID string `json:"type_place_id"`
    Nombre      int    `json:"nombre"`
}



// ============ VALIDATION 

type ReservationDetails struct {
	ReservationID   string    `json:"reservation_id"`
	Email           string    `json:"email"`
	DateReservation time.Time `json:"date_reservation"`
	EtatReservation string    `json:"etat_reservation"`
	Evenement       Evenement `json:"evenement"`
	DetailsPlaces   DetailsPlaces `json:"details_places"`
	Erreur          *ErreurResponse `json:"erreur,omitempty"`
}

type Evenement struct {
	Nom       string    `json:"nom"`
	Lieu      string    `json:"lieu"`
	DateDebut time.Time `json:"date_debut"`
	DateFin   time.Time `json:"date_fin"`
}

type DetailsPlaces struct {
	NombrePlaces    int       `json:"nombre_places"`
	NumerosPlaces   []string  `json:"numeros_places"`
	PrixParPlace    []float64 `json:"prix_par_place"`
	TotalReservation float64   `json:"total_reservation"`
}

type ErreurResponse struct {
	Erreur   bool   `json:"erreur"`
	Message  string `json:"message"`
	ReservationID string `json:"reservation_id,omitempty"`
}


// Structure intermédiaire pour gérer le parsing flexible des dates
type TempReservationDetails struct {
    ReservationID   string          `json:"reservation_id"`
    Email           string          `json:"email"`
    DateReservation string          `json:"date_reservation"`
    EtatReservation string          `json:"etat_reservation"`
    Evenement       struct {
        Nom       string `json:"nom"`
        Lieu      string `json:"lieu"`
        DateDebut string `json:"date_debut"`
        DateFin   string `json:"date_fin"`
    } `json:"evenement"`
    DetailsPlaces DetailsPlaces `json:"details_places"`
    Erreur        *ErreurResponse `json:"erreur,omitempty"`
}