import { Card, Text, Group, Badge, Stack, Divider, ThemeIcon, Grid, Box } from '@mantine/core';
import { IconMail, IconInfoCircle, IconCheck, IconClock, IconTicket, IconCoin, IconArrowLeft } from '@tabler/icons-react';
import { Link } from 'react-router';

interface PlaceDetail {
  place_id: string;
  numero_place: string;
  type_place_id: string;
  type_place_nom: string;
  tarif: number;
  etat_place: {
    code: string;
    description: string;
  };
}

interface Reservation {
  reservation_id: string;
  email: string;
  etat_reservation: 'payee' | 'en_attente';
  nombre_places_reservees: number;
  total_reservation: number;
  details_places: PlaceDetail[];
}

interface ReservationCardProps {
  reservation: Reservation;
  forUser?: boolean;
  idEvent?: string;
}

const statusConfig = {
  payee: { color: 'green', label: 'Payée', icon: IconCheck },
  en_attente: { color: 'yellow', label: 'En attente', icon: IconClock },
};

const formatPrice = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(amount);
};

export default function ReservationCard({ reservation, forUser, idEvent }: ReservationCardProps) {

  console.log("forUser dans ReservationCard:", forUser);
  const { etat_reservation, nombre_places_reservees, email, reservation_id, total_reservation, details_places } = reservation;
  const statusInfo = statusConfig[etat_reservation];
  const StatusIcon = statusInfo.icon;

  return (
    <Card withBorder radius="md" shadow="sm" p="lg" className="max-w-4xl mx-auto">
      <Card.Section withBorder inheritPadding py="xs">
        <Group justify="apart">
          <Group gap="xs">
             <Link to={forUser ? '/resa/'+ idEvent : 'https://renyevents.vercel.app/'}>
                          <IconArrowLeft size={20} color="red" style={{ cursor: 'pointer' }} />
                        </Link>
            <ThemeIcon variant="light" color="gray" size="sm">
              <IconInfoCircle size={16} />
            </ThemeIcon>
            <Text fw={600} size="sm" c="dimmed">
              Réservation #{reservation_id.slice(0, 8)}
            </Text>
          </Group>
          <Badge
            color={statusInfo.color}
            variant="light"
            leftSection={<StatusIcon size={14} />}
            size="lg"
          >
            {statusInfo.label}
          </Badge>
        </Group>
      </Card.Section>

      <Stack gap="md" mt="md">
        {/* Infos principales */}
        <Grid>
          <Grid.Col span={{ base: 12, sm: 6 }}>
            <Group gap="xs">
              <ThemeIcon variant="light" color="cyan" size="md">
                <IconMail size={18} />
              </ThemeIcon>
              <Box>
                <Text size="sm" c="dimmed">Email</Text>
                <Text fw={500} size="sm">{email}</Text>
              </Box>
            </Group>
          </Grid.Col>
        </Grid>

        <Divider />

        {/* Résumé financier */}
        <Grid>
          <Grid.Col span={{ base: 12, sm: 6 }}>
            <Group gap="xs">
              <ThemeIcon variant="light" color="teal" size="md">
                <IconTicket size={18} />
              </ThemeIcon>
              <Box>
                <Text size="sm" c="dimmed">Places réservées</Text>
                <Text fw={700} size="lg">{nombre_places_reservees}</Text>
              </Box>
            </Group>
          </Grid.Col>

          <Grid.Col span={{ base: 12, sm: 6 }}>
            <Group gap="xs">
              <ThemeIcon variant="light" color="orange" size="md">
                <IconCoin size={18} />
              </ThemeIcon>
              <Box>
                <Text size="sm" c="dimmed">Montant total</Text>
                <Text fw={700} size="lg" c="orange">
                  {formatPrice(total_reservation)} Ar
                </Text>
              </Box>
            </Group>
          </Grid.Col>
        </Grid>

        <Divider />

        {/* Détail des places */}
        <Box>
          <Text size="sm" c="dimmed" mb="sm" fw={600}>
            Détail des places réservées
          </Text>
          <Stack gap="sm">
            {details_places.map((place) => (
              <Card key={place.place_id} withBorder radius="sm" p="sm" bg="gray.0">
                <Grid align="center">
                  <Grid.Col span={{ base: 12, sm: 4 }}>
                    <Group gap="xs">
                      <ThemeIcon size="sm" radius="xl" color="indigo" variant="light">
                        <IconTicket size={14} />
                      </ThemeIcon>
                      <Text size="sm" fw={500}>{place.numero_place}</Text>
                    </Group>
                  </Grid.Col>

                  <Grid.Col span={{ base: 12, sm: 3 }}>
                    <Badge color="indigo" variant="filled" size="sm">
                      {place.type_place_nom}
                    </Badge>
                  </Grid.Col>

                  <Grid.Col span={{ base: 12, sm: 3 }}>
                    <Text size="sm" fw={600} c="dark">
                      {formatPrice(place.tarif)} Ar
                    </Text>
                  </Grid.Col>

                  <Grid.Col span={{ base: 12, sm: 2 }}>
                    <Badge
                      color={place.etat_place.code === 'reservee' ? 'orange' : 'gray'}
                      variant="light"
                      size="sm"
                    >
                      {place.etat_place.code === 'reservee' ? 'Réservée' : place.etat_place.description}
                    </Badge>
                  </Grid.Col>
                </Grid>
              </Card>
            ))}
          </Stack>
        </Box>

        {etat_reservation === 'en_attente' && (
          <Box mt="md">
            <Badge color="yellow" variant="filled" size="md" fullWidth>
              Paiement en attente – Places bloquées temporairement
            </Badge>
          </Box>
        )}
      </Stack>
    </Card>
  );
}