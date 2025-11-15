package infrastructure

import (
	"testing"

	"github.com/J2d6/reny_event/domain/models"
	// infrastructure "github.com/J2d6/reny_event/infrastructure/email"
	"github.com/google/uuid"
)



func TestReservation(t *testing.T) {
	t.Run("Reservation with success", func (t *testing.T) {
		repo := CreateRepository(t)

		req := models.ReservationRequest{
			Email:       "noelardau@gmail.com",
			EvenementID: "fc142deb-73c7-4dbb-8f51-fe05a8231836",
			PlacesDemandees: []models.TypePlaceDemande{
				{
					TypePlaceID: "14467104-6d39-445c-a2d1-4dd1f697ac68",
					Nombre:      5,
				},
			},
		}
		reservation_id , err := repo.Reserver(req)
		if reservation_id == "" {
			t.Errorf("FAILED TO RESERVE: %v", err)
		}
	})

	t.Run("Reservation with no place dispo", func (t *testing.T) {
		repo := CreateRepository(t)

		req := models.ReservationRequest{
			Email:       "client@example.com",
			EvenementID: "fc142deb-73c7-4dbb-8f51-fe05a8231836",
			PlacesDemandees: []models.TypePlaceDemande{
				{
					TypePlaceID: "14467104-6d39-445c-a2d1-4dd1f697ac68",
					Nombre:      500,
				},
			},
		}
		_ , err := repo.Reserver(req)
		if err == nil {
			t.Errorf("FAILED TO RESERVE: %v", err)
		}
	})
		
}


func TestGetReservation(t *testing.T) {
	t.Run("Get alll reservations for a known evenement", func (t *testing.T) {
		repo:= CreateRepository(t)
		id_Evenement := uuid.New()
		_, err := repo.GetAllReservationsFor(id_Evenement)
		if err != nil {
			t.Errorf("Didn't get resevations : %v", err)
		}
	})
}

func TestValidateReservation(t *testing.T) {
	t.Run("Validation with success", func (t *testing.T) {
		repo := CreateRepository(t)
		id_Evenement := uuid.MustParse("2c24611e-1b4c-401f-8ead-78da264f81e1")
		err := repo.ValidateReservation(id_Evenement)
		if err != nil {
			t.Errorf("Failed to validate reservation : %v", err)
		}
	})
}


func TestGetReservationByID(t *testing.T) {
	t.Run("Get reservation by id", func (t *testing.T) {
		repo := CreateRepository(t)
		id_reservation := uuid.MustParse("900b487f-6ed7-4259-bee3-b8f397360772")
		_, err := repo.GetReservationByID(id_reservation)
		if err != nil {
			t.Errorf("Failed to get reservation : %v", err)
		}

	})
}


