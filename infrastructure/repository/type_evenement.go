package repository

import (
	"context"
	"encoding/json"

	"github.com/J2d6/reny_event/domain/models"
)


func (repo EvenementRepository) GetAllTypeEvenements() ([]models.TypeEvenementGet, error) {
    var typesEvenementsData []byte
    
    err := repo.conn.QueryRow(context.Background(), 
        "SELECT obtenir_tous_types_evenements() as types_evenements_data",
    ).Scan(&typesEvenementsData)
    
    if err != nil {
        return nil, err
    }

    var typesEvenements []models.TypeEvenementGet
    err = json.Unmarshal(typesEvenementsData, &typesEvenements)
    if err != nil {
        return nil, err
    }

    return typesEvenements, nil
}