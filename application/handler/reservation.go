package handler

import (
	"encoding/json"
	"net/http"

	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/models"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)


func ReserverHandler(service interfaces.EvenementService) http.HandlerFunc {
 
	return func(w http.ResponseWriter, req *http.Request) {

		if req.Method != http.MethodPost {
			http.Error(w, "Méthode non autorisée", http.StatusMethodNotAllowed)
			return
		}

		reservationID, err := service.Reserver(req)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
			return
		}

		response := map[string]any{
			"success": true,
			"reservation_id": reservationID,
			"message": "Réservation créée avec succès",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)

    }
}


func AllReservationsHandler(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, req *http.Request) {
        if req.Method != http.MethodGet {
            http.Error(w, "Méthode non autorisée", http.StatusMethodNotAllowed)
            return
        }

        evenement_id_string := chi.URLParam(req, "id") 
        id_evenement, err := uuid.Parse(evenement_id_string)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: "ID événement invalide",
            })
            return
        }

        allreservations, err := service.GetAllReservationsFor(id_evenement)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }


        w.Header().Set("Content-Type", "application/json")
        w.Write(allreservations) 
    }
}




func ValiderReservation(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, req *http.Request) {
        if req.Method != http.MethodPost {
            http.Error(w, "Méthode non autorisée", http.StatusMethodNotAllowed)
            return
        }

        evenement_id_string := chi.URLParam(req, "id") 
        id_evenement, err := uuid.Parse(evenement_id_string)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: "ID événement invalide",
            })
            return
        }

        err = service.ValidateReservation(id_evenement)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }


        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    }
}



func MarkReservation(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, req *http.Request) {
        if req.Method != http.MethodPost {
            http.Error(w, "Méthode non autorisée", http.StatusMethodNotAllowed)
            return
        }

        reservation_id_string := chi.URLParam(req, "id") 
        id_reservation, err := uuid.Parse(reservation_id_string)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: "ID événement invalide",
            })
            return
        }

        err = service.MarkReservation(id_reservation)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }


        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    }
} 



func GetReservationByID(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        reservationIDStr := chi.URLParam(r, "id")
        reservationID, err := uuid.Parse(reservationIDStr)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: "ID de réservation invalide",
            })
            return
        }

        reservation, err := service.GetReservationByID(reservationID)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusNotFound)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(reservation)
    }
}