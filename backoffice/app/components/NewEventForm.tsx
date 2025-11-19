'use client';

import { useState } from 'react';
import {
  TextInput,
  Textarea,
  NumberInput,
  Button,
  Group,
  Box,
  FileInput,
  Card,
  ActionIcon,
  Stack,
  Title,
  Grid,
  Paper,
  Select,
  Image,
  Center,
  Text,
} from '@mantine/core';
import '@mantine/dates/styles.css';
import { useForm } from '@mantine/form';
import { IconTrash, IconPlus, IconCalendar } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications'; // ← Ajouté
import { DateTimePicker } from '@mantine/dates';
import { format } from 'date-fns';

import { api_paths } from '~/constants/api';

import { useQueryGet } from '~/hooks/useQueryGet';

export function NewEventForm() {
  const [loading, setLoading] = useState(false);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  let typePlaceData = useQueryGet(['type_place'], api_paths.getTypePlace);
  let typeEventData = useQueryGet(['type_evenement'], api_paths.getTypeEvenement);


  let type_evenement = typeEventData.data?.map((te:any) => ({ value: te.id.toString(), label: te.nom })) || [];
  let type_place = typePlaceData.data?.map((tp:any) => ({ value: tp.id.toString(), label: tp.nom })) || [];


  const form = useForm({
    initialValues: {
      titre: '',
      description: '',
      date_debut: null as Date | null,
      date_fin: null as Date | null,
      type_id: '',
      lieu_nom: '',
      lieu_adresse: '',
      lieu_ville: '',
      lieu_capacite: 0,
      tarifs: [{ type_place_id: '', prix: 0, nombre_places: 0 }],
      fichiers: [{ nom_fichier: '', type_mime: '', type_fichier: 'affiche', donnees_bytea: '' }],
    },
    validate: {
      titre: (v) => (v?.trim() ? null : 'Requis'),
      description: (v) => (v?.trim() ? null : 'Requis'),
      date_debut: (v) => (v ? null : 'Requis'),
      date_fin: (v, values) =>
        v && values.date_debut && v > values.date_debut ? null : 'Doit être après le début',
      type_id: (v) => (v ? null : 'Type requis'),
      lieu_nom: (v) => (v?.trim() ? null : 'Requis'),
      lieu_ville: (v) => (v?.trim() ? null : 'Requis'),
      lieu_capacite: (v) => (v > 0 ? null : 'Invalide'),
      tarifs: {
        type_place_id: (v) => (v ? null : 'Requis'),
        prix: (v) => (v > 0 ? null : 'Requis'),
        nombre_places: (v) => (v > 0 ? null : 'Requis'),
      },
    },
  });

  const addTarif = () => {
    form.setFieldValue('tarifs', [
      ...form.values.tarifs,
      { type_place_id: '', prix: 0, nombre_places: 0 },
    ]);
  };

  const removeTarif = (index: number) => {
    if (form.values.tarifs.length === 1) return;
    form.setFieldValue(
      'tarifs',
      form.values.tarifs.filter((_, i) => i !== index)
    );
  };

  const handleFileChange = (file: File | null) => {
    if (!file) {
      setImagePreview(null);
      form.setFieldValue('fichiers.0', {
        nom_fichier: '',
        type_mime: '',
        type_fichier: 'affiche',
        donnees_bytea: '',
      });
      return;
    }

    const readerPreview = new FileReader();
    readerPreview.onload = (e) => setImagePreview(e.target?.result as string);
    readerPreview.readAsDataURL(file);

    const readerHex = new FileReader();
    readerHex.onload = (e) => {
      const arrayBuffer = e.target?.result as ArrayBuffer;
      const hex = Array.from(new Uint8Array(arrayBuffer))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
      form.setFieldValue('fichiers.0', {
        nom_fichier: file.name,
        type_mime: file.type || 'application/octet-stream',
        type_fichier: 'affiche',
        donnees_bytea: hex,
      });
    };
    readerHex.readAsArrayBuffer(file);
  };

  const toISO = (date: Date | null): string | null => {
    if (!date) return null;
    return format(date, "yyyy-MM-dd'T'HH:mm:ss'Z'");
  };

  const handleSubmit = async (values: typeof form.values) => {
    setLoading(true);

    const payload = {
      ...values,
      date_debut: toISO(values.date_debut),
      date_fin: toISO(values.date_fin),
    };

    try {
      const response = await fetch(api_paths.createEvenement, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const result = await response.json();
      

        notifications.show({
          title: 'Événement créé !',
          message: `${values.titre} a été ajouté avec succès.`,
          color: 'green',
          icon: <IconPlus size={18} />,
        });

        form.reset();
        setImagePreview(null);
      } else {
        const err = await response.json();
        console.log(payload)

        notifications.show({
          title: 'Échec de création',
          message: err.error || 'Une erreur est survenue.',
          color: 'red',
        });
      }
    } catch (err) {
      notifications.show({
        title: 'Erreur réseau',
        message: 'Impossible de contacter le serveur. Vérifiez votre connexion.',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box p="md" maw={900} mx="auto">
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Paper p="lg" shadow="sm" withBorder>
          <Stack gap="md">
            {/* Titre + Type */}
            <Grid>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <TextInput label="Titre" placeholder="Foire 2026" required {...form.getInputProps('titre')} />
              </Grid.Col>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <Select
                  label="Type d'événement"
                  placeholder="Sélectionner..."
                  data={type_evenement}
                  required
                  {...form.getInputProps('type_id')}
                />
              </Grid.Col>
            </Grid>

            <Textarea
              label="Description"
              placeholder="Décrivez l'événement..."
              required
              minRows={3}
              {...form.getInputProps('description')}
            />

            {/* Dates */}
            <Grid>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <DateTimePicker
                  label="Date de début"
                  placeholder="15/07/2026 20:00"
                  required
                  valueFormat="DD MMM YYYY à HH:mm"
                  leftSection={<IconCalendar size={16} />}
                  popoverProps={{ withinPortal: true }}
                  {...form.getInputProps('date_debut')}
                />
              </Grid.Col>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <DateTimePicker
                  label="Date de fin"
                  placeholder="15/07/2026 23:30"
                  required
                  valueFormat="DD MMM YYYY à HH:mm"
                  leftSection={<IconCalendar size={16} />}
                  popoverProps={{ withinPortal: true }}
                  {...form.getInputProps('date_fin')}
                />
              </Grid.Col>
            </Grid>

            {/* Lieu */}
            <Title order={4} mt="lg">Lieu</Title>
            <Grid>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <TextInput label="Nom" placeholder="Stade Barea" required {...form.getInputProps('lieu_nom')} />
              </Grid.Col>
              <Grid.Col span={{ base: 12, md: 6 }}>
                <TextInput label="Ville" placeholder="Antananarivo" required {...form.getInputProps('lieu_ville')} />
              </Grid.Col>
              <Grid.Col span={{ base: 12, md: 8 }}>
                <TextInput label="Adresse" placeholder="Mahamasina..." required {...form.getInputProps('lieu_adresse')} />
              </Grid.Col>
              <Grid.Col span={{ base: 12, md: 4 }}>
                <NumberInput label="Capacité" placeholder="5000" required min={1} {...form.getInputProps('lieu_capacite')} />
              </Grid.Col>
            </Grid>

            {/* Tarifs */}
            <Title order={4} mt="lg">Tarifs</Title>
            {form.values.tarifs.map((_, index) => (
              <Card key={index} withBorder p="sm">
                <Grid align="end">
                  <Grid.Col span={{ base: 12, md: 5 }}>
                    <Select
                      label="Type de place"
                      placeholder="Choisir..."
                      data={type_place}
                      required
                      {...form.getInputProps(`tarifs.${index}.type_place_id`)}
                    />
                  </Grid.Col>
                  <Grid.Col span={{ base: 12, md: 3 }}>
                    <NumberInput label="Prix (Ar)" placeholder="750" required min={0} {...form.getInputProps(`tarifs.${index}.prix`)} />
                  </Grid.Col>
                  <Grid.Col span={{ base: 12, md: 3 }}>
                    <NumberInput label="Places" placeholder="2000" required min={1} {...form.getInputProps(`tarifs.${index}.nombre_places`)} />
                  </Grid.Col>
                  <Grid.Col span={{ base: 12, md: 1 }}>
                    <ActionIcon
                      color="red"
                      variant="subtle"
                      onClick={() => removeTarif(index)}
                      disabled={form.values.tarifs.length === 1}
                    >
                      <IconTrash size={16} />
                    </ActionIcon>
                  </Grid.Col>
                </Grid>
              </Card>
            ))}
            <Button leftSection={<IconPlus size={16} />} variant="light" onClick={addTarif}>
              Ajouter un tarif
            </Button>

            {/* Affiche + Preview */}
            <Title order={4} mt="lg">Affiche</Title>
            <FileInput
              label="Téléverser l'affiche"
              placeholder="JPG, PNG..."
              accept="image/jpeg,image/png"
              onChange={handleFileChange}
            />
            {imagePreview ? (
              <Card withBorder p="sm">
                <Text size="sm" fw={500} mb="xs">Prévisualisation :</Text>
                <Center>
                  <Image
                    src={imagePreview}
                    alt="Affiche"
                    radius="md"
                    mah={300}
                    fit="contain"
                    style={{ border: '1px solid #ddd' }}
                  />
                </Center>
              </Card>
            ) : form.values.fichiers[0]?.nom_fichier ? (
              <Text size="sm" c="dimmed" ta="center">
                Aucune image sélectionnée
              </Text>
            ) : null}

            {/* Submit */}
            <Group justify="flex-end" mt="xl">
              <Button type="submit" loading={loading} color="blue">
                Créer l'événement
              </Button>
            </Group>
          </Stack>
        </Paper>
      </form>
    </Box>
  );
}