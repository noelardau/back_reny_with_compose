import { Button, Container, Overlay, Text, Title } from '@mantine/core';
import classes from '../styles/HeroContentLeft.module.css';
import { Link } from 'react-router';

export function HeroContentLeft({isConnected}: {isConnected: boolean}) {
  return (
    <div className={classes.hero}>
      <Overlay
        gradient="linear-gradient(180deg, rgba(0, 0, 0, 0.25) 0%, rgba(0, 0, 0, .65) 40%)"
        opacity={1}
        zIndex={0}
      />
      <Container className={classes.container} size="md">
        <Title className={classes.title}>Back office de RENY Events</Title>
        <Text className={classes.description} size="xl" mt="xl">
         Bienvenue sur votre back office. Gérer vos événements ainsi que les réservations à travers une interface simple et intuitive.
        </Text>

      {
        !isConnected ?
             <Link to="/login">
          <Button variant="outline" color='red' size="xl" radius="xl" className={classes.control}>
          Se connecter
        </Button>
     </Link>
        : 
          <Link to="/event">
          <Button variant="outline" color='red' size="xl" radius="xl" className={classes.control}>
          Voir les événements
        </Button>
     </Link>
      }
      </Container>
    </div>
  );
}