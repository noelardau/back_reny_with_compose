// // Dans domain/service/authentification.go
package service

import (
	"context"
	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/google/uuid"
)

type AuthentificationService struct {
	utilisateurRepo interfaces.UtilisateurRepository
}

func NewAuthentificationService(utilisateurRepo interfaces.UtilisateurRepository) *AuthentificationService {
	return &AuthentificationService{
		utilisateurRepo: utilisateurRepo,
	}
}

// Authentifie
func (service AuthentificationService) VerifierCredentials( login, motDePasse string) (uuid.UUID, error){
	 auth, err := service.utilisateurRepo.VerifierCredentials(
		context.Background(),
		login,
		motDePasse,
	)
	if err != nil {
		return uuid.Nil, err
	}
	return  auth.ID, nil
}

