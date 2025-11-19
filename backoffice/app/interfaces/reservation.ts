

export interface ReservationFormProps {
  evenement_id: string;
  onSubmit?: (data: {
    email: string;
    evenement_id: string;
    places_demandees: { type_place_id: string; nombre: number }[];
  }) => void;
}

export interface newReservation {
  email: string;
  evenement_id: string;
  places_demandees: { type_place_id: string; nombre: number }[];
}

export interface reservation {
  email: string;
  reservation_id: string;
  places_demandees: { type_place_id: string; nombre: number }[];
  etat_reservation: string;
}

// enums pour les états (optionnel mais recommandé)
enum EtatReservation {
  EN_ATTENTE = "en_attente",
  CONFIRMEE = "confirmée",
  ANNULEE = "annulée",
  // Ajoute d'autres états si nécessaire
}

enum EtatPlace {
  RESERVEE = "reservee",
  PAYEE = "payee",
  DISPONIBLE = "disponible",
  // etc.
}

// Interfaces principales
interface TypeEvenement {
  type_evenement_id: string;
  type_evenement_nom: string;
  type_evenement_description: string | null;
}

interface Lieu {
  lieu_id: string;
  lieu_nom: string;
  lieu_adresse: string;
  lieu_ville: string;
  lieu_capacite: number | null;
}

interface TypePlace {
  id: string;
  nom: string;
  description: string;
  avantages: string;
}

interface Tarif {
  id: string;
  prix: number;
  type_place: TypePlace;
}

interface Place {
  place_id: string;
  numero: string;
  etat_code: string;
  etat_description: string;
  tarif: Tarif;
}

interface Evenement {
  id: string;
  titre: string;
  description: string;
  date_debut: string; // ISO string
  date_fin: string;   // ISO string
  type_evenement: TypeEvenement;
  lieu: Lieu;
}

interface Reservation {
  reservation_id: string;
  email: string;
  reference_paiement: string;
  date_reservation: string; // ISO string
  etat: string;
  etat_code: EtatReservation;
  evenement: Evenement;
  places: Place[];
  total: number;
  nombre_places: number;
}

// Export pour une meilleure réutilisation
export type { 
  TypeEvenement, 
  Lieu, 
  TypePlace, 
  Tarif, 
  Place, 
  Evenement, 
  Reservation 
};

export { EtatReservation, EtatPlace };