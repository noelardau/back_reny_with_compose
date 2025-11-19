import {
  Button,
  Container,
  Flex,
  Text,
  Title,
  Pagination,
  TextInput,
  Group,
  ActionIcon,
} from "@mantine/core";
import { Link, useSearchParams } from "react-router";
import { EventsGrid } from "~/components/EventsGrid";
import { routeProtection } from "~/utils/routeProtection";
import type { Route } from "./+types/evenements";
import { useQueryGet } from "~/hooks/useQueryGet";
import { api_paths } from "~/constants/api";
import dayjs from "dayjs";
import "dayjs/locale/fr";
import srcImg from "../assets/Foaran_ny_fetin_ny_reny.jpg";
import { IconSearch, IconX } from "@tabler/icons-react";
import { useMemo, useEffect, useState } from "react";
import { base64ToDataUrl } from "~/utils/base64"; 

dayjs.locale("fr");
const ITEMS_PER_PAGE = 4; // ← 4 événements par page

export async function loader() {
  routeProtection();
  return null;
}

export default function Evenements() {
  const [searchParams, setSearchParams] = useSearchParams();
  const urlQuery = searchParams.get("q")?.trim() || "";
  const urlPage = searchParams.get("page");
  const currentPage = Math.max(1, parseInt(urlPage || "1", 10));

  // Champ de recherche local
  const [inputValue, setInputValue] = useState(urlQuery);

  // Synchroniser le champ avec l'URL
  useEffect(() => {
    setInputValue(urlQuery);
  }, [urlQuery]);

  const { data, isPending, error } = useQueryGet(["evenements"], api_paths.getAllEvenements);

  console.log(data)
  // === Tous les événements transformés ===
  const allEvents = useMemo(() => {
    if (!data || !Array.isArray(data)) return [];
    return data.map((event: any) => {
      const debut = dayjs(event.date_debut);
      const fin = dayjs(event.date_fin);
      const isSameDay = debut.isSame(fin, "day");
      const prixMin = event.tarifs?.length > 0
        ? Math.min(...event.tarifs.map((t: any) => t.prix))
        : null;

    const binaryData = event.fichiers?.[0]?.donnees_binaire;
    const imageFromBase64 = base64ToDataUrl(binaryData); 

      return {
        id: event.evenement_id,
        title: event.titre,
        image: imageFromBase64 || event.fichiers?.[0]?.fichier_url || srcImg,
        date: isSameDay
          ? debut.format("D MMMM YYYY")
          : `${debut.format("D")} → ${fin.format("D MMMM YYYY")}`,
        price: prixMin,
      };
    });
  }, [data]);

  // === Filtrage sur tous les événements ===
  const filteredEvents = useMemo(() => {
    if (!urlQuery) return allEvents;
    const normalize = (str: string) =>
      str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    const query = normalize(urlQuery);
    return allEvents.filter(event => normalize(event.title).includes(query));
  }, [allEvents, urlQuery]);

  // === Pagination (4 par page) ===
  const total = filteredEvents.length;
  const totalPages = Math.ceil(total / ITEMS_PER_PAGE);
  const validPage = Math.min(Math.max(1, currentPage), totalPages || 1);
  const start = (validPage - 1) * ITEMS_PER_PAGE;
  const end = start + ITEMS_PER_PAGE;
  const paginatedEvents = filteredEvents.slice(start, end);

  // === Handlers ===
  const handleSearch = () => {
    const trimmed = inputValue.trim();
    setSearchParams(prev => {
      const newParams = new URLSearchParams(prev);
      if (trimmed) {
        newParams.set("q", trimmed);
      } else {
        newParams.delete("q");
      }
      newParams.set("page", "1");
      return newParams;
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  const clearSearch = () => {
    setInputValue("");
    setSearchParams(prev => {
      const newParams = new URLSearchParams(prev);
      newParams.delete("q");
      newParams.set("page", "1");
      return newParams;
    });
  };

  const handlePageChange = (page: number) => {
    setSearchParams(prev => {
      const newParams = new URLSearchParams(prev);
      newParams.set("page", page.toString());
      return newParams;
    });
    window.scrollTo(0, 0);
  };

  // === Rendu ===
  if (isPending) {
    return (
      <Container size="md" my="md" py={100} pb={50}>
        <Text ta="center" c="dimmed">Chargement des événements...</Text>
      </Container>
    );
  }

  if (error || !data) {
    return (
      <Container size="md" my="md" py={100} pb={50}>
        <Text ta="center" c="red">Erreur lors du chargement des événements.</Text>
      </Container>
    );
  }

  return (
    <Container size="md" my="md" py={100} pb={50}>
      <Flex justify="space-between" align="center" mb="lg" wrap="wrap" gap="md">
        <Title c="red" size="h3">Liste des évènements</Title>

        <Group>
          <TextInput
            placeholder="Rechercher (Entrée pour valider)"
            leftSection={<IconSearch size={16} />}
            rightSection={
              inputValue && (
                <ActionIcon size="sm" onClick={clearSearch} variant="subtle" color="gray">
                  <IconX size={14} />
                </ActionIcon>
              )
            }
            value={inputValue}
            onChange={(e) => setInputValue(e.currentTarget.value)}
            onKeyDown={handleKeyDown}
            style={{ minWidth: 280 }}
            size="sm"
          />
          <Link to="new">
            <Button variant="outline" color="red">+ Nouveau</Button>
          </Link>
        </Group>
      </Flex>

      {/* Résultats */}
      {urlQuery && (
        <Text size="sm" c="dimmed" mb="md">
          {total} résultat{total > 1 ? "s" : ""} pour <strong>"{urlQuery}"</strong>
          {total === 0 && " — Aucun événement trouvé."}
          {total > 0 && (
            <Text component="span" ml={8} c="blue" style={{ cursor: "pointer" }} onClick={clearSearch}>
              [Effacer]
            </Text>
          )}
        </Text>
      )}

      {/* 4 événements par page */}
      <EventsGrid events={paginatedEvents} />

      {/* Pagination */}
      {totalPages > 1 && (
        <Flex justify="center" mt="xl">
          <Pagination
            total={totalPages}
            value={validPage}
            onChange={handlePageChange}
            withEdges
            color="red"
            radius="md"
            size="sm"
          />
        </Flex>
      )}

      <Text size="sm" c="dimmed" ta="center" mt="sm">
        Page {validPage} sur {totalPages} • {total} événement{total > 1 ? "s" : ""} trouvé{total > 1 ? "s" : ""}
      </Text>
    </Container>
  );
}