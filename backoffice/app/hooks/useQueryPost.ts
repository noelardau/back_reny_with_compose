import { useMutation, useQueryClient } from '@tanstack/react-query';

type PlaceDemandee = {
  type_place_id: string;
  nombre: number;
};

type ReservationPayload = {
  email: string;
  evenement_id: string;
  places_demandees: PlaceDemandee[];
};

// const postReservation = async (payload: ReservationPayload) => {
//   const res = await fetch('http://localhost:4000/v1/reservations', {
//     method: 'POST',
//     headers: {
//       'Content-Type': 'application/json',
//     },
//     body: JSON.stringify(payload),
//   });

//   if (!res.ok) {
//     const error = await res.json().catch(() => ({ message: 'Erreur serveur' }));
//     throw new Error(error.message || 'Échec de la réservation');
//   }

//   return res.json();
// };

export function useQueryPost(api_url:string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (payload:ReservationPayload) => {
  const res = await fetch(api_url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: 'Erreur serveur' }));
    throw new Error(error.message || 'Échec de la réservation');
  }

  return res.json();
},
    onSuccess: () => {
      // Invalide le cache des réservations si besoin
      queryClient.invalidateQueries({ queryKey: ['reservations'] });

      alert('Réservation réussie !');
    },
    onError: (error: Error) => {
      alert(`Erreur lors de la réservation : ${error.message}`);
    },
  });
}