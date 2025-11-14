import { useState } from 'react';
import {
  Card,
  Stack,
  Group,
  Text,
  Badge,
  Button,
  ActionIcon,
  Loader,
  Flex,
  Box,
  useMantineTheme,
} from '@mantine/core';
import { useMediaQuery } from '@mantine/hooks';
import { Link } from 'react-router';
import { IconCheck, IconClock, IconMail, IconId } from '@tabler/icons-react';
import type { reservation } from '~/interfaces/reservation';
import { useQueryClient } from '@tanstack/react-query';
import { notifications} from '@mantine/notifications';

export function TableResa({ reservations }: { reservations: reservation[] }) {
  const theme = useMantineTheme();
  const isMobile = useMediaQuery(`(max-width: ${theme.breakpoints.sm})`);
  const [validatingIds, setValidatingIds] = useState<Set<string>>(new Set());

  const queryClient = useQueryClient();

  const validateResa = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    setValidatingIds((prev) => new Set(prev).add(id));

    try {
      const res = await fetch(`http://localhost:3000/v1/reservations/validate/${id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!res.ok) throw new Error('Échec de la validation');
      // Optionnel : rafraîchir via invalidateQueries()
    } catch (error) {
      console.error('Erreur validation:', error);
      // Optionnel : notification d'erreur
    } finally {
      setValidatingIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        notifications.clean();
        notifications.show({
          title: 'Réservation validée !',
          message: 'La resa a été validéé.',
                color: 'green',
                icon: <IconCheck size={18} />,
                autoClose: 5000,
              });
              queryClient.invalidateQueries({queryKey:['resa']});
        return next;
      });
    }
  };

  return (
    <Stack gap="md" mt={20}>
     
      {reservations.map((row) => {
        const isValidating = validatingIds.has(row.reservation_id);
        const isPending = row.etat_reservation === 'en_attente';


        return (
          <Card
            key={row.reservation_id}
            withBorder
            radius="md"
            p={isMobile ? 'sm' : 'md'}
            shadow="sm"
            component={Link}
            to={row.reservation_id}
            style={{
              pointerEvents: isValidating ? 'none' : 'auto',
              opacity: isValidating ? 0.7 : 1,
              transition: 'opacity 0.2s',
            }}
            className="hover:shadow-md transition-shadow"
          >
            <Flex
              direction={isMobile ? 'column' : 'row'}
              justify="space-between"
              align={isMobile ? 'stretch' : 'center'}
              gap="sm"
            >
              {/* Gauche : ID + Email */}
              <Box flex={1}>
                <Group gap="xs" wrap="nowrap">
                  <IconId size={16} color="gray" />
                  <Text size="sm" fw={600} truncate>
                    {row.reservation_id.slice(0, 8)}...
                  </Text>
                </Group>
                <Group gap="xs" mt={4}>
                  <IconMail size={16} color="gray" />
                  <Text size="sm" c="dimmed" truncate>
                    {row.email}
                  </Text>
                </Group>
              </Box>

              {/* Droite : Badge + Bouton */}
              <Group gap="xs" align="center" wrap="nowrap">
                <Badge
                  color={isPending ? 'orange' : 'green'}
                  variant="light"
                  size={isMobile ? 'sm' : 'md'}
                  leftSection={isPending ? <IconClock size={14} /> : <IconCheck size={14} />}
                >
                  {isPending ? 'En attente' : 'Validée'}
                </Badge>

                {isPending && (
                  <Button
                    size="xs"
                    color="green"
                    onClick={(e) => validateResa(row.reservation_id, e)}
                    loading={isValidating}
                    loaderProps={{ type: 'dots' }}
                    disabled={isValidating}
                    leftSection={isValidating ? null : <IconCheck size={14} />}
                  >
                    {isValidating ? 'Validation...' : 'Valider'}
                  </Button>
                )}
              </Group>
            </Flex>
          </Card>
        );
      })}
    </Stack>
  );
}