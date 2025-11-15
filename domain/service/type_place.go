package service

import "github.com/J2d6/reny_event/domain/models"


func (service EvenementService) GetTypePlaces() ([]models.TypePlaceGet, error) {
	typesPlaces, err := service.repo.GetTypePlaces()
    if err != nil {
        return nil, err
    }
    return typesPlaces, nil
}

