package request


import (
    "time"
)

// CreateEvenementRequest - Structure pour la requête API
type CreateEvenementRequest struct {
    Titre         string            `json:"titre"`
    Description   string            `json:"description"`
    DateDebut     time.Time         `json:"date_debut"`
    DateFin       time.Time         `json:"date_fin"`
    TypeEvenement string            `json:"type_evenement"`
    Lieu          LieuRequest       `json:"lieu"`
    Tarifs        []TarifRequest    `json:"tarifs"`
    Fichiers      []FichierRequest  `json:"fichiers,omitempty"`
}

type LieuRequest struct {
    Nom      string `json:"nom"`
    Adresse  string `json:"adresse"`
    Ville    string `json:"ville"`
    Capacite int    `json:"capacite"`
}

type TarifRequest struct {
    TypePlace    string  `json:"type_place"`    // "VIP", "Standard", etc.
    Prix         float64 `json:"prix"`
    NombrePlaces int     `json:"nombre_places"`
}

type FichierRequest struct {
    NomFichier    string `json:"nom_fichier"`
    TypeMime      string `json:"type_mime"`
    TypeFichier   string `json:"type_fichier"`
    DonneesBase64 string `json:"donnees_base64"`
}


