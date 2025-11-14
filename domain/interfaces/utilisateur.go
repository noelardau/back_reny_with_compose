package interfaces

import (
	"context"

	"github.com/J2d6/reny_event/domain/models"
)

type UtilisateurRepository interface {
	VerifierCredentials(ctx context.Context, login, motDePasse string) (*models.Utilisateur, error)
}