package service

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/J2d6/reny_event/domain/models"
	"github.com/google/uuid"
)


func (service EvenementService) Reserver(req *http.Request) (string, error) {
	reservationData, err := mapRequeteReservation(req)
	if err != nil {
		return "", err
	}

	reservation_id, err := service.repo.Reserver(reservationData)
	if err != nil {
		return "", err
	}
	return  reservation_id, nil
}

func (service EvenementService) GetAllReservationsFor(evenement_id uuid.UUID)([]byte, error)  {
    reservations,err := service.repo.GetAllReservationsFor(evenement_id)
    if err != nil {
        return nil, err
    }

    return reservations, nil
}


func (serrvice EvenementService) ValidateReservation(id_Evenement uuid.UUID) error {
    if err := serrvice.repo.ValidateReservation(id_Evenement); err != nil {
        return err
    }
    return  nil
}

func (service EvenementService) GetReservationByID(reservationID uuid.UUID) (*models.ReservationCompleteT, error) {
    reservation, err := service.repo.GetReservationByID(reservationID)
    if err != nil {
        return nil, err
    }
    return reservation, nil
}


func mapRequeteReservation(r *http.Request) (models.ReservationRequest, error) {
    var req models.ReservationRequest
    
    // Vérifier que le body n'est pas vide
    if r.Body == nil {
        return req, fmt.Errorf("body de requête vide")
    }
    defer r.Body.Close()
    
    // Lire et décoder le JSON
    body, err := io.ReadAll(r.Body)
    if err != nil {
        return req, fmt.Errorf("erreur lecture body: %w", err)
    }
    
    if len(body) == 0 {
        return req, fmt.Errorf("body JSON vide")
    }
    
    err = json.Unmarshal(body, &req)
    if err != nil {
        return req, fmt.Errorf("erreur décodage JSON: %w", err)
    }
    
    // Validation basique
    if req.Email == "" {
        return req, fmt.Errorf("email est requis")
    }
    
    if req.EvenementID == "" {
        return req, fmt.Errorf("evenement_id est requis")
    }
    
    if len(req.PlacesDemandees) == 0 {
        return req, fmt.Errorf("au moins une place doit être demandée")
    }
    
    return req, nil
}