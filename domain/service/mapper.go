package service

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/J2d6/reny_event/domain/models"

	"github.com/google/uuid"
)

// CreationEvenementMapper map une requête HTTP vers CreationEvenementRequest
func CreationEvenementMapper(r *http.Request) (*models.CreationEvenementRequest, *HTTPError) {
	
	// Lire le corps de la requête
	body, err := io.ReadAll(r.Body)
	if err != nil {
		return nil, &HTTPError{
			StatusCode: http.StatusBadRequest,
			Message:    "Erreur de lecture du corps de la requête",
		}
	}
	defer r.Body.Close()

	// Parser le JSON
	var rawData map[string]interface{}
	if err := json.Unmarshal(body, &rawData); err != nil {
		return nil, &HTTPError{
			StatusCode: http.StatusBadRequest,
			Message:    "JSON invalide",
		}
	}

	// Valider et construire la requête
	req, err := buildCreationEvenementRequest(rawData)
	if err != nil {
		return nil, &HTTPError{
			StatusCode: http.StatusBadRequest,
			Message:    err.Error(),
		}
	}

	// Valider avec la méthode Validate du struct
	if err := req.Validate(); err != nil {
		return nil, &HTTPError{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf("Validation échouée: %v", err),
		}
	}

	return req, nil
}



// buildCreationEvenementRequest construit la requête à partir des données brutes
func buildCreationEvenementRequest(body map[string]interface{}) (*models.CreationEvenementRequest, error) {
	req := &models.CreationEvenementRequest{}

	// Valider les champs requis
	if err := validateRequiredFields(body); err != nil {
		return nil, err
	}

	// Champs de base
	req.Titre = body["titre"].(string)
	
	if description, exists := body["description"]; exists && description != nil {
		req.Description = description.(string)
	}

	// Dates
	if err := parseDates(body, req); err != nil {
		return nil, err
	}

	// Type ID
	if err := parseTypeID(body, req); err != nil {
		return nil, err
	}

	// Lieu
	if err := parseLieu(body, req); err != nil {
		return nil, err
	}

	// Tarifs
	if err := parseTarifs(body, req); err != nil {
		return nil, err
	}

	// Fichiers (optionnel)
	if err := parseFichiers(body, req); err != nil {
		return nil, err
	}

	return req, nil
}

// validateRequiredFields valide les champs requis
func validateRequiredFields(body map[string]interface{}) error {
	requiredFields := []string{
		"titre", 
		"date_debut", 
		"date_fin", 
		"type_id",
		"lieu_nom", 
		"lieu_adresse", 
		"lieu_ville",
		"tarifs",
	}

	for _, field := range requiredFields {
		value, exists := body[field]
		if !exists || value == nil {
			return fmt.Errorf("champ requis manquant: %s", field)
		}
	}

	return nil
}

// parseDates parse les dates de début et fin
func parseDates(body map[string]interface{}, req *models.CreationEvenementRequest) error {
	dateDebutStr, ok := body["date_debut"].(string)
	if !ok {
		return fmt.Errorf("date_debut doit être une chaîne")
	}

	dateDebut, err := time.Parse(time.RFC3339, dateDebutStr)
	if err != nil {
		return fmt.Errorf("format de date_debut invalide: %v", err)
	}
	req.DateDebut = dateDebut

	dateFinStr, ok := body["date_fin"].(string)
	if !ok {
		return fmt.Errorf("date_fin doit être une chaîne")
	}

	dateFin, err := time.Parse(time.RFC3339, dateFinStr)
	if err != nil {
		return fmt.Errorf("format de date_fin invalide: %v", err)
	}
	req.DateFin = dateFin

	return nil
}

// parseTypeID parse le type ID
func parseTypeID(body map[string]interface{}, req *models.CreationEvenementRequest) error {
	typeIDStr, ok := body["type_id"].(string)
	if !ok {
		return fmt.Errorf("type_id doit être une chaîne UUID")
	}

	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		return fmt.Errorf("type_id invalide: %v", err)
	}
	req.TypeID = typeID

	return nil
}

// parseLieu parse les informations du lieu
func parseLieu(body map[string]interface{}, req *models.CreationEvenementRequest) error {
	req.LieuNom = body["lieu_nom"].(string)
	req.LieuAdresse = body["lieu_adresse"].(string)
	req.LieuVille = body["lieu_ville"].(string)

	if capacite, exists := body["lieu_capacite"]; exists && capacite != nil {
		capFloat, ok := capacite.(float64) // JSON numbers sont float64
		if !ok {
			return fmt.Errorf("lieu_capacite doit être un nombre")
		}
		capInt := int(capFloat)
		req.LieuCapacite = &capInt
	}

	return nil
}

// parseTarifs parse les tarifs
func parseTarifs(body map[string]interface{}, req *models.CreationEvenementRequest) error {
	tarifsData, ok := body["tarifs"].([]interface{})
	if !ok {
		return fmt.Errorf("tarifs doit être un tableau")
	}

	if len(tarifsData) == 0 {
		return fmt.Errorf("au moins un tarif est requis")
	}

	req.Tarifs = make([]models.TarifRequest, len(tarifsData))

	for i, tarifData := range tarifsData {
		tarifMap, ok := tarifData.(map[string]interface{})
		if !ok {
			return fmt.Errorf("élément tarif invalide à l'index %d", i)
		}

		tarif, err := parseTarifRequest(tarifMap)
		if err != nil {
			return fmt.Errorf("tarif invalide à l'index %d: %v", i, err)
		}

		req.Tarifs[i] = *tarif
	}

	return nil
}

// parseTarifRequest parse un tarif individuel
func parseTarifRequest(tarifMap map[string]interface{}) (*models.TarifRequest, error) {
	tarif := &models.TarifRequest{}

	// TypePlaceID
	typePlaceIDStr, ok := tarifMap["type_place_id"].(string)
	if !ok {
		return nil, fmt.Errorf("type_place_id requis")
	}
	typePlaceID, err := uuid.Parse(typePlaceIDStr)
	if err != nil {
		return nil, fmt.Errorf("type_place_id invalide: %v", err)
	}
	tarif.TypePlaceID = typePlaceID

	// Prix
	prix, ok := tarifMap["prix"].(float64)
	if !ok {
		return nil, fmt.Errorf("prix requis et doit être un nombre")
	}
	tarif.Prix = prix

	// NombrePlaces
	nombrePlaces, ok := tarifMap["nombre_places"].(float64)
	if !ok {
		return nil, fmt.Errorf("nombre_places requis et doit être un nombre")
	}
	tarif.NombrePlaces = int(nombrePlaces)

	return tarif, nil
}

// parseFichiers parse les fichiers (optionnel)
func parseFichiers(body map[string]interface{}, req *models.CreationEvenementRequest) error {
	if fichiersData, exists := body["fichiers"]; exists && fichiersData != nil {
		fichiersArray, ok := fichiersData.([]interface{})
		if !ok {
			return fmt.Errorf("fichiers doit être un tableau")
		}

		req.Fichiers = make([]models.FichierRequest, len(fichiersArray))

		for i, fichierData := range fichiersArray {
			fichierMap, ok := fichierData.(map[string]interface{})
			if !ok {
				return fmt.Errorf("élément fichier invalide à l'index %d", i)
			}

			fichier, err := parseFichierRequest(fichierMap)
			if err != nil {
				return fmt.Errorf("fichier invalide à l'index %d: %v", i, err)
			}

			req.Fichiers[i] = *fichier
		}
	}

	return nil
}

// parseFichierRequest parse un fichier individuel avec conversion base64 -> []byte
func parseFichierRequest(fichierMap map[string]interface{}) (*models.FichierRequest, error) {
	fichier := &models.FichierRequest{}

	// Champs requis
	requiredFields := []string{"nom_fichier", "type_mime", "type_fichier", "donnees_bytea"}
	for _, field := range requiredFields {
		if _, exists := fichierMap[field]; !exists {
			return nil, fmt.Errorf("%s requis", field)
		}
	}

	fichier.NomFichier = fichierMap["nom_fichier"].(string)
	fichier.TypeMime = fichierMap["type_mime"].(string)
	
	// TypeFichier avec validation
	typeFichier := fichierMap["type_fichier"].(string)
	if typeFichier != "photo" && typeFichier != "affiche" && typeFichier != "document" {
		return nil, fmt.Errorf("type_fichier doit être 'photo', 'affiche' ou 'document'")
	}
	fichier.TypeFichier = typeFichier

	// Conversion base64 -> []byte
	donneesBase64 := fichierMap["donnees_bytea"].(string)
	donneesBytea, err := base64.StdEncoding.DecodeString(donneesBase64)
	if err != nil {
		return nil, fmt.Errorf("donnees_bytea invalide (format base64 attendu): %v", err)
	}
	fichier.DonneesBytea = donneesBytea

	return fichier, nil
}




// // Handler HTTP complet
// func CreationEvenementHandler(w http.ResponseWriter, r *http.Request) {
// 	// Mapper la requête
	
// 	if httpErr != nil {
// 		w.Header().Set("Content-Type", "application/json")
// 		w.WriteHeader(httpErr.StatusCode)
// 		json.NewEncoder(w).Encode(models.CreationEvenementResponse{
// 			Success: false,
// 			Message: httpErr.Message,
// 		})
// 		return
// 	}

// 	// Ici, vous traiteriez la création dans votre service
// 	// eventService.CreateEvenement(creationReq)

// 	// Réponse de succès
// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusCreated)
// 	json.NewEncoder(w).Encode(models.CreationEvenementResponse{
// 		Success:     true,
// 		Message:     "Événement créé avec succès",
// 		EvenementID: uuid.New(),
// 	})
// }