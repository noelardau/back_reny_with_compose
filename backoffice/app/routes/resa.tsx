import type { Route } from "./+types/resa";
import { useQueryGet } from "~/hooks/useQueryGet";
import { api_paths } from "~/constants/api";
import { Container, Center, Loader, Text } from "@mantine/core";
import { showNotification } from "@mantine/notifications";
import ReservationCard from "~/components/ReservationCard";
import { useOutletContext } from "react-router";
import { useQueryClient } from "@tanstack/react-query";
import { IconCheck, IconX } from "@tabler/icons-react";

export function loader({ params }: Route.LoaderArgs) {
  return { idResa: params.idResa };
}

export default function Resa({ loaderData }: Route.ComponentProps) {
  const { idResa } = loaderData;
  const { forUser } = useOutletContext<{ forUser: boolean }>();
  const queryClient = useQueryClient();

  const {
    data: reservation,
    error,
    isPending,
  } = useQueryGet(["resa", "one", idResa], api_paths.getReservationById(idResa!));

  const markAsUsed = async (id: string) => {
    try {
      const response = await fetch(api_paths.markResaToUsed(id), {
        method: "POST",
      });

      if (!response.ok) {
        throw new Error("Échec du marquage comme utilisé");
      }

      // Invalidation + refetch pour être sûr d'avoir les données fraîches
      await queryClient.invalidateQueries({ queryKey: ["resa", "one", idResa] });
      // ou simplement refetch() si tu préfères
     

      showNotification({
        title: "Billet scanné !",
        message: "Le billet a été marqué comme utilisé avec succès.",
        color: "green",
        icon: <IconCheck size={18} />,
        autoClose: 5000,
      });
    } catch (err) {
      console.error(err);
      showNotification({
        title: "Erreur",
        message: "Impossible de marquer le billet comme utilisé.",
        color: "red",
        icon: <IconX size={18} />,
        autoClose: 5000,
      });
    }
  };

  // Loading
  if (isPending) {
    return (
      <Container my="md" size="md" pt={100}>
        <Center h={200}>
          <Loader size="lg" />
        </Center>
      </Container>
    );
  }

  // Erreur
  if (error) {
    return (
      <Container my="md" size="md" pt={100}>
        <Text c="red" ta="center">
          {(error as Error)?.message || "Une erreur est survenue"}
        </Text>
      </Container>
    );
  }

  // Si le billet est déjà utilisé, on peut afficher une petite info en plus dans la carte
  // (ReservationCard gère déjà probablement l'affichage du statut)
  return (
    <Container my="md" size="md" pt={100}>
      <ReservationCard
        reservation={reservation}
        forUser={forUser}
        onMarkAsUsed={markAsUsed}
      />
    </Container>
  );
}