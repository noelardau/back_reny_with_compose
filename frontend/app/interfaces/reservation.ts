

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