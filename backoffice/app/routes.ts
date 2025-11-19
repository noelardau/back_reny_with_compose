import { type RouteConfig, index, prefix, route, layout } from "@react-router/dev/routes";

export default [
    index("routes/home.tsx"),
    route("/login","routes/login.tsx"),
    ...prefix("event/",[
        
        index("routes/evenements.tsx"),
        route(":eventId","routes/evenement.tsx"),
        route("new","routes/newEvenement.tsx"),

    ]),
    ...prefix("resa",[
        route(":eventId", "routes/listeResa.tsx"),
            layout("layouts/AppLayout.tsx", [
        route("/one/:idResa", "routes/resa.tsx"),

       ]) 
    ])

] satisfies RouteConfig;
