
import { LoginForm } from "~/components/LoginForm";
import type { Route } from "./+types/login";
import { conectUser } from "~/db/user";
import { redirect } from "react-router";


export async function action({request}: Route.ActionArgs) {
    let formData = await request.formData();
    let username = formData.get("username");
    let password = formData.get("password");

    if(conectUser(username as string, password as string)){
        return redirect("/")
    }

    return {success:false, message:"Nom d'utilisateur ou mot de passe incorrect"};

}

export default function Login() {
  return <LoginForm />;
}