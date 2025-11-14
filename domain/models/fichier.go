package models

import "github.com/google/uuid"

type FichierContenu struct {
    EvenementID    uuid.UUID `json:"-"`
    NomFichier     string    `json:"nom_fichier"`
    TypeMime       string    `json:"type_mime"`
    TailleBytes    int64     `json:"taille_bytes"`
    DonneesBinaire []byte    `json:"-"`
}

