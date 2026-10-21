import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string({ error: 'auth.errors.invalidEmail' }).trim().pipe(z.email('auth.errors.invalidEmail')),
  password: z.string({ error: 'auth.errors.passwordRequired' }).min(1, 'auth.errors.passwordRequired'),
})
