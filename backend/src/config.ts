import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32),
  PORT: z.coerce.number().int().positive().default(3000),
  EVIDENCE_STORAGE_PATH: z.string().min(1),
  HYDRANTS_API_BASE_URL: z.url().optional().or(z.literal('')),
  HYDRANTS_API_TOKEN: z.string().min(1).optional().or(z.literal('')),
});

export type AppConfig = z.infer<typeof schema>;
export const loadConfig = (): AppConfig => schema.parse(process.env);
