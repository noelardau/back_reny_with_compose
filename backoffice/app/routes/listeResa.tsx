import {
  Button,
  Container,
  Flex,
  Loader,
  Text,
  Title,
  Menu,
  Group,
  Badge,
  rem,
} from "@mantine/core";
import type { Route } from "./+types/listeResa";
import { TableResa } from "~/components/TableResa";
import { useQueryGet } from "~/hooks/useQueryGet";
import { Link } from "react-router";
import { IconArrowLeft, IconFilter, IconCheck, IconClock } from "@tabler/icons-react";
import { routeProtection } from "~/utils/routeProtection";
import { useState } from "react";
import { api_paths} from "~/constants/api";

export const loader = async ({ params }: Route.LoaderArgs) => {
  routeProtection();
  return params.eventId;
};

export default function ListResa({ loaderData }: Route.ComponentProps) {
  const { data, error, isPending } = useQueryGet(
    ["resa", loaderData],api_paths.getAllReservationsByEvent(loaderData!)
  );

  const [filter, setFilter] = useState<"all" | "en_attente" | "payee">("all");

  if (error) {
    return (
      <Container size="md" p={100}>
        <Text c="red">Erreur : {error.message}</Text>
      </Container>
    );
  }

  if (isPending) {
    return (
      <Container size="md" p={100}>
        <Flex justify="center" align="center" gap="xs">
          <Loader size="sm" />
          <Text>Chargement...</Text>
        </Flex>
      </Container>
    );
  }

  // === COMPTAGE ===
  const total = data.reservations.length;
  const enAttente = data.reservations.filter((r: any) => r.etat_reservation === "en_attente").length;
  const payee = data.reservations.filter((r: any) => r.etat_reservation === "payee").length;

  // === FILTRE ===
  const filteredReservations = data.reservations.filter((resa: any) => {
    if (filter === "all") return true;
    return resa.etat_reservation === filter;
  });

  // === LABEL DU MENU ===
  const getMenuLabel = () => {
    if (filter === "all") return `Toutes (${total})`;
    if (filter === "en_attente") return `En attente (${enAttente})`;
    if (filter === "payee") return `Payé (${payee})`;
  };

  return (
    <Container my="md" size="md" pt={100}>
      {/* === EN-TÊTE === */}
      <Flex justify="space-between" align="center" mb="lg" wrap="wrap" gap="sm">
        <Link to={`/event/${data.evenement_id}`}>
          <IconArrowLeft size={18} color="red" style={{ cursor: "pointer" }} />
        </Link>

        <Title c="red" size="md" style={{ flex: 1, textAlign: "center" }}>
          Liste des réservations
        </Title>

        {/* === MENU DÉROULANT RESPONSIVE === */}
        <Menu shadow="md" width={200} position="bottom-end">
          <Menu.Target>
            <Button
              variant="light"
              color="gray"
              size="sm"
              leftSection={<IconFilter size={16} />}
              rightSection={
                <Text size="xs" fw={500} c="dimmed">
                  {getMenuLabel()}
                </Text>
              }
            >
              Filtrer
            </Button>
          </Menu.Target>

          <Menu.Dropdown>
            <Menu.Label>Statut de paiement</Menu.Label>

            <Menu.Item
              leftSection={<IconClock size={14} />}
              onClick={() => setFilter("all")}
              color={filter === "all" ? "blue" : undefined}
            >
              <Group justify="space-between" wrap="nowrap">
                <Text size="sm">Toutes</Text>
                <Badge size="xs" variant="light">
                  {total}
                </Badge>
              </Group>
            </Menu.Item>

            <Menu.Item
              leftSection={<IconClock size={14} color="orange" />}
              onClick={() => setFilter("en_attente")}
              color={filter === "en_attente" ? "orange" : undefined}
            >
              <Group justify="space-between" wrap="nowrap">
                <Text size="sm">En attente</Text>
                <Badge size="xs" color="orange" variant="light">
                  {enAttente}
                </Badge>
              </Group>
            </Menu.Item>

            <Menu.Item
              leftSection={<IconCheck size={14} color="green" />}
              onClick={() => setFilter("payee")}
              color={filter === "payee" ? "green" : undefined}
            >
              <Group justify="space-between" wrap="nowrap">
                <Text size="sm">Payé</Text>
                <Badge size="xs" color="green" variant="light">
                  {payee}
                </Badge>
              </Group>
            </Menu.Item>
          </Menu.Dropdown>
        </Menu>
      </Flex>

      {/* === TABLEAU === */}
      <TableResa reservations={filteredReservations} />
    </Container>
  );
}


