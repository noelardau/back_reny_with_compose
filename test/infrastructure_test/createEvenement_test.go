package infrastructure_test

import (
	"errors"
	"os"
	"testing"
	"time"

	"github.com/J2d6/reny_event/domain/models"
	"github.com/J2d6/reny_event/infrastructure/db"
	"github.com/J2d6/reny_event/infrastructure/repository"
	"github.com/google/uuid"
)

func TestCreateEvenement(t *testing.T) {

	conn, err := db.CreateNewPgxConnexionPool()
	if err != nil {
		t.Fatalf("Failed to connect to the database : %v", err)
	}

	req, err := exempleAvecCapaciteLimitee()
	if err != nil {
		t.Fatalf("ERROR EXEMPLE DATA: %v", err)
	}

	repo := repository.NewEvenementRepository(conn)
	id_evenement, err := repo.CreateNewEvenement(*req)

	if id_evenement == uuid.Nil {
		t.Errorf("Failed to create the evenement, got %v ... ERROR : %v", id_evenement, err)
	}
}

func exempleAvecCapaciteLimitee() (*models.CreationEvenementRequest, error) {
	fichier, err := chargerFichierReel("./test_files/IMG_9998.JPG")
	if err != nil {
		return nil, err
	}
	var lieuCapacite int = 2000
	return &models.CreationEvenementRequest{
		Titre:       "TARIKA HERY",
		Description: "Un concert magique en plein air dans le parc de la ville.",
		DateDebut:   time.Date(2026, 8, 10, 19, 0, 0, 0, time.UTC),
		DateFin:     time.Date(2026, 8, 10, 22, 0, 0, 0, time.UTC),
		TypeID:      uuid.MustParse("360ad057-8a48-4bf5-be64-6390d581460c"),

		LieuNom:      "Parc Central",
		LieuAdresse:  "Avenue des Champs-Élysées",
		LieuVille:    "Paris",
		LieuCapacite: &lieuCapacite,

		Tarifs: []models.TarifRequest{
			{
				TypePlaceID:  uuid.MustParse("900b487f-6ed7-4259-bee3-b8f397360772"),
				Prix:         25.00,
				NombrePlaces: 1000,
			},
		},

		Fichiers: []models.FichierRequest{
			{
				NomFichier:   "image.jpg",
				TypeMime:     "image/jpeg",
				TypeFichier:  "photo",
				DonneesBytea: fichier,
			},
		},
	}, nil
}

func chargerFichierReel(chemin string) ([]byte, error) {
	data, err := os.ReadFile(chemin)
	if err != nil {
		return nil, err
	}

	// Vérifier que le fichier n'est pas vide
	if len(data) == 0 {
		return nil, errors.New("LEN DATA 0")
	}

	return data, nil
}
