import { Container, Flex,  } from "@mantine/core";
import type { Route } from "./+types/evenement";
import { SingleEventCard } from "~/components/SingleEventCard";
import { useQueryGet } from "~/hooks/useQueryGet";
import { Loader } from '@mantine/core';
import { useOutletContext } from "react-router";
import {api_paths} from "~/constants/api";


export async function loader({params}:Route.LoaderArgs){

  let id = params.eventId


    return {
      eventId: id
    }
}




export default function Evenement({loaderData}:Route.ComponentProps) {
      

  const { forUser } = useOutletContext<{ forUser: boolean }>();

     const {error,data,isPending} = useQueryGet(['user',loaderData.eventId],api_paths.getEvenementbyid(loaderData.eventId!))
     
 
  if(error){
    return  <Container size="md" p="100">
      <div>Une erreur est survenue : {error.message}</div>

    </Container>
  }

  if(isPending){
    return <Container size="md" p="100">  
      <Flex justify="center" align="center" style={{ height: '100vh' }}>  
        <Loader size="lg" variant="dots" />
      </Flex>
    </Container>


  }

  return (
    <Container size="md" p="100">  
      <SingleEventCard event={data} forUser={forUser}/>
    </Container>
  );
}