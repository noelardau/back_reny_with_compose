package repository


var (

    GET_ALL_EVENETS_QUERY = `SELECT obtenir_tous_evenements() as evenements;`
    CREATE_EVENEMENT_COMPLET_QUERY string = `
       SELECT creer_evenement_complet($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    `

    FIND_EVENEMENT_BY_ID_QUERY string = `
    SELECT 
        evenement_id,
        titre,
        description_evenement,
        date_debut,
        date_fin,
        type_evenement,
        lieu,
        tarifs,
        fichiers,
        statistiques
    FROM vue_evenement_complet 
    WHERE evenement_id = $1
`

    GET_EVENEMENT_BY_ID string = `SELECT obtenir_evenement_par_id($1) as evenement_data`

    RESERVER_QUERY string = "SELECT reserver_places($1, $2, $3, $4)"

    MARK_RESERVATION = "UPDATE reservation SET etat = '$1' WHERE id='$2'"
)