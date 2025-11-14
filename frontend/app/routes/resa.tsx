import type { Route } from "./+types/resa";
import { useQueryGet } from "~/hooks/useQueryGet";
import { API_BASE_URL } from "~/constants/api";
import { Container } from "@mantine/core";
import ReservationCard from "~/components/ReservationCard";
import { useOutletContext } from "react-router";



export function loader({params}: Route.LoaderArgs) {
  return { 
    idResa:  params.idResa,
    idEvent: params.eventId

  };
}


export default function Resa({loaderData}: Route.ComponentProps) {

  const { data,error,isPending } = useQueryGet(["resa", "one"],`${API_BASE_URL}/evenements/reservations/${loaderData.idEvent}`);

  const {reservations} = data || {reservations: []};
  const { forUser } = useOutletContext<{ forUser: boolean }>();

  const reservation = reservations.find((r:any) => r.reservation_id.toString() === loaderData.idResa);

  console.log(reservation);

  



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
             
    <ReservationCard reservation={reservation} forUser={forUser} idEvent={loaderData.idEvent}></ReservationCard>
     </Container>
  
  
  
}