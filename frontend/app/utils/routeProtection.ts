import { redirect } from "react-router";
import {user} from "~/db/user";


export function routeProtection() {
     if(!user.isConnected){
        throw redirect("/");
    }
}