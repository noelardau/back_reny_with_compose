// Types de base
type UUID = string;
type ISODateString = string;

// État d'une place
interface EtatPlace {
  etat_code: 'disponible' | 'reservee' | 'vendue' | 'annulee' | 'maintenance';
  etat_description: string;
}

// Place individuelle
interface Place {
  place_id: UUID;
  numero_place: string;
  etat: EtatPlace;
}

// Type d'événement
interface TypeEvenement {
  type_evenement_id: UUID;
  type_evenement_nom: string;
  type_evenement_description: string;
}

// Lieu de l'événement
interface Lieu {
  lieu_id: UUID;
  lieu_nom: string;
  lieu_adresse: string;
  lieu_ville: string;
  lieu_capacite: number;
}

// Statistiques des places pour un tarif
interface StatistiquesEtat {
  places_disponibles: number;
  places_vendues: number;
  places_reservees: number;
  places_annulees: number;
  places_maintenance: number;
}

// Type de place (ex: Standard, VIP, etc.)
interface TypePlace {
  type_place_id: UUID;
  type_place_nom: string;
  type_place_description: string;
  type_place_avantages: string;
}

// Tarif avec places associées
interface TarifEtPlaces {
  tarif_id: UUID;
  type_place_id: UUID;
  type_place_nom: string;
  type_place_description: string;
  type_place_avantages: string;
  prix: number;
  nombre_places_total: number;
  statistiques_etat: StatistiquesEtat;
  places: Place[];
}

// Fichier (affiche, image, etc.)
interface Fichier {
  fichier_id: UUID;
  nom_fichier: string;
  type_mime: string;
  taille_bytes: number;
  type_fichier: 'affiche' | 'image' | 'document' | string;
  date_upload: ISODateString;
  donnees_binaire: string; // Base64
}

// Statistiques globales de l'événement
interface StatistiquesGlobales {
  total_places: number;
  places_disponibles: number;
  places_vendues: number;
  places_reservees: number;
  places_annulees: number;
  places_maintenance: number;
  taux_occupation: number;
  capacite_restante: number;
  pourcentage_remplissage: number;
}

// Informations complémentaires
interface InformationsComplementaires {
  duree_evenement_minutes: number;
  jours_restants: number;
  est_passe: boolean;
  est_actuel: boolean;
  est_futur: boolean;
  prix_minimum: number;
  prix_maximum: number;
  nombre_types_places: number;
  statut: 'a_venir' | 'en_cours' | 'termine' | string;
}

// Interface principale de l'événement
interface evenement {
  evenement_id: UUID;
  titre: string;
  description_evenement: string;
  date_debut: ISODateString;
  date_fin: ISODateString;
  type_evenement: TypeEvenement;
  lieu: Lieu;
  tarifs_et_places: TarifEtPlaces[];
  statistiques_globales: StatistiquesGlobales;
  fichiers: Fichier[];
  informations_complementaires: InformationsComplementaires;
}

// Export pour utilisation
export type { evenement, Place, TarifEtPlaces, StatistiquesGlobales };