

export const API_BASE_URL = "http://localhost:3000/v1";
// export const API_BASE_URL = "https://backend-reny-event.onrender.com/v1";

export const api_paths = {
    createEvenement : `${API_BASE_URL}/evenements`, 
    getEvenementbyid : (id_event:string) => `${API_BASE_URL}/evenements/${id_event}`,
    getAllEvenements : `${API_BASE_URL}/evenements/all`,
    createReservation : `${API_BASE_URL}/reservations`,
    getAllReservationsByEvent : (id_event:string) => `${API_BASE_URL}/evenements/reservations/${id_event}`,
    postReservation: `${API_BASE_URL}/reservations`,
    validateReservation: (id_reservation:string) => `${API_BASE_URL}/reservations/validate/${id_reservation}`,
    getReservationById: (id_reservation:string) => `${API_BASE_URL}/reservation/${id_reservation}`,
    getTypePlace: `${API_BASE_URL}/type_places`,
    getTypeEvenement: `${API_BASE_URL}/type_evenements`,
}

