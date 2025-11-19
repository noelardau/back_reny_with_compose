import { user } from "~/db/user";
import type { Route } from "./+types/home";
import { HeroContentLeft } from "~/components/HeroSectionBack";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "New React Router App" },
    { name: "description", content: "Welcome to React Router!" },
  ];
}


export async function loader({}: Route.LoaderArgs) {
  
 
  return user;
}

export default function Home({loaderData}: Route.ComponentProps) {
  
  return <HeroContentLeft isConnected={loaderData.isConnected}></HeroContentLeft>;

}
