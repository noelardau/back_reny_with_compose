package repository

import (
	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/jackc/pgx/v5/pgxpool"
)



type EvenementRepository struct {
	conn *pgxpool.Pool
}

func NewEvenementRepository(conn *pgxpool.Pool)  interfaces.EvenementRepository {
	return EvenementRepository{conn: conn}
}
