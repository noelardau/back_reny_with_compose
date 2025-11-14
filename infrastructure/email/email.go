package infrastructure

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"text/template"
	"github.com/J2d6/reny_event/domain/models"
	"gopkg.in/gomail.v2"
)


func SendGomail(reservationInfos models.ReservationDetails)  {
	cwd, err := os.Getwd()
	if err != nil {
	   panic(err)
	}
	templatePath := filepath.Join(cwd, "template.html")
	var body bytes.Buffer
	t, err := template.ParseFiles(templatePath)
	if err != nil {
		panic(err)
	}	
	t.Execute(&body,reservationInfos)

	CreateQR()
	// fmt.Println("CREATE QR")
	m := gomail.NewMessage()
	m.SetHeader("From", "j2d6.pro@gmail.com")
	m.SetHeader("To",reservationInfos.Email)
	m.SetHeader("Subject", "CONFIRMATION DE RESERVATION")
	m.SetBody("text/html", body.String())
	m.Attach("qr.png")

	d := gomail.NewDialer("smtp.gmail.com", 587, "j2d6.pro@gmail.com", "mgyp eska udfh tilp")

	if err := d.DialAndSend(m); err != nil {
		panic(err)
	}

	fmt.Println("MAIL SENT")
}






// package main

// import (
// 	"bytes"
// 	"fmt"
// 	"html/template"
// 	"time"
// )

// // Fonctions custom pour le template
// var templateFuncs = template.FuncMap{
// 	"formatDate": func(t time.Time, layout string) string {
// 		return t.Format(layout)
// 	},
// 	"slice": func(s string, start, end int) string {
// 		if len(s) < end {
// 			return s
// 		}
// 		return s[start:end]
// 	},
// }

// // RenderTicket génère le HTML du billet
// func RenderTicket(details *ReservationDetails) (string, error) {
// 	// Parse le template
// 	tmpl, err := template.New("ticket").Funcs(templateFuncs).Parse(ticketTemplate)
// 	if err != nil {
// 		return "", fmt.Errorf("erreur parsing template: %w", err)
// 	}

// 	// Execute le template
// 	var buf bytes.Buffer
// 	if err := tmpl.Execute(&buf, details); err != nil {
// 		return "", fmt.Errorf("erreur execution template: %w", err)
// 	}

// 	return buf.String(), nil
// }

// // Handler HTTP pour télécharger le billet
// func (h *ReservationHandler) DownloadTicketHandler(w http.ResponseWriter, r *http.Request) {
// 	reservationID := r.PathValue("id")
	
// 	// Récupérer les détails de la réservation
// 	details, err := h.repo.GetReservationByID(r.Context(), reservationID)
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusNotFound)
// 		return
// 	}

// 	// Générer le HTML du billet
// 	htmlContent, err := RenderTicket(details)
// 	if err != nil {
// 		http.Error(w, "Erreur génération billet", http.StatusInternalServerError)
// 		return
// 	}

// 	// Définir les headers pour le téléchargement
// 	w.Header().Set("Content-Type", "text/html")
// 	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=billet-%s.html", reservationID))
	
// 	// Écrire le contenu
// 	w.Write([]byte(htmlContent))
// }

// // Handler pour prévisualiser le billet
// func (h *ReservationHandler) PreviewTicketHandler(w http.ResponseWriter, r *http.Request) {
// 	reservationID := r.PathValue("id")
	
// 	details, err := h.repo.GetReservationByID(r.Context(), reservationID)
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusNotFound)
// 		return
// 	}

// 	htmlContent, err := RenderTicket(details)
// 	if err != nil {
// 		http.Error(w, "Erreur génération billet", http.StatusInternalServerError)
// 		return
// 	}

// 	w.Header().Set("Content-Type", "text/html")
// 	w.Write([]byte(htmlContent))
// }
