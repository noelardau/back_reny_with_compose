package handler

import (
	"encoding/json"
	"net/http"

	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/models"
)

func CreationEvenementHandler(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        response, err := service.CreateNewEvenement(r)
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusBadRequest)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusCreated)
        json.NewEncoder(w).Encode(response)
    }
}