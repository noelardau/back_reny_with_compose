package db

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func CreateNewPgxConnexionPool() (*pgxpool.Pool, error) {
	// Chaîne de connexion PostgreSQL locale
	config, err := pgxpool.ParseConfig("postgresql://admin:admin@localhost:5432/renydb")
	if err != nil {
		return nil, err
	}

	// Optionnel : config pool
	config.MaxConns = 25
	config.MinConns = 5

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, err
	}

	// Test connexion
	if err = pool.Ping(context.Background()); err != nil {
		log.Fatalf("Erreur du serveur: %v", err)
		return nil, err
	}

	return pool, nil
}

// package db

// import (
// 	"context"

// 	"github.com/jackc/pgx/v5/pgxpool"
// )

// func CreateNewPgxConnexionPool() (*pgxpool.Pool, error) {

// 	dbpool, err := pgxpool.New(context.Background(), "postgresql://postgres:gF7dYGWDK9tOUzCN@db.bbfsckuzadzzsdymgzmj.supabase.co:5432/postgres")
// 	if err != nil {
// 		return nil, err
// 	}

// 	return dbpool, nil
// }
