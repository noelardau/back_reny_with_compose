package models

import "github.com/google/uuid"


type Utilisateur struct {
    ID         uuid.UUID `json:"id"`
    Login      string    `json:"login"`
    MotDePasse string    `json:"-"` // Le "-" cache le mot de passe en JSON
}


type CreationUtilisateurRequest struct {
    Login      string `json:"login"`
    MotDePasse string `json:"mot_de_passe"`
}

 
type ConnexionRequest struct {
    Login      string `json:"login"`
    MotDePasse string `json:"mot_de_passe"`
}


type RequeteConnexion struct {
	Login      string `json:"login"`
	MotDePasse string `json:"mot_de_passe"`
}

// ReponseConnexion avec token (à implémenter plus tard)
type ReponseConnexion struct {
	Utilisateur *Utilisateur `json:"utilisateur"`
	Message     string       `json:"message"`
}

// RequeteCreationUtilisateur pour créer un utilisateur
type RequeteCreationUtilisateur struct {
	Login      string `json:"login"`
	MotDePasse string `json:"mot_de_passe"`
}

// ReponseCreationUtilisateur après création
type ReponseCreationUtilisateur struct {
	ID      string `json:"id"`
	Login   string `json:"login"`
	Message string `json:"message"`
}