import { Button, Container, Flex, Group } from "@mantine/core";
import type { Route } from "./+types/evenement";
// import axios from "axios"
import { SingleEventCard } from "~/components/SingleEventCard";

import { useQueryGet } from "~/hooks/useQueryGet";

import { Loader } from '@mantine/core';
import { IconArrowLeft } from "@tabler/icons-react";
import { Link } from "react-router";

import { useOutletContext } from "react-router";

import { API_BASE_URL } from "~/constants/api";

export async function loader({params}:Route.LoaderArgs){

  let id = params.eventId


  

  // fetch("https://46f6ac1dd812.ngrok-free.app/v1/evenements/fc142deb-73c7-4dbb-8f51-fe05a8231836",{method:"GET"}).then(data=>{
  // if(!data.ok){
  //   console.log("il y a un problme")
  //   throw new Error("dklfqjmf")

  // }
  // return data.body
  // }).then(r=>console.log(r?.getReader())).catch(err=> {throw err})

    return {
      eventId: id
    }
}




export default function Evenement({loaderData}:Route.ComponentProps) {
      


     const {error,data,isPending} = useQueryGet(['user',loaderData.eventId],API_BASE_URL + "/evenements/"+loaderData.eventId)
    const { forUser } = useOutletContext<{ forUser: boolean }>();
 
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

  console.log(data)

  return (
    <Container size="md" p="100">
      
      {/* <Group mb="md">
        <Link to={"/event"} children={
          
  <Button
    leftSection={<IconArrowLeft size={18} />}
    variant="light" color="red"
    // onClick={() => navigate(-1)}
  >
    Retour
  </Button>
        } />

        
        
</Group> */}
        
      {/* <h1>Event number {loaderData.title} </h1> */}

    <SingleEventCard event={data} forUser={forUser}/>
    </Container>
  );
}