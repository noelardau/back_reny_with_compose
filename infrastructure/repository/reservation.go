package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/J2d6/reny_event/domain/models"
	infrastructure "github.com/J2d6/reny_event/infrastructure/email"
	"github.com/google/uuid"
)


func (repo EvenementRepository) Reserver(req models.ReservationRequest) (string, error) {
	
    var reservationID string
    placesJSON, err := json.Marshal(req.PlacesDemandees)
    if err != nil {
        return "", fmt.Errorf("erreur marshaling JSON: %w", err)
    }
    
    err = repo.conn.QueryRow(
        context.Background(),
        RESERVER_QUERY,
        req.Email,
        req.EvenementID,
        placesJSON,
    ).Scan(&reservationID)
    
    if err != nil {
        return "", fmt.Errorf("erreur lors de la réservation: %w", err)
    }
    
    return reservationID, nil
}

func (repo EvenementRepository) GetAllReservationsFor(id_evenement uuid.UUID) ([]byte, error) {
    var jsonData []byte
    err := repo.conn.QueryRow(
        context.Background(),
        "SELECT obtenir_reservations_evenement($1)",
        id_evenement,
    ).Scan(&jsonData)
    if err != nil {
        return nil, err
    }
    
 
    return jsonData, nil
}



func (repo EvenementRepository) ValidateReservation(id_reservation uuid.UUID) error {
    _, err := repo.conn.Exec(
        context.Background(),
        `UPDATE public.reservation 
            SET etat_code='payee'::character varying, 
                etat='payee'::character varying
            WHERE id=$1;`, 
        id_reservation)
    if err != nil {
        return err
    }

    const query = `SELECT obtenir_details_reservation_par_id($1)`

    var jsonResult []byte
    err = repo.conn.QueryRow(context.Background(), query, id_reservation).Scan(&jsonResult)
    
    if err != nil {
        return err
    }

    // Désérialiser d'abord dans la structure temporaire
    var temp models.TempReservationDetails
    if err := json.Unmarshal(jsonResult, &temp); err != nil {
        return fmt.Errorf("erreur de décodage JSON: %w", err)
    }

    // Vérifier si c'est une erreur
    if temp.Erreur != nil && temp.Erreur.Erreur {
        return fmt.Errorf("réservation non trouvée: %s", temp.Erreur.Message)
    }

    // Convertir les dates
    dateReservation, err := parseFlexibleTime(temp.DateReservation)
    if err != nil {
        return fmt.Errorf("erreur parsing date réservation: %w", err)
    }

    dateDebut, err := parseFlexibleTime(temp.Evenement.DateDebut)
    if err != nil {
        return fmt.Errorf("erreur parsing date début: %w", err)
    }

    dateFin, err := parseFlexibleTime(temp.Evenement.DateFin)
    if err != nil {
        return fmt.Errorf("erreur parsing date fin: %w", err)
    }

    // Construire l'objet final
    details := models.ReservationDetails{
        ReservationID:   temp.ReservationID,
        Email:           temp.Email,
        DateReservation: dateReservation,
        EtatReservation: temp.EtatReservation,
        Evenement: models.Evenement{
            Nom:       temp.Evenement.Nom,
            Lieu:      temp.Evenement.Lieu,
            DateDebut: dateDebut,
            DateFin:   dateFin,
        },
        DetailsPlaces: temp.DetailsPlaces,
    }

    infrastructure.SendGomail(details)
    return nil
}




func parseFlexibleTime(timeStr string) (time.Time, error) {
    formats := []string{
        time.RFC3339,                    // "2006-01-02T15:04:05Z07:00"
        "2006-01-02T15:04:05.999999",   // Avec microsecondes
        "2006-01-02T15:04:05",          // Sans timezone
        "2006-01-02T15:04:05Z",         // Avec Z
        "2006-01-02 15:04:05.999999",   // Avec espace et microsecondes
        "2006-01-02 15:04:05",          // Avec espace
    }
    
    for _, format := range formats {
        t, err := time.Parse(format, timeStr)
        if err == nil {
            return t, nil
        }
    }
    
    return time.Time{}, fmt.Errorf("format de date non reconnu: %s", timeStr)
}
