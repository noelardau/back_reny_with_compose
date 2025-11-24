import type { Route } from "./+types/resa";
import { useQueryGet } from "~/hooks/useQueryGet";
import { API_BASE_URL, api_paths } from "~/constants/api";
import { Container } from "@mantine/core";
import ReservationCard from "~/components/ReservationCard";
import { useOutletContext } from "react-router";



export function loader({params}: Route.LoaderArgs) {
  return { 
    idResa:  params.idResa

  };
}


export default function Resa({loaderData}: Route.ComponentProps) {

  // const { data,error,isPending } = useQueryGet(["resa", "one"],`${API_BASE_URL}/evenements/reservations/${loaderData.idEvent}`);
  const { data,error,isPending } = useQueryGet(["resa", "one"],`${api_paths.getReservationById(loaderData.idResa!)}`);

  // const {reservations} = data || {reservations: []};
  const { forUser } = useOutletContext<{ forUser: boolean }>();

  // const reservation = reservations.find((r:any) => r.reservation_id.toString() === loaderData.idResa);

  const reservation = data;
  console.log("Reservation data:", data);

  // console.log(reservation);

  function MarkAsUsed(){
    
  }

  



  if(isPending) {
  return <Container my="md" size="md" pt={100}>
             
    <div>Loading...</div>
     </Container>
  }

  if(error) {
  return <Container my="md" size="md" pt={100}>
             
    <div>{error.message}</div>
     </Container>
  }
  return <Container my="md" size="md" pt={100}>
             
    <ReservationCard reservation={reservation} forUser={forUser} onMarkAsUsed={MarkAsUsed}></ReservationCard>
     </Container>
  
  
  
}