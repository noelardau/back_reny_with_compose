package application

// import (
// 	"encoding/json"
// 	"fmt"
// 	"net/http"
// 	"strconv"

// 	"github.com/J2d6/reny_event/application/request"
// 	Int "github.com/J2d6/reny_event/domain/interfaces"
// 	"github.com/J2d6/reny_event/domain/models"
// 	"github.com/J2d6/reny_event/domain/service"
// 	"github.com/go-chi/chi/v5"
// 	"github.com/google/uuid"
// )

// type EvenementHandler struct {
// 	service *service.EvenementService
// }

// func NewEvenementHandler(service *service.EvenementService) *EvenementHandler {
// 	return &EvenementHandler{service: service}
// }

// // CreateEvenementHandler gère la création d'événement
// func (h *EvenementHandler) CreateEvenementHandler(w http.ResponseWriter, r *http.Request) {
// 	fmt.Println("IN REQUEST - CREATE")
// 	var apiReq request.CreateEvenementRequest

// 	if err := json.NewDecoder(r.Body).Decode(&apiReq); err != nil {
// 		h.sendError(w, http.StatusBadRequest, "Format JSON invalide")
// 		return
// 	}

// 	internalReq := h.transformToInternalModel(apiReq)
// 	evenementID, err := h.service.CreerEvenement(r.Context(), internalReq)
// 	if err != nil {
// 		h.sendError(w, http.StatusBadRequest, err.Error())
// 		return
// 	}

// 	response := map[string]interface{}{
// 		"id":      evenementID,
// 		"message": "Événement créé avec succès",
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusCreated)
// 	json.NewEncoder(w).Encode(response)
// }

// // GetEvenementHandler gère la lecture d'événement
// func (h *EvenementHandler) GetEvenementHandler(w http.ResponseWriter, r *http.Request) {
// 	fmt.Println("IN REQUEST - GET")

// 	idParam := chi.URLParam(r, "id")
// 	evenementID, err := uuid.Parse(idParam)
// 	if err != nil {
// 		h.sendError(w, http.StatusBadRequest, "ID d'événement invalide")
// 		return
// 	}

// 	evenement, err := h.service.GetEvenementDetail(r.Context(), evenementID)
// 	if err != nil {
// 		h.sendError(w, http.StatusInternalServerError, "Erreur lors de la récupération de l'événement: "+err.Error())
// 		return
// 	}

// 	if evenement == nil {
// 		h.sendError(w, http.StatusNotFound, "Événement non trouvé")
// 		return
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusOK)
// 	json.NewEncoder(w).Encode(evenement)
// }

// // GetFichierContenuHandler gère le téléchargement de fichier
// // func (h *EvenementHandler) GetFichierContenuHandler(w http.ResponseWriter, r *http.Request) {
// // 	fmt.Println("IN REQUEST - GET FICHIER CONTENU")

// // 	evenementIDParam := chi.URLParam(r, "evenementId")
// // 	fichierIDParam := chi.URLParam(r, "fichierId")

// // 	evenementID, err := uuid.Parse(evenementIDParam)
// // 	if err != nil {
// // 		h.sendError(w, http.StatusBadRequest, "ID d'événement invalide")
// // 		return
// // 	}

// // 	fichierID, err := uuid.Parse(fichierIDParam)
// // 	if err != nil {
// // 		h.sendError(w, http.StatusBadRequest, "ID de fichier invalide")
// // 		return
// // 	}

// // 	contenu, err := h.service.GetFichierContenu(r.Context(), evenementID, fichierID)
// // 	if err != nil {
// // 		h.sendError(w, http.StatusInternalServerError, "Erreur lors de la récupération du fichier: "+err.Error())
// // 		return
// // 	}

// // 	if contenu == nil {
// // 		h.sendError(w, http.StatusNotFound, "Fichier non trouvé")
// // 		return
// // 	}

// // 	w.Header().Set("Content-Type", contenu.TypeMime)
// // 	w.Header().Set("Content-Length", strconv.FormatInt(contenu.TailleBytes, 10))
// // 	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", contenu.NomFichier))
// // 	w.Header().Set("Cache-Control", "public, max-age=3600")

// // 	w.WriteHeader(http.StatusOK)
// // 	w.Write(contenu.DonneesBinaire)
// // }

// // func (h *EvenementHandler) transformToInternalModel(apiReq request.CreateEvenementRequest) models.CreationEvenementRequest {
// // 	tarifs := make([]models.TarifInput, len(apiReq.Tarifs))
// // 	for i, tarifReq := range apiReq.Tarifs {
// // 		typePlaceID := Int.TypePlaceIDMap[tarifReq.TypePlace]
// // 		tarifs[i] = models.TarifInput{
// // 			TypePlaceID:  uuid.MustParse(typePlaceID),
// // 			Prix:         tarifReq.Prix,
// // 			NombrePlaces: tarifReq.NombrePlaces,
// // 		}
// // 	}

// // 	fichiers := make([]models.FichierInput, len(apiReq.Fichiers))
// // 	for i, fichierReq := range apiReq.Fichiers {
// // 		fichiers[i] = models.FichierInput{
// // 			NomFichier:    fichierReq.NomFichier,
// // 			TypeMime:      fichierReq.TypeMime,
// // 			TypeFichier:   fichierReq.TypeFichier,
// // 			DonneesBase64: fichierReq.DonneesBase64,
// // 		}
// // 	}

// // 	return models.CreationEvenementRequest{
// // 		Type_evenement: apiReq.TypeEvenement,
// // 		Titre:          apiReq.Titre,
// // 		Description:    apiReq.Description,
// // 		DateDebut:      apiReq.DateDebut,
// // 		DateFin:        apiReq.DateFin,
// // 		Lieu: models.LieuInput{
// // 			Nom:      apiReq.Lieu.Nom,
// // 			Adresse:  apiReq.Lieu.Adresse,
// // 			Ville:    apiReq.Lieu.Ville,
// // 			Capacite: apiReq.Lieu.Capacite,
// // 		},
// // 		Tarifs:   tarifs,
// // 		Fichiers: fichiers,
// // 	}
// // }

// func (h *EvenementHandler) sendError(w http.ResponseWriter, status int, message string) {
// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(status)
// 	json.NewEncoder(w).Encode(map[string]string{
// 		"error": message,
// 	})
// }