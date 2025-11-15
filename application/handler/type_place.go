package handler

import (
	"encoding/json"
	"net/http"
	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/models"
)




func GetTypePlacesHandler(service interfaces.EvenementService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        typesPlaces, err := service.GetTypePlaces()
        if err != nil {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(http.StatusInternalServerError)
            json.NewEncoder(w).Encode(models.ErrorResponse{
                Error: err.Error(),
            })
            return
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(typesPlaces)
    }
}