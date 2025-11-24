import {
  Card,
  Text,
  Group,
  Badge,
  Stack,
  Divider,
  ThemeIcon,
  Grid,
  Box,
  Button,
  ActionIcon,
  CopyButton,
  Tooltip,
  rem,
} from '@mantine/core';
import {
  IconMail,
  IconInfoCircle,
  IconCheck,
  IconClock,
  IconTicket,
  IconCoin,
  IconArrowLeft,
  IconCalendar,
  IconMapPin,
  IconCategory,
  IconCopy,
  IconQrcode,
  IconChecks,
} from '@tabler/icons-react';
import { Link } from 'react-router';
import { path_to_vitrine } from '~/constants/app';

interface ReservationCardProps {
  reservation: any;
  forUser?: boolean;
  idEvent?: string;
  onMarkAsUsed?: (reservationId: string) => void; // nouvelle callback
}

const statusConfig = {
  en_attente: { color: 'yellow', label: 'En attente', icon: IconClock },
  payee: { color: 'green', label: 'Payée', icon: IconCheck },
  utilisee: { color: 'blue', label: 'Utilisée', icon: IconChecks },
} as const;

const formatPrice = (amount: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(amount);

const formatDate = (date: string) =>
  new Date(date).toLocaleDateString('fr-FR', {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });

export default function ReservationCard({
  reservation,
  forUser = false,
  onMarkAsUsed,
}: ReservationCardProps) {
  const {
    reservation_id,
    email,
    etat_code,
    nombre_places,
    total,
    places,
    evenement,
    reference_paiement,
  } = reservation;

  const statusInfo = statusConfig[etat_code as keyof typeof statusConfig] || {
    color: 'gray',
    label: 'Inconnu',
    icon: IconInfoCircle,
  };
  const StatusIcon = statusInfo.icon;
  const isPaid = etat_code === 'payee';
  const isUsed = etat_code === 'utilisee';

  return (
    <Card withBorder radius="md" shadow="sm" p="lg" className="max-w-4xl mx-auto">
      {/* HEADER */}
      <Card.Section withBorder inheritPadding py="xs">
        <Group justify="apart">
          <Group gap="xs">
            <Link
              to={
                forUser
                  ? `/resa/${evenement.id}`
                  : path_to_vitrine
              }
            >
              <IconArrowLeft size={20} color="red" style={{ cursor: 'pointer' }} />
            </Link>
            <ThemeIcon variant="light" color="gray" size="sm">
              <IconInfoCircle size={16} />
            </ThemeIcon>
            <Text fw={600} size="sm" c="dimmed">
              Réservation #{reservation_id.slice(0, 8)}
            </Text>
          </Group>

          <Group gap="md">
            {/* Statut principal */}
            <Badge
              color={statusInfo.color}
              variant="light"
              leftSection={<StatusIcon size={14} />}
              size="lg"
            >
              {statusInfo.label}
            </Badge>

            {/* Bouton "Marquer comme utilisé" */}
            {isPaid && !isUsed && onMarkAsUsed && forUser && (
              <Button
                leftSection={<IconChecks size={18} />}
                color="blue"
                variant="light"
                size="sm"
                onClick={() => onMarkAsUsed(reservation_id)}
              >
                Marquer comme utilisé
              </Button>
            )}

            {isUsed && (
              <Badge color="blue" variant="filled">
                Billet scanné
              </Badge>
            )}
          </Group>
        </Group>
      </Card.Section>

      <Stack gap="md" mt="md">
        {/* ÉVÉNEMENT */}
        <Box>
          <Text size="lg" fw={700} c="blue">
            {evenement.titre}
          </Text>
          <Group gap="xs" mt={4}>
            <IconCalendar size={16} color="gray" />
            <Text size="sm" c="dimmed">
              {formatDate(evenement.date_debut)} → {formatDate(evenement.date_fin)}
            </Text>
          </Group>
          {evenement.lieu?.lieu_nom && (
            <Group gap="xs" mt={2}>
              <IconMapPin size={16} color="gray" />
              <Text size="sm" c="dimmed">
                {evenement.lieu.lieu_nom}
                {evenement.lieu.lieu_ville && `, ${evenement.lieu.lieu_ville}`}
              </Text>
            </Group>
          )}
        </Box>

        <Divider />

        {/* RÉFÉRENCE DE PAIEMENT + COPY */}
        {reference_paiement && (
          <Group justify="apart" align="center" wrap="nowrap">
            <Group gap="xs">
              <ThemeIcon variant="light" color="violet" size="md">
                <IconQrcode size={18} />
              </ThemeIcon>
              <Box>
                <Text size="sm" c="dimmed">Référence paiement</Text>
                <Text fw={600} size="sm" >
                  {reference_paiement}
                </Text>
              </Box>
            </Group>

            <CopyButton value={reference_paiement}>
              {({ copied, copy }) => (
                <Tooltip label={copied ? "Copié !" : "Copier"}>
                  <ActionIcon variant="subtle" color={copied ? 'teal' : 'gray'} onClick={copy}>
                    {copied ? <IconCheck size={18} /> : <IconCopy size={18} />}
                  </ActionIcon>
                </Tooltip>
              )}
            </CopyButton>
          </Group>
        )}

        <Divider />

        {/* INFOS CLIENT */}
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

        {/* RÉSUMÉ FINANCIER */}
        <Grid>
          <Grid.Col span={{ base: 12, sm: 6 }}>
            <Group gap="xs">
              <ThemeIcon variant="light" color="teal" size="md">
                <IconTicket size={18} />
              </ThemeIcon>
              <Box>
                <Text size="sm" c="dimmed">Places réservées</Text>
                <Text fw={700} size="lg">{nombre_places}</Text>
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
                  {formatPrice(total)} Ar
                </Text>
              </Box>
            </Group>
          </Grid.Col>
        </Grid>

        {/* DÉTAIL DES PLACES */}
        {places && places.length > 0 && (
          <Box>
            <Text size="sm" c="dimmed" mb="sm" fw={600}>
              Détail des places réservées
            </Text>
            <Stack gap="sm">
              {places.map((place: any) => (
                <Card key={place.place_id} withBorder radius="sm" p="sm" bg="gray.0">
                  <Grid align="center">
                    <Grid.Col span={{ base: 12, sm: 4 }}>
                      <Group gap="xs">
                        <ThemeIcon size="sm" radius="xl" color="indigo" variant="light">
                          <IconTicket size={14} />
                        </ThemeIcon>
                        <Text size="sm" fw={500}>{place.numero}</Text>
                      </Group>
                    </Grid.Col>
                    <Grid.Col span={{ base: 12, sm: 3 }}>
                      <Badge color="indigo" variant="filled" size="sm">
                        {place.tarif.type_place.nom}
                      </Badge>
                    </Grid.Col>
                    <Grid.Col span={{ base: 12, sm: 3 }}>
                      <Text size="sm" fw={600} c="dark">
                        {formatPrice(place.tarif.prix)} Ar
                      </Text>
                    </Grid.Col>
                  </Grid>
                </Card>
              ))}
            </Stack>
          </Box>
        )}
      </Stack>
    </Card>
  );
}