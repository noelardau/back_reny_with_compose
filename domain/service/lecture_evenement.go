package service

import (
	"encoding/json"
	"fmt"

	"github.com/J2d6/reny_event/domain/errors"
	"github.com/J2d6/reny_event/domain/models"
	"github.com/google/uuid"
)

func (service EvenementService) GetEvenementByID(id_evenement uuid.UUID) (*models.EvenementComplet, error) {
	evenementJsonData, err := service.repo.GetEvenementByID(id_evenement)
	if err != nil {
		return nil, errors.ServiceError{Message: err.Error()} // erreur generique dde la couche service 
	}

	var evenement models.EvenementComplet
	if err := json.Unmarshal(evenementJsonData, &evenement); err != nil {
		return nil, fmt.Errorf("erreur de décodage JSON: %w", err)
	}

	return  &evenement, nil
}

func (service EvenementService) GetAllEvents() ([]models.EvenementCompletGet, error) {
	allEvents, err := service.repo.GetAllEvents()
	if err != nil {
		return nil, err
	}
	return allEvents, nil

}