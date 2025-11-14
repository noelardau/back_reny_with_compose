package models

// import (
// 	"encoding/json"
// 	"time"

// 	"github.com/google/uuid"
// )

// type CreationEvenementRequest struct {
//     // Données événement
//     Type_evenement string    `json:"type_id"`
//     Titre       string       `json:"titre"`
//     Description string       `json:"description"`
//     DateDebut   time.Time    `json:"date_debut"`
//     DateFin     time.Time    `json:"date_fin"`
    
    
//     Lieu        LieuInput    `json:"lieu"`
    
 
//     Tarifs      []TarifInput `json:"tarifs"`
    
   
//     Fichiers    []FichierInput `json:"fichiers,omitempty"`
// }

// type FichierInput struct {
//     NomFichier  string `json:"nom_fichier"`
//     TypeMime    string `json:"type_mime"`
//     TypeFichier string `json:"type_fichier"` // 'photo', 'affiche', 'document'
//     DonneesBase64 string `json:"donnees_base64"` // Fichier encodé en base64
// }




// type EvenementRow struct {
//     EvenementID    uuid.UUID       `db:"evenement_id"`
//     Titre          string          `db:"titre"`
//     Description    string          `db:"description_evenement"`
//     DateDebut      time.Time       `db:"date_debut"`  
//     DateFin        time.Time       `db:"date_fin"`   
//     TypeEvenement  json.RawMessage `db:"type_evenement"`
//     Lieu           json.RawMessage `db:"lieu"`
//     Tarifs         json.RawMessage `db:"tarifs"`
//     Fichiers       json.RawMessage `db:"fichiers"`
//     Statistiques   json.RawMessage `db:"statistiques"`
// }

// type EvenementDetail struct {
//     ID          uuid.UUID         `json:"id"`
//     Titre       string            `json:"titre"`
//     Description string            `json:"description"`
//     DateDebut   time.Time         `json:"date_debut"`
//     DateFin     time.Time         `json:"date_fin"`
//     Type        TypeEvenement     `json:"type_evenement"`
//     Lieu        LieuDetail        `json:"lieu"`
//     Tarifs      []TarifDetail     `json:"tarifs"`
//     Fichiers    []FichierInfo     `json:"fichiers"`
//     Statistiques EvenementStats   `json:"statistiques"`
// }


// type LieuDetail struct {
//     ID       uuid.UUID `json:"id"`
//     Nom      string    `json:"nom"`
//     Adresse  string    `json:"adresse"`
//     Ville    string    `json:"ville"`
//     Capacite int       `json:"capacite"`
// }


// type TarifDetail struct {
//     ID           uuid.UUID      `json:"id"`
//     Prix         float64        `json:"prix"`
//     NombrePlaces int            `json:"nombre_places"`
//     TypePlace    TypePlace      `json:"type_place"`
//     Statistiques TarifStats     `json:"statistiques"`
// }


// type TarifStats struct {
//     Total       int `json:"total"`
//     Disponibles int `json:"disponibles"`
//     Reservees   int `json:"reservees"`
//     Vendues     int `json:"vendues"`
//     Inactives   int `json:"inactives"`
// }


// type FichierInfo struct {
//     ID          uuid.UUID `json:"id"`
//     NomFichier  string    `json:"nom_fichier"`
//     TypeMime    string    `json:"type_mime"`
//     TypeFichier string    `json:"type_fichier"`
//     TailleBytes int64     `json:"taille_bytes"`
//     DateUpload  time.Time `json:"date_upload"`
//     UrlContenu  string    `json:"url_contenu"`
// }


// type EvenementStats struct {
//     TotalPlaces       int     `json:"total_places"`
//     PlacesDisponibles int     `json:"places_disponibles"`
//     PlacesReservees   int     `json:"places_reservees"`
//     PlacesVendues     int     `json:"places_vendues"`
//     TauxOccupation    float64 `json:"taux_occupation"`
// }


// type TypeEvenement struct {
//     ID          uuid.UUID `json:"id"`
//     Nom         string    `json:"nom"`
//     Description string    `json:"description"`
// }


// type TypePlace struct {
//     ID          uuid.UUID `json:"id"`
//     Nom         string    `json:"nom"`
//     Description string    `json:"description"`
//     Avantages   string    `json:"avantages"`
// }



