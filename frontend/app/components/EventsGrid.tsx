import { AspectRatio, Card, Container, Image, SimpleGrid, Text } from '@mantine/core';
import classes from '../styles/EventsGrid.module.css';
import { Link } from 'react-router';


export function EventsGrid({events}) {
  const cards = events.map((article,index) => (
     <Link to={'/event/'+article.id} key={article.date} children={

    <Card key={article.title} p="md" radius="md" component="a" href="#" className={classes.card}>
      <AspectRatio ratio={1920 / 1080}>
        <Image src={article.image} radius="md" />
      </AspectRatio>
      <Text className={classes.date}>{article.date}</Text>
      <Text className={classes.title}>{article.title}</Text>
    </Card>
     }>
       </Link> 

  ));

  return (
    <Container py="xl">
      <SimpleGrid cols={{ base: 1, sm: 2 }} spacing={{ base: 0, sm: 'md' }}>
        {cards}
      </SimpleGrid>
    </Container>
  );
}