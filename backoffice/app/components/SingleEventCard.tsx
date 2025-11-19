import { IconArrowLeft, IconEdit, IconList, IconTagPlus, IconMapPin, IconCalendar, IconClock, IconTicket, IconCheck, IconX } from '@tabler/icons-react';
import { Modal, Badge, Button, Card, Group, Image, Text, SimpleGrid, AspectRatio, Stack, Divider } from '@mantine/core';
import { ReservationForm } from './ReservationFrom';
import classes from '../styles/SingleEventCard.module.css';
import { useState } from 'react';
import { Link } from 'react-router';
import { useMutation } from '@tanstack/react-query';
import { api_paths } from '~/constants/api';
import type { evenement } from '~/interfaces/evenement';
import type { newReservation } from '~/interfaces/reservation';
import dayjs from 'dayjs';
import 'dayjs/locale/fr';
import event1 from "../assets/Foaran_ny_fetin_ny_reny.jpg";
import { notifications } from '@mantine/notifications';
import '@mantine/notifications/styles.css';

dayjs.locale('fr');

export function SingleEventCard({ event, forUser }: { event: evenement; forUser?: boolean }) {
  const [opened, setOpened] = useState(false);

  const mutation = useMutation({
    mutationFn: (newResa: newReservation) =>
      fetch(`${api_paths.createReservation}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newResa),
      }).then((res) => {
        if (!res.ok) throw new Error('Échec de la réservation');
        return res.json();
      }),
    onSuccess: () => {
      setOpened(false);
      notifications.show({
        title: 'Réservation réussie !',
        message: 'Votre place a été réservée avec succès.',
        color: 'green',
        icon: <IconCheck size={18} />,
        autoClose: 5000,
      });
    },
    onError: (error: any) => {
      notifications.show({
        title: 'Erreur',
        message: error.message || 'Impossible de réserver. Veuillez réessayer.',
        color: 'red',
        icon: <IconX size={18} />,
        autoClose: 5000,
      });
    },
  });

  const saveResa = (newResa: newReservation) => {
    mutation.mutate(newResa);
  };

  const eventImage = event.fichiers?.[0]?.fichier_url || event1;
  const formatDate = (date: string) => dayjs(date).format('D MMMM YYYY');
  const formatTime = (date: string) => dayjs(date).format('HH:mm');
  const isSameDay = dayjs(event.date_debut).isSame(event.date_fin, 'day');

  return (
    <>
      <Modal
        opened={opened}
        onClose={() => !mutation.isPending && setOpened(false)}
        title="Réserver une place"
        centered
        closeOnClickOutside={!mutation.isPending}
      >
        <ReservationForm
          evenement_id={event.evenement_id}
          event={event}
          onSubmit={saveResa}
          loading={mutation.isPending}
        />
      </Modal>

      <Card withBorder radius="md" className={classes.card} p="lg">
        {/* === EN-TÊTE === */}
        <Card.Section className={classes.section} mt="md">
          <Group justify="apart" align="center">
            <Link to={forUser ? '/event' : 'http://localhost:3002'}>
              <IconArrowLeft size={20} color="red" style={{ cursor: 'pointer' }} />
            </Link>
            <Text fz="xl" fw={700} style={{ flex: 1, textAlign: 'center' }}>
              {event.titre}
            </Text>
            <Badge size="lg" variant="light" color="blue">
              {event.type_evenement.type_evenement_nom}
            </Badge>
          </Group>
        </Card.Section>

        {/* === IMAGE === */}
        <Card.Section mt="md">
          <AspectRatio ratio={16 / 9}>
            <Image
              src={eventImage}
              alt={event.titre}
              radius="md"
              fit="cover"
              h="100%"
            />
          </AspectRatio>
        </Card.Section>

        {/* === DESCRIPTION === */}
        <Card.Section className={classes.section} mt="md">
          <Text size="sm" c="dimmed" mb="xs">Description</Text>
          <Text size="md" style={{ whiteSpace: 'pre-wrap' }}>
            {event.description_evenement || 'Aucune description fournie.'}
          </Text>
        </Card.Section>

        <Divider my="md" />

        {/* === INFOS CLÉS === */}
        <Stack gap="xs" mt="md">
          <Group gap="xs">
            <IconCalendar size={18} />
            <Text size="sm" fw={500}>
              {isSameDay
                ? `Le ${formatDate(event.date_debut)}`
                : `Du ${formatDate(event.date_debut)} au ${formatDate(event.date_fin)}`}
            </Text>
          </Group>
          <Group gap="xs">
            <IconClock size={18} />
            <Text size="sm">
              De {formatTime(event.date_debut)} à {formatTime(event.date_fin)}
            </Text>
          </Group>
          <Group gap="xs">
            <IconMapPin size={18} />
            <Text size="sm">
              {event.lieu.lieu_nom} - {event.lieu.lieu_adresse}
            </Text>
          </Group>
        </Stack>

        <Divider my="md" />

        {/* === STATISTIQUES GLOBALES === */}
        <SimpleGrid cols={{ base: 2, sm: 4 }} spacing="xs" mt="md">
          <div>
            <Text size="xs" c="dimmed">Places totales</Text>
            <Text fw={600}>{event.statistiques_globales.total_places}</Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Disponibles</Text>
            <Text fw={600} color="green">{event.statistiques_globales.places_disponibles}</Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Vendues</Text>
            <Text fw={600} color="orange">{event.statistiques_globales.places_vendues}</Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Taux</Text>
            <Text fw={600}>
              {event.statistiques_globales.total_places > 0
                ? `${Math.round((event.statistiques_globales.places_vendues / event.statistiques_globales.total_places) * 100)}%`
                : '0%'}
            </Text>
          </div>
        </SimpleGrid>

        {/* === NOUVELLES INFOS : Prix, Jours, Statut === */}
        <SimpleGrid cols={{ base: 2, sm: 4 }} spacing="xs" mt="md">
          <div>
            <Text size="xs" c="dimmed">Prix min</Text>
            <Text fw={600} color="teal">
              {event.informations_complementaires.prix_minimum?.toLocaleString('fr-FR')} Ar
            </Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Prix max</Text>
            <Text fw={600} color="teal">
              {event.informations_complementaires.prix_maximum?.toLocaleString('fr-FR')} Ar
            </Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Jours restants</Text>
            <Text fw={600} color="blue">
              {event.informations_complementaires.jours_restants}
            </Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Statut</Text>
            <Text
              fw={600}
              color={
                event.informations_complementaires.est_passe
                  ? 'red'
                  : event.informations_complementaires.est_actuel
                  ? 'orange'
                  : 'green'
              }
            >
              {event.informations_complementaires.statut === 'a_venir'
                ? 'À venir'
                : event.informations_complementaires.statut === 'en_cours'
                ? 'En cours'
                : event.informations_complementaires.statut === 'termine'
                ? 'Terminé'
                : 'Inconnu'}
            </Text>
          </div>
        </SimpleGrid>

        {/* === INFOS SUPPLÉMENTAIRES === */}
        <SimpleGrid cols={{ base: 2, sm: 4 }} spacing="xs" mt="md">
          <div>
            <Text size="xs" c="dimmed">Réservées</Text>
            <Text fw={600} color="yellow">
              {event.statistiques_globales.places_reservees}
            </Text>
          </div>
          <div>
            <Text size="xs" c="dimmed">Types de places</Text>
            <Text fw={600}>
              {event.informations_complementaires.nombre_types_places}
            </Text>
          </div>
        </SimpleGrid>

        {/* === BOUTONS === */}
        {forUser ? (
          <SimpleGrid cols={{ base: 1, sm: 2 }} mt="xl" spacing="xs">
            <Button
              leftSection={<IconTagPlus size={18} />}
              color="green"
              onClick={() => setOpened(true)}
              loading={mutation.isPending}
              fullWidth
            >
              Réserver
            </Button>
            <Button
              leftSection={<IconList size={18} />}
              color="blue"
              component={Link}
              to={`/resa/${event.evenement_id}`}
              fullWidth
            >
              <Text hiddenFrom="sm">Liste</Text>
            </Button>
          
          </SimpleGrid>
        ) : (
          <Button
            mt="xl"
            fullWidth
            leftSection={<IconTicket size={18} />}
            color="green"
            onClick={() => setOpened(true)}
            loading={mutation.isPending}
          >
            Réserver une place
          </Button>
        )}
      </Card>
    </>
  );
}