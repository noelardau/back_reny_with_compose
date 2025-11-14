package repository

import (
	"context"
	"fmt"

	"github.com/J2d6/reny_event/domain/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UtilisateurRepository struct {
	conn *pgxpool.Pool
}

func NewUtilisateurRepository(conn *pgxpool.Pool) *UtilisateurRepository {
	return &UtilisateurRepository{conn: conn}
}

// VerifierCredentials vérifie le login/mot de passe et retourne l'utilisateur si valide
func (r *UtilisateurRepository) VerifierCredentials(
    ctx context.Context, 
    login, motDePasse string,
) (*models.Utilisateur, error) {
    
    var utilisateur models.Utilisateur
    
    query := `
      	SELECT id, username, created_at 
		FROM admin 
		WHERE username = $1
		AND password = $2;
    `
    
    err := r.conn.QueryRow(ctx, query, login, motDePasse).Scan(
        &utilisateur.ID,
        &utilisateur.Login,
        &utilisateur.MotDePasse,
    )
    
    if err != nil {
        if err == pgx.ErrNoRows {
            return nil, nil // Credentials invalides
        }
        return nil, fmt.Errorf("erreur vérification credentials: %w", err)
    }
    
    return &utilisateur, nil
}
