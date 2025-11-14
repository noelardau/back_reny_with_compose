package models

type LieuInput struct {
    Nom      string `json:"nom"`
    Adresse  string `json:"adresse"`
    Ville    string `json:"ville"`
    Capacite int    `json:"capacite"`
}
