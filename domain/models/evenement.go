package models

import (
    "github.com/google/uuid"
)
// Structures pour mapper la réponse JSON de la fonction SQL
type EvenementCompletGet struct {
    EvenementID   uuid.UUID          `json:"evenement_id"`
    Titre         string             `json:"titre"`
    Description   string             `json:"description"`
    DateDebut     CustomTime         `json:"date_debut"`
    DateFin       CustomTime         `json:"date_fin"`
    TypeEvenement TypeEvenementGet   `json:"type_evenement"`
    Lieu          LieuGet            `json:"lieu"`
    Tarifs        []TarifComplet     `json:"tarifs"`
    Fichiers      []FichierEvenement `json:"fichiers"`
}

type TypeEvenementGet struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
}

type LieuGet struct {
    ID       uuid.UUID `json:"id"`
    Nom      string    `json:"nom"`
    Adresse  string    `json:"adresse"`
    Ville    string    `json:"ville"`
    Capacite int       `json:"capacite"`
}

type TarifComplet struct {
    TarifID      uuid.UUID `json:"tarif_id"`
    Prix         float64   `json:"prix"`
    NombrePlaces int       `json:"nombre_places"`
    TypePlace    TypePlace `json:"type_place"`
}

type TypePlace struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
    Avantages   string    `json:"avantages"`
}

// Structure corrigée pour les fichiers d'événement
type FichierEvenement struct {
    FichierID      uuid.UUID  `json:"fichier_id"`
    NomFichier     string     `json:"nom_fichier"`
    TypeMime       string     `json:"type_mime"`
    TailleBytes    int64      `json:"taille_bytes"`
    TypeFichier    string     `json:"type_fichier"`
    DateUpload     CustomTime `json:"date_upload"`
    DonneesBinaire string     `json:"donnees_binaire"` // Données en base64
}