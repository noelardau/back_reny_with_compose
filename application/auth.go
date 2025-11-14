package application

// import (
// 	"context"
// 	"encoding/json"
// 	"fmt"
// 	"net/http"
// 	"time"

// 	"github.com/J2d6/reny_event/domain/models"
// 	"github.com/J2d6/reny_event/domain/service"
// 	"github.com/golang-jwt/jwt/v5"
// 	"github.com/google/uuid"
// )

// type AuthHandler struct {
// 	authService *service.AuthentificationService
// 	jwtSecret   []byte
// }

// func NewAuthHandler(authService *service.AuthentificationService, jwtSecret string) *AuthHandler {
// 	return &AuthHandler{
// 		authService: authService,
// 		jwtSecret:   []byte(jwtSecret),
// 	}
// }

// // ConnexionHandler gère la connexion et génère un JWT
// func (h *AuthHandler) ConnexionHandler(w http.ResponseWriter, r *http.Request) {
// 	fmt.Println("IN REQUEST - CONNEXION")

// 	var req models.RequeteConnexion
// 	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
// 		h.sendError(w, http.StatusBadRequest, "Format JSON invalide")
// 		return
// 	}

// 	// Authentifier l'utilisateur
// 	utilisateur, err := h.authService.AuthentifierUtilisateur(r.Context(), req.Login, req.MotDePasse)
// 	if err != nil {
// 		h.sendError(w, http.StatusUnauthorized, err.Error())
// 		return
// 	}

// 	// Générer le JWT
// 	token, err := h.genererJWT(utilisateur)
// 	if err != nil {
// 		h.sendError(w, http.StatusInternalServerError, "Erreur génération token")
// 		return
// 	}

// 	// Créer le cookie HTTP-only
// 	cookie := &http.Cookie{
// 		Name:     "session_token",
// 		Value:    token,
// 		Path:     "/",
// 		HttpOnly: true,
// 		Secure:   false, // true en production avec HTTPS
// 		SameSite: http.SameSiteStrictMode,
// 		Expires:  time.Now().Add(24 * time.Hour), // 24 heures
// 	}
// 	http.SetCookie(w, cookie)

// 	// Réponse JSON
// 	response := map[string]interface{}{
// 		"message":     "Connexion réussie",
// 		"utilisateur": utilisateur,
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusOK)
// 	json.NewEncoder(w).Encode(response)
// }

// // DeconnexionHandler gère la déconnexion
// func (h *AuthHandler) DeconnexionHandler(w http.ResponseWriter, r *http.Request) {
// 	fmt.Println("IN REQUEST - DÉCONNEXION")

// 	// Supprimer le cookie
// 	cookie := &http.Cookie{
// 		Name:     "session_token",
// 		Value:    "",
// 		Path:     "/",
// 		HttpOnly: true,
// 		Secure:   false,
// 		SameSite: http.SameSiteStrictMode,
// 		Expires:  time.Now().Add(-1 * time.Hour), // Date dans le passé
// 		MaxAge:   -1,
// 	}
// 	http.SetCookie(w, cookie)

// 	response := map[string]string{
// 		"message": "Déconnexion réussie",
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusOK)
// 	json.NewEncoder(w).Encode(response)
// }

// // MiddlewareAuth vérifie le JWT dans les cookies
// func (h *AuthHandler) MiddlewareAuth(next http.Handler) http.Handler {
// 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
// 		fmt.Println("MIDDLEWARE AUTH - Vérification JWT")

// 		// Récupérer le cookie
// 		cookie, err := r.Cookie("session_token")
// 		if err != nil {
// 			h.sendError(w, http.StatusUnauthorized, "Token manquant")
// 			return
// 		}

// 		// Valider le JWT
// 		claims, err := h.validerJWT(cookie.Value)
// 		if err != nil {
// 			h.sendError(w, http.StatusUnauthorized, "Token invalide")
// 			return
// 		}

// 		// Ajouter les claims au contexte
// 		ctx := context.WithValue(r.Context(), "user_claims", claims)
// 		next.ServeHTTP(w, r.WithContext(ctx))
// 	})
// }

// // genererJWT génère un token JWT pour l'utilisateur
// func (h *AuthHandler) genererJWT(utilisateur *models.Utilisateur) (string, error) {
// 	claims := jwt.MapClaims{
// 		"user_id": utilisateur.ID.String(),
// 		"login":   utilisateur.Login,
// 		"exp":     time.Now().Add(24 * time.Hour).Unix(),
// 		"iat":     time.Now().Unix(),
// 	}

// 	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
// 	return token.SignedString(h.jwtSecret)
// }

// // validerJWT valide et parse un token JWT
// func (h *AuthHandler) validerJWT(tokenString string) (jwt.MapClaims, error) {
// 	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
// 		// Vérifier la méthode de signature
// 		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
// 			return nil, fmt.Errorf("méthode de signature inattendue: %v", token.Header["alg"])
// 		}
// 		return h.jwtSecret, nil
// 	})

// 	if err != nil {
// 		return nil, err
// 	}

// 	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
// 		return claims, nil
// 	}

// 	return nil, fmt.Errorf("token invalide")
// }

// // GetUserFromContext récupère l'utilisateur depuis le contexte
// func (h *AuthHandler) GetUserFromContext(ctx context.Context) (*models.Utilisateur, error) {
// 	claims, ok := ctx.Value("user_claims").(jwt.MapClaims)
// 	if !ok {
// 		return nil, fmt.Errorf("aucun utilisateur dans le contexte")
// 	}

// 	userIDStr, ok := claims["user_id"].(string)
// 	if !ok {
// 		return nil, fmt.Errorf("ID utilisateur invalide dans le token")
// 	}

// 	userID, err := uuid.Parse(userIDStr)
// 	if err != nil {
// 		return nil, fmt.Errorf("ID utilisateur invalide")
// 	}

// 	login, ok := claims["login"].(string)
// 	if !ok {
// 		return nil, fmt.Errorf("login invalide dans le token")
// 	}

// 	return &models.Utilisateur{
// 		ID:    userID,
// 		Login: login,
// 	}, nil
// }

// func (h *AuthHandler) sendError(w http.ResponseWriter, status int, message string) {
// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(status)
// 	json.NewEncoder(w).Encode(map[string]string{
// 		"error": message,
// 	})
// }