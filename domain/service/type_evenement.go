package service

import "github.com/J2d6/reny_event/domain/models"

func (service EvenementService) GetAllTypeEvenements() ([]models.TypeEvenementGet, error) {
    typesEvenements, err := service.repo.GetAllTypeEvenements()
    if err != nil {
        return nil, err
    }
    return typesEvenements, nil
}