package infrastructure

import (
	"errors"
	"testing"

	domain_error "github.com/J2d6/reny_event/domain/errors"
	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/infrastructure/db"
	"github.com/J2d6/reny_event/infrastructure/repository"
)

func CreateRepository(t testing.TB) interfaces.EvenementRepository {
	t.Helper()
	conn, err := db.CreateNewPgxConnexionPool()
	if err != nil {
		t.Fatalf("Failed to connect to the database")
	}
	repo := repository.NewEvenementRepository(conn)
	return repo
}

func AssertError(t testing.TB, err error) {
	t.Helper()
	if err != nil {
		t.Errorf("ERROR : %v", err)
	}
}

func AssertSQLError(t testing.TB, err error) {
	t.Helper()
	if !errors.Is(err, &domain_error.ErreurSQL{}) {
		t.Errorf("Didn't get SQL ERROR : %v", err)
	}
}
