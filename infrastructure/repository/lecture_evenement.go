package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/google/uuid"
)

func (repo EvenementRepository) GetEvenementByID(id uuid.UUID) ([]byte, error) {
	
	var EvenementCompletJSON []byte
	err := repo.conn.QueryRow(context.Background(), GET_EVENEMENT_BY_ID, id).Scan(&EvenementCompletJSON)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la récupération de l'événement: %w", err)
	}

	if flag, err := checkIfResponseIsError(EvenementCompletJSON); flag {
		return nil, errors.New(err.Error())
	}

	
	return  EvenementCompletJSON, nil
}


func checkIfResponseIsError(evenement []byte) (bool , error ){
	// Vérifier si c'est une erreur
	var errorResponse struct {
		Erreur bool   `json:"erreur"`
		Message string `json:"message"`
	}
	
	if err := json.Unmarshal(evenement, &errorResponse); err == nil && errorResponse.Erreur {
		return true, errors.New(errorResponse.Message)
	}

	return false, nil
}