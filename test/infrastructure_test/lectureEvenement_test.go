package infrastructure_test

import (
	"testing"
	infrastructure "github.com/J2d6/reny_event/test/infrastructure_test"
	"github.com/google/uuid"
)



func TestLectureEvenement(t *testing.T) { 
	t.Run("NOT FOUND EVENEMENT", func (t *testing.T) {
		evenement_id := uuid.New()
		repo := infrastructure.CreateRepository(t)
		_ , err := repo.GetEvenementByID(evenement_id)
		if err == nil {
			t.Errorf("Didn't get the SQL error : %v", err)
		}
	})

	t.Run("Get evenement by known ID", func (t *testing.T) {
		evenement_id := uuid.MustParse("fc142deb-73c7-4dbb-8f51-fe05a8231836")
		repo:= infrastructure.CreateRepository(t)
		_ , err := repo.GetEvenementByID(evenement_id)
		infrastructure.AssertError(t, err)
	})


	t.Run("Get all events", func (t *testing.T) {
		repo:= infrastructure.CreateRepository(t)
		reservation , err := repo.GetAllEvents()
		if err != nil {
			t.Errorf("Failed to get all evenets : %v, RESA : %v", err, reservation)
		}
	})
	
}
