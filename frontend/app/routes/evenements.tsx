import { Button, Container, Flex, Text, Title, Pagination } from "@mantine/core";
import { Link, useSearchParams } from "react-router";
import { EventsGrid } from "~/components/EventsGrid";
import { routeProtection } from "~/utils/routeProtection";
import event1 from "../assets/Foaran_ny_fetin_ny_reny.jpg";
import type { Route } from "./+types/evenements";
import { Id_event_added } from "~/constants/app";

const ITEMS_PER_PAGE = 3;

export async function loader({ request }: Route.LoaderArgs) {
  routeProtection();

  const url = new URL(request.url);
  const page = Math.max(1, parseInt(url.searchParams.get("page") || "1", 10));

  // Liste complète des événements
  const allEvents = [
    {
      id: Id_event_added,
      title: "Foire fête des mères",
      image: event1,
      date: "August 18, 2022",
    },
    {
      id:"fec4c386-7722-4fd0-aded-d18a8cbec20e",
      title: "Best forests to visit in North America",
      image:
        "https://images.unsplash.com/photo-1448375240586-882707db888b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=720&q=80",
      date: "August 27, 2022",
    },
    {
      id: 4,
      title: "Hawaii beaches review: better than you think",
      image:
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=720&q=80",
      date: "September 9, 2022",
    },
    {
      id: 5,
      title: "Mountains at night: 12 best locations to enjoy the view",
      image:
        "https://images.unsplash.com/photo-1519681393784-d120267933ba?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=720&q=80",
      date: "September 12, 2022",
    },
    // Ajoute d'autres événements ici...
  ];

  const total = allEvents.length;
  const totalPages = Math.ceil(total / ITEMS_PER_PAGE);
  const validPage = Math.min(Math.max(1, page), totalPages);

  const start = (validPage - 1) * ITEMS_PER_PAGE;
  const end = start + ITEMS_PER_PAGE;
  const paginatedEvents = allEvents.slice(start, end);

  return {
    events: paginatedEvents,
    pagination: {
      page: validPage,
      totalPages,
      total,
      hasNext: validPage < totalPages,
      hasPrev: validPage > 1,
    },
  };
}

export default function Evenements({ loaderData }: Route.ComponentProps) {
  const [searchParams, setSearchParams] = useSearchParams();
  const currentPage = loaderData.pagination.page;
  const totalPages = loaderData.pagination.totalPages;

  const handlePageChange = (page: number) => {
    setSearchParams({ page: page.toString() });
  };

  return (
    <Container size="md" my="md" py={100} pb={50}>
      <Flex justify="space-between" align="center" mb="lg">
        <Title c="red" size="h3">
          Liste des évènements
        </Title>
        <Link to="new">
          <Button variant="outline" color="red">
            + Nouveau
          </Button>
        </Link>
      </Flex>

      <EventsGrid events={loaderData.events} />

      {totalPages > 1 && (
        <Flex justify="center" mt="xl">
          <Pagination
            total={totalPages}
            value={currentPage}
            onChange={handlePageChange}
            withEdges
            color="red"
            radius="md"
            size="sm"
          />
        </Flex>
      )}

      <Text size="sm" c="dimmed" ta="center" mt="sm">
        Page {currentPage} sur {totalPages} • {loaderData.pagination.total} événement(s)
      </Text>
    </Container>
  );
}