package service

import (
	"github.com/J2d6/reny_event/domain/interfaces"
)


type EvenementService struct {
    repo interfaces.EvenementRepository
}
func NewEvenementService (repo interfaces.EvenementRepository) interfaces.EvenementService {
    return EvenementService{repo: repo}
}



