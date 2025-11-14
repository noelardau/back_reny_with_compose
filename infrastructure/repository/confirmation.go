package repository

// import (
// 	"context"
// 	"encoding/json"
// 	"fmt"
// 	"github.com/jackc/pgx/v5"

// )

// // Structures pour le résultat JSON



// type ReservationRepository struct {
// 	conn *pgx.Conn
// }

// func NewReservationRepository(conn *pgx.Conn) *ReservationRepository {
// 	return &ReservationRepository{conn: conn}
// }


// func GetReservationByID(ctx context.Context, reservationID string) (*ReservationDetails, error) {
// 	const query = `SELECT obtenir_details_reservation_par_id($1)`

// 	var jsonResult []byte
// 	err := r.conn.QueryRow(ctx, query, reservationID).Scan(&jsonResult)
// 	if err != nil {
// 		return nil,err
// 	}

// 	var details ReservationDetails
// 	if err := json.Unmarshal(jsonResult, &details); err != nil {
// 		return nil, fmt.Errorf("erreur de décodage JSON: %w", err)
// 	}

// 	// Vérifier si c'est une erreur (réservation non trouvée)
// 	if details.Erreur != nil && details.Erreur.Erreur {
// 		return nil, fmt.Errorf("réservation non trouvée: %s", details.Erreur.Message)
// 	}

// 	return &details, nil
// }