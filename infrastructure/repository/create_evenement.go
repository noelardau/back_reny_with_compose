package repository

import (
	"context"
	"encoding/json"
	"github.com/J2d6/reny_event/domain/models"
	"github.com/google/uuid"
)


func (repo EvenementRepository) CreateNewEvenement(creationEvenementRequest models.CreationEvenementRequest) (uuid.UUID, error)  {
	tarifsJSON, err := json.Marshal(creationEvenementRequest.Tarifs); 
	if err != nil {
        return uuid.Nil, err
    }
	fichiersJSON, err := json.Marshal(creationEvenementRequest.Fichiers); 
	if err != nil {
        return uuid.Nil, err
    }

	var evenementID uuid.UUID

	err = repo.conn.QueryRow(context.Background(), CREATE_EVENEMENT_COMPLET_QUERY,
        creationEvenementRequest.Titre,
        creationEvenementRequest.Description,
        creationEvenementRequest.DateDebut,
        creationEvenementRequest.DateFin,
        creationEvenementRequest.TypeID,
        creationEvenementRequest.LieuNom,
        creationEvenementRequest.LieuAdresse,
        creationEvenementRequest.LieuVille,
        creationEvenementRequest.LieuCapacite,
        string(tarifsJSON),
        string(fichiersJSON),
    ).Scan(&evenementID)


	if err != nil {
        return uuid.Nil, err
    }

	return evenementID, nil
}



