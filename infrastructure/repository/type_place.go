package repository

import (
	"context"
	"encoding/json"

	"github.com/J2d6/reny_event/domain/models"
)

func (repo EvenementRepository) GetTypePlaces() ([]models.TypePlaceGet, error) {
	var typesPlacesData []byte
    
    err := repo.conn.QueryRow(context.Background(), 
        "SELECT obtenir_tous_types_places() as types_places_data",
    ).Scan(&typesPlacesData)
    
    if err != nil {
        return nil, err
    }

    var typesPlaces []models.TypePlaceGet
    err = json.Unmarshal(typesPlacesData, &typesPlaces)
    if err != nil {
        return nil, err
    }

    return typesPlaces, nil
}