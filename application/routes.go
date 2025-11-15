package application

import (
	"github.com/J2d6/reny_event/application/handler"
	"github.com/J2d6/reny_event/domain/interfaces"
	"github.com/J2d6/reny_event/domain/service"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
)

func SetupRoutes(r chi.Router, evenementService interfaces.EvenementService, authService *service.AuthentificationService) {

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"https://*", "http://*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           86400,
	}))

	// Route d'authentification (publique)
	r.Post("/auth", handler.AuthHandler(authService))

	r.Route("/v1", func(r chi.Router) {
		// Routes publiques
		r.Get("/evenements/{id}", handler.GetEvenementByIDHandler(evenementService))
		r.Get("/evenements/reservations/{id}", handler.AllReservationsHandler(evenementService))
		r.Post("/reservations", handler.ReserverHandler(evenementService))

		// Routes protégées (nécessitent une authentification)
		// r.Group(func(r chi.Router) {
		// r.Use(handler.AuthMiddleware) // Applique le middleware d'auth à toutes les routes de ce groupe
		r.Post("/evenements", handler.CreationEvenementHandler(evenementService))
		r.Post("/reservations/validate/{id}", handler.ValiderReservation(evenementService))
		r.Get("/evenements/all", handler.GetAllEvents(evenementService))
		// })
	})
}
