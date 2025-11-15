package handler

import (
	"encoding/json"
	"net/http"

	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/models"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func GetEvenementByIDHandler(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
		evenement_id_string := chi.URLParam(r, "id") 
		evenement_id := uuid.MustParse(evenement_id_string)
		evenement, err := service.GetEvenementByID(evenement_id)
		if err!= nil {
			w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
			return
		}

		w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(evenement)
    }
}


func GetAllEvents(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {

		evenements, err := service.GetAllEvents()
		if err!= nil {
			w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
			return
		}

		w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(evenements)
    }
}