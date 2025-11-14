

export interface evenement {
   evenement_id: string;
    titre: string;
    description_evenement: string;
    date_debut: string;
    date_fin: string;
    lieu: {
        lieu_nom: string;
        lieu_adresse: string;
    };
    statistiques_globales: {
        total_places: number;
        places_disponibles: number;
        places_vendues: number;
    };
    fichiers: {
        fichier_id: string;
        fichier_url: string;
        fichier_type: string;
    }[];
    type_evenement: {
        type_evenement_id: string;
        type_evenement_nom: string;
    };
}