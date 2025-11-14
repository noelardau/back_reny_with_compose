package handler

import (
	"encoding/json"
	"net/http"
	"time"

	// "github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/service"
	"github.com/golang-jwt/jwt/v5"
)


type AuthRequest struct {
	Login    string `json:"login"`
	Password string `json:"password"`
}

func AuthHandler(authService *service.AuthentificationService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Décoder la requête JSON
		var req AuthRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Requête invalide", http.StatusBadRequest)
			return
		}

		// Vérifier les credentials
		_, err := authService.VerifierCredentials(req.Login, req.Password)
		if err != nil {
			http.Error(w, "Login ou mot de passe incorrect", http.StatusUnauthorized)
			return
		}

		// Générer le JWT
		token, err := EncodeRenyEvent()
		if err != nil {
			http.Error(w, "Erreur interne", http.StatusInternalServerError)
			return
		}

		// Mettre le cookie dans la réponse
		http.SetCookie(w, &http.Cookie{
			Name:     "auth_token",
			Value:    token,
			Expires:  time.Now().Add(24 * time.Hour),
			HttpOnly: true,
			Secure:   false, // Mettre à true en production
			SameSite: http.SameSiteStrictMode,
			Path:     "/",
		})

		// Réponse succès
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Authentification réussie"))
	}
}


// AuthMiddleware vérifie le cookie JWT
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Récupérer le cookie JWT
		cookie, err := r.Cookie("auth_token")
		if err != nil {
			if err == http.ErrNoCookie {
				http.Error(w, "Cookie d'authentification manquant", http.StatusUnauthorized)
				return
			}
			http.Error(w, "Erreur de lecture du cookie", http.StatusBadRequest)
			return
		}

		// Vérifier le JWT
		_, err = DecodeAndVerify(cookie.Value)
		if err != nil {
			http.Error(w, "Token invalide ou expiré", http.StatusUnauthorized)
			return
		}

		// Si le JWT est valide, passer au handler suivant
		next.ServeHTTP(w, r)
	})
}



// Clé secrète - à mettre dans une variable d'environnement en production
var secretKey = []byte("votre-secret-super-securise")

// EncodeRenyEvent crée un JWT avec le message "reny event"
func EncodeRenyEvent() (string, error) {
	// Créer les claims (payload)
	claims := jwt.MapClaims{
		"message": "reny event",
		"exp":     time.Now().Add(24 * time.Hour).Unix(), // Expiration dans 24h
		"iat":     time.Now().Unix(),                     // Date de création
	}

	// Créer le token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Signer le token avec la clé secrète
	tokenString, err := token.SignedString(secretKey)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}


// DecodeAndVerify décode et vérifie un JWT
func DecodeAndVerify(tokenString string) (string, error) {
	// Parser le token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Vérifier la méthode de signature
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return secretKey, nil
	})

	if err != nil {
		return "", err
	}

	// Vérifier si le token est valide
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// Récupérer le message
		message, ok := claims["message"].(string)
		if !ok {
			return "", jwt.ErrTokenInvalidClaims
		}

		// Vérifier que c'est bien "reny event"
		if message != "reny event" {
			return "", jwt.ErrTokenInvalidClaims
		}

		return message, nil
	}

	return "", jwt.ErrTokenInvalidClaims
}