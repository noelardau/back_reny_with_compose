import { useForm } from '@mantine/form';
import {
  TextInput,
  Button,
  Group,
  Box,
  ActionIcon,
  Select,
  NumberInput,
  Stack,
} from '@mantine/core';
import { IconTrash } from '@tabler/icons-react';
import { useState, useEffect } from 'react';
import {type_place} from "~/constants/app";

type PlaceDemandee = {
  type_place_id: string;
  nombre: number;
};

type FormValues = {
  email: string;
  reference_paiement: string; // Nouveau champ
  places_demandees: PlaceDemandee[];
};

type ReservationFormProps = {
  evenement_id: string;
  loading?: boolean;
  disabled?: boolean;
  onSubmit?: (data: {
    email: string;
    reference_paiement: string;
    evenement_id: string;
    places_demandees: PlaceDemandee[];
  }) => void;
};



export function ReservationForm({
  evenement_id,
  onSubmit,
  loading,
  disabled,
}: ReservationFormProps) {
  const [entries, setEntries] = useState<number[]>([0]); // indices des lignes

  const form = useForm<FormValues>({
    initialValues: {
      email: '',
      reference_paiement: '',
      places_demandees: [],
    },
    validate: {
      email: (value) => (/^\S+@\S+$/.test(value) ? null : 'Email invalide'),
      reference_paiement: (value) =>
        value.trim() ? null : 'La référence de paiement est requise',
      places_demandees: {
        type_place_id: (value, values, path) => {
          const index = parseInt(path.split('.')[1]);
          const hasEntry = index < entries.length;
          return hasEntry && !value ? 'Type de place requis' : null;
        },
        nombre: (value, values, path) => {
          const index = parseInt(path.split('.')[1]);
          const hasEntry = index < entries.length;
          return hasEntry && (!value || value < 1) ? 'Nombre invalide' : null;
        },
      },
    },
  });

  // Synchronise le nombre de lignes avec le tableau places_demandees
  useEffect(() => {
    const currentLength = form.values.places_demandees.length;
    const targetLength = entries.length;
    if (currentLength < targetLength) {
      const missing = targetLength - currentLength;
      form.setFieldValue('places_demandees', [
        ...form.values.places_demandees,
        ...Array(missing)
          .fill(null)
          .map(() => ({ type_place_id: '', nombre: 1 })),
      ]);
    } else if (currentLength > targetLength) {
      form.setFieldValue(
        'places_demandees',
        form.values.places_demandees.slice(0, targetLength)
      );
    }
  }, [entries.length]);

  const addPlaceField = () => {
    setEntries((prev) => [...prev, prev.length]);
  };

  const removePlaceField = (index: number) => {
    setEntries((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = (values: FormValues) => {
    // Nettoyer les entrées vides ou invalides
    const validPlaces = values.places_demandees.filter(
      (p) => p.type_place_id && p.nombre > 0
    );

    // Ne pas soumettre si aucune place valide
    if (validPlaces.length === 0) {
      form.setFieldError('places_demandees.0.type_place_id', 'Veuillez ajouter au moins un type de place');
      return;
    }

    const data = {
      email: values.email,
      reference_paiement: values.reference_paiement.trim(),
      evenement_id,
      places_demandees: validPlaces,
    };

    console.log('Données soumises :', data);
    onSubmit?.(data);

    // Reset du formulaire
    form.reset();
    setEntries([0]);
  };

  return (
    <Box component="form" onSubmit={form.onSubmit(handleSubmit)} maw={500}>
      <Stack gap="md">
        <TextInput
          label="Email"
          placeholder="client@example.com"
          withAsterisk
          {...form.getInputProps('email')}
        />

       

        {entries.map((_, index) => (
          <Group key={index} grow align="flex-end" wrap="nowrap">
            <Select
              label={index === 0 ? 'Type de place' : ''}
              placeholder="Choisir un type"
              data={type_place}
              withAsterisk={index === 0}
              {...form.getInputProps(`places_demandees.${index}.type_place_id`)}
              onChange={(value) => {
                form.setFieldValue(`places_demandees.${index}.type_place_id`, value || '');
              }}
            />
            <NumberInput
              label={index === 0 ? 'Nombre' : ''}
              placeholder="1"
              min={1}
              max={10}
              {...form.getInputProps(`places_demandees.${index}.nombre`)}
              onChange={(value) => {
                form.setFieldValue(`places_demandees.${index}.nombre`, Number(value) || 1);
              }}
            />
            {entries.length > 1 && (
              <ActionIcon
                color="red"
                variant="subtle"
                onClick={() => removePlaceField(index)}
                mb={index === 0 ? 28 : 0}
              >
                <IconTrash size={16} />
              </ActionIcon>
            )}
          </Group>
        ))}

        <Button variant="outline" onClick={addPlaceField} size="sm" w="fit-content">
          + Ajouter un type de place
        </Button>

         <TextInput
          label="Référence de paiement"
          placeholder="REF-123456"
          withAsterisk
          {...form.getInputProps('reference_paiement')}
        />

        <Group justify="flex-end" mt="md">
          <Button type="submit" loading={loading} disabled={disabled}>
            Réserver
          </Button>
        </Group>
      </Stack>
    </Box>
  );
}