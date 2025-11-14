package models

import (
	"fmt"
	"time"
    "github.com/shopspring/decimal"
	"github.com/google/uuid"
)

// CreationEvenementRequest représente toutes les données nécessaires pour créer un événement complet
type CreationEvenementRequest struct {
    // Informations de base de l'événement
    Titre       string    `json:"titre" binding:"required,min=1,max=150"`
    Description string    `json:"description"`
    DateDebut   time.Time `json:"date_debut" binding:"required"`
    DateFin     time.Time `json:"date_fin" binding:"required"`
    TypeID      uuid.UUID `json:"type_id" binding:"required"`
    
    // Informations du lieu
    LieuNom      string `json:"lieu_nom" binding:"required,min=1,max=150"`
    LieuAdresse  string `json:"lieu_adresse" binding:"required"`
    LieuVille    string `json:"lieu_ville" binding:"required,max=100"`
    LieuCapacite *int   `json:"lieu_capacite"` // Pointer pour permettre nil (capacité illimitée)
    
    // Tarifs et types de places
    Tarifs []TarifRequest `json:"tarifs" binding:"required,min=1,dive"`
    
    // Fichiers associés (optionnel)
    Fichiers []FichierRequest `json:"fichiers,omitempty"`
}

// TarifRequest représente un tarif pour un type de place
type TarifRequest struct {
    TypePlaceID  uuid.UUID `json:"type_place_id" binding:"required"`
    Prix         float64   `json:"prix" binding:"required,min=0"`
    NombrePlaces int       `json:"nombre_places" binding:"required,min=1"`
}

// FichierRequest représente un fichier associé à l'événement
type FichierRequest struct {
    NomFichier    string `json:"nom_fichier" binding:"required,max=255"`
    TypeMime      string `json:"type_mime" binding:"required,max=100"`
    TypeFichier   string `json:"type_fichier" binding:"required"`
    DonneesBytea  []byte `json:"donnees_bytea" binding:"required"` // ✅ Ajout du tag JSON
}



type ErrorResponse struct {
    Error string `json:"error"`
}


// Méthodes utilitaires pour le struct principal
func (r *CreationEvenementRequest) Validate() error {
    // Validation des dates
    if r.DateDebut.After(r.DateFin) {
        return fmt.Errorf("la date de début doit être avant la date de fin")
    }
    
    if r.DateDebut.Before(time.Now()) {
        return fmt.Errorf("la date de début doit être dans le futur")
    }
    
    // Validation de la capacité
    if r.LieuCapacite != nil && *r.LieuCapacite < 0 {
        return fmt.Errorf("la capacité du lieu ne peut pas être négative")
    }
    
    // Validation des tarifs
    totalPlaces := 0
    for _, tarif := range r.Tarifs {
        totalPlaces += tarif.NombrePlaces
    }
    
    if r.LieuCapacite != nil && totalPlaces > *r.LieuCapacite {
        return fmt.Errorf("la somme des places (%d) dépasse la capacité du lieu (%d)", 
            totalPlaces, *r.LieuCapacite)
    }
    
    return nil
}

// CalculerTotalPlaces calcule le nombre total de places demandées
func (r *CreationEvenementRequest) CalculerTotalPlaces() int {
    total := 0
    for _, tarif := range r.Tarifs {
        total += tarif.NombrePlaces
    }
    return total
}

// HasCapaciteIllimitee vérifie si le lieu a une capacité illimitée
func (r *CreationEvenementRequest) HasCapaciteIllimitee() bool {
    return r.LieuCapacite == nil
}




//============================ REPONSE 

// CreationEvenementResponse représente la réponse après création d'un événement
type CreationEvenementResponse struct {
    ID      string `json:"id"`                // Format UUID
    Message string `json:"message,omitempty"` // Optionnel
}
// EvenementCree représente l'événement créé avec ses relations
type EvenementCree struct {
    EvenementID uuid.UUID `json:"evenement_id"`
    Titre       string    `json:"titre"`
    LieuID      uuid.UUID `json:"lieu_id"`
    LieuNom     string    `json:"lieu_nom"`
    TotalPlaces int       `json:"total_places"`
    TarifsCrees []TarifCree `json:"tarifs_crees"`
    FichiersCrees []FichierCree `json:"fichiers_crees,omitempty"`
}

type TarifCree struct {
    TarifID     uuid.UUID `json:"tarif_id"`
    TypePlace   string    `json:"type_place"`
    Prix        float64   `json:"prix"`
    NombrePlaces int      `json:"nombre_places"`
}

type FichierCree struct {
    FichierID  uuid.UUID `json:"fichier_id"`
    NomFichier string    `json:"nom_fichier"`
    TypeMime   string    `json:"type_mime"`
    TailleBytes int      `json:"taille_bytes"`
}




//========================================


type EvenementStructure struct {
    Evenement      EvenementJSON     `json:"evenement"`
    Lieu           LieuJSON          `json:"lieu"`
    TypeEvenement  TypeEvenementJSON `json:"type_evenement"`
    PlacesParType  map[uuid.UUID]TypePlaceDetail `json:"places_par_type"`
}

type EvenementJSON struct {
    ID          uuid.UUID `json:"id"`
    Titre       string    `json:"titre"`
    Description string    `json:"description"`
    DateDebut   time.Time `json:"date_debut"`
    DateFin     time.Time `json:"date_fin"`
    TypeID      uuid.UUID `json:"type_id"`
}

type LieuJSON struct {
    ID       uuid.UUID `json:"id"`
    Nom      string    `json:"nom"`
    Adresse  string    `json:"adresse"`
    Ville    string    `json:"ville"`
    Capacite *int      `json:"capacite"`
}

type TypeEvenementJSON struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
}

type TypePlaceDetail struct {
    TypePlace TypePlaceJSON `json:"type_place"`
    Tarif     TarifJSON     `json:"tarif"`
    Places    []PlaceJSON   `json:"places"`
}

type TypePlaceJSON struct {
    ID          uuid.UUID `json:"id"`
    Nom         string    `json:"nom"`
    Description string    `json:"description"`
    Avantages   string    `json:"avantages"`
}

type TarifJSON struct {
    ID            uuid.UUID       `json:"id"`
    Prix          decimal.Decimal `json:"prix"`
    NombrePlaces  int             `json:"nombre_places"`
}

type PlaceJSON struct {
    ID               uuid.UUID `json:"id"`
    Numero           string    `json:"numero"`
    EtatCode         string    `json:"etat_code"`
    EtatDescription  string    `json:"etat_description"`
}