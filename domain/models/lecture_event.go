package models




type EvenementComplet struct {
	EvenementID              string                 `json:"evenement_id"`
	Titre                    string                 `json:"titre"`
	DescriptionEvenement     *string                `json:"description_evenement"`
	DateDebut                string                 `json:"date_debut"`
	DateFin                  string                 `json:"date_fin"`
	TypeEvenement            TypeEvenement          `json:"type_evenement"`
	Lieu                     Lieu                   `json:"lieu"`
	TarifsEtPlaces           []TarifAvecPlaces      `json:"tarifs_et_places"`
	StatistiquesGlobales     StatistiquesGlobales   `json:"statistiques_globales"`
	Fichiers                 []FichierAvecDonnees   `json:"fichiers"` // Changé ici
	InformationsComplementaires InformationsComplementaires `json:"informations_complementaires"`
}

// Ancienne structure FichierMetadata (à conserver si utilisée ailleurs)
type FichierMetadata struct {
	FichierID   string  `json:"fichier_id"`
	NomFichier  string  `json:"nom_fichier"`
	TypeMime    string  `json:"type_mime"`
	TailleBytes int64   `json:"taille_bytes"`
	TypeFichier string  `json:"type_fichier"`
	DateUpload  string  `json:"date_upload"`
}

// NOUVELLE structure avec données binaires
type FichierAvecDonnees struct {
	FichierID              string  `json:"fichier_id"`
	NomFichier             string  `json:"nom_fichier"`
	TypeMime               string  `json:"type_mime"`
	TailleBytes            int64   `json:"taille_bytes"`
	TypeFichier            string  `json:"type_fichier"`
	DateUpload             string  `json:"date_upload"`
	DonneesBinaireBase64   *string `json:"donnees_binaire_base64,omitempty"` // Nouveau champ
	URLData                *string `json:"url_data,omitempty"`               // Nouveau champ
}

// Mise à jour de InformationsComplementaires pour ajouter les infos fichiers
type InformationsComplementaires struct {
	DureeEvenementMinutes int     `json:"duree_evenement_minutes"`
	JoursRestants         int     `json:"jours_restants"`
	EstPasse              bool    `json:"est_passe"`
	EstActuel             bool    `json:"est_actuel"`
	EstFutur              bool    `json:"est_futur"`
	PrixMinimum           float64 `json:"prix_minimum"`
	PrixMaximum           float64 `json:"prix_maximum"`
	NombreTypesPlaces     int     `json:"nombre_types_places"`
	Statut                string  `json:"statut"`
	NombreFichiers        int     `json:"nombre_fichiers"`        // Nouveau champ
	AAffiche              bool    `json:"a_affiche"`              // Nouveau champ
	APhotos               bool    `json:"a_photos"`               // Nouveau champ
}












//////////////////////

// type EvenementComplet struct {
// 	EvenementID              string                 `json:"evenement_id"`
// 	Titre                    string                 `json:"titre"`
// 	DescriptionEvenement     *string                `json:"description_evenement"`
// 	DateDebut                string                 `json:"date_debut"`
// 	DateFin                  string                 `json:"date_fin"`
// 	TypeEvenement            TypeEvenement          `json:"type_evenement"`
// 	Lieu                     Lieu                   `json:"lieu"`
// 	TarifsEtPlaces           []TarifAvecPlaces      `json:"tarifs_et_places"`
// 	StatistiquesGlobales     StatistiquesGlobales   `json:"statistiques_globales"`
// 	Fichiers                 []FichierMetadata      `json:"fichiers"`
// 	InformationsComplementaires InformationsComplementaires `json:"informations_complementaires"`
// }

// Structures pour le décodage JSON
type TypeEvenement struct {
	ID          string  `json:"type_evenement_id"`
	Nom         string  `json:"type_evenement_nom"`
	Description *string `json:"type_evenement_description"`
}

type Lieu struct {
	ID       string  `json:"lieu_id"`
	Nom      string  `json:"lieu_nom"`
	Adresse  string  `json:"lieu_adresse"`
	Ville    string  `json:"lieu_ville"`
	Capacite *int    `json:"lieu_capacite"`
}

type TarifAvecPlaces struct {
	TarifID           string         `json:"tarif_id"`
	TypePlaceID       string         `json:"type_place_id"`
	TypePlaceNom      string         `json:"type_place_nom"`
	TypePlaceDescription *string     `json:"type_place_description"`
	TypePlaceAvantages *string       `json:"type_place_avantages"`
	Prix              float64        `json:"prix"`
	NombrePlacesTotal int            `json:"nombre_places_total"`
	StatistiquesEtat  StatistiquesEtat `json:"statistiques_etat"`
	Places            []Place        `json:"places"`
}

type Place struct {
	PlaceID     string `json:"place_id"`
	NumeroPlace string `json:"numero_place"`
	Etat        Etat   `json:"etat"`
}

type Etat struct {
	Code        string `json:"etat_code"`
	Description string `json:"etat_description"`
}

type StatistiquesEtat struct {
	PlacesDisponibles int `json:"places_disponibles"`
	PlacesVendues     int `json:"places_vendues"`
	PlacesReservees   int `json:"places_reservees"`
	PlacesAnnulees    int `json:"places_annulees"`
	PlacesMaintenance int `json:"places_maintenance"`
}

type StatistiquesGlobales struct {
	TotalPlaces          int     `json:"total_places"`
	PlacesDisponibles    int     `json:"places_disponibles"`
	PlacesVendues        int     `json:"places_vendues"`
	PlacesReservees      int     `json:"places_reservees"`
	PlacesAnnulees       int     `json:"places_annulees"`
	PlacesMaintenance    int     `json:"places_maintenance"`
	TauxOccupation       float64 `json:"taux_occupation"`
	CapaciteRestante     *int    `json:"capacite_restante"`
	PourcentageRemplissage float64 `json:"pourcentage_remplissage"`
}

// type FichierMetadata struct {
// 	FichierID   string  `json:"fichier_id"`
// 	NomFichier  string  `json:"nom_fichier"`
// 	TypeMime    string  `json:"type_mime"`
// 	TailleBytes int64   `json:"taille_bytes"`
// 	TypeFichier string  `json:"type_fichier"`
// 	DateUpload  string  `json:"date_upload"`
// }

// type InformationsComplementaires struct {
// 	DureeEvenementMinutes int     `json:"duree_evenement_minutes"`
// 	JoursRestants         int     `json:"jours_restants"`
// 	EstPasse              bool    `json:"est_passe"`
// 	EstActuel             bool    `json:"est_actuel"`
// 	EstFutur              bool    `json:"est_futur"`
// 	PrixMinimum           float64 `json:"prix_minimum"`
// 	PrixMaximum           float64 `json:"prix_maximum"`
// 	NombreTypesPlaces     int     `json:"nombre_types_places"`
// 	Statut                string  `json:"statut"`
// }