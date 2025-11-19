import { z } from 'zod';

export const reservationSchema = z.object({
  email: z.string().email('Email invalide').min(1, 'Email requis'),
  type: z.enum(['standard', 'vip', 'premium'], { required_error: 'Type requis' }),
  places: z.coerce.number().min(1, 'Au moins 1 place').max(10, 'Maximum 10 places'),
  reference: z.string().min(1, 'Référence du transfert requise'),
});