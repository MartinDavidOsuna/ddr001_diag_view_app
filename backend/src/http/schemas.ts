import { z } from 'zod';

export const loginSchema = z.object({
  display_name: z.string().trim().min(1),
  email: z.email(),
  phone: z.string().min(7),
});

export const caseSchema = z.looseObject({
  case_id: z.uuid(), meter_id: z.string().min(1), user_id: z.uuid(),
  status: z.enum(['OPEN', 'CLOSED']), overall_verdict: z.enum(['APROBADO', 'RECHAZADO', 'NO_CONCLUYENTE']).nullable().optional(),
  report_version: z.number().int().positive(), checksum: z.string().min(1).nullable().optional(),
  created_at: z.iso.datetime(), closed_at: z.iso.datetime().nullable().optional(),
});

export const flowSchema = z.looseObject({
  flow_point_id: z.uuid(), code: z.enum(['Q1', 'Q2', 'Q3', 'Q4']), status: z.string(), checksum: z.string().nullable().optional(), created_at: z.iso.datetime(),
});

export const sampleSchema = z.looseObject({
  sample_id: z.uuid(), flow_point_id: z.uuid(), sample_number: z.number().int().positive(),
  status: z.literal('CLOSED_VALID'), checksum: z.string().min(1), created_at: z.iso.datetime(),
  started_at: z.iso.datetime().nullable().optional(), ended_at: z.iso.datetime().nullable().optional(),
});

export const reportSchema = z.looseObject({
  report_id: z.uuid(), version: z.number().int().positive(), checksum: z.string().min(1), html_key: z.string().nullable().optional(), pdf_key: z.string().nullable().optional(),
});

export const syncSchema = z.object({ items: z.array(z.object({ entity_type: z.enum(['case', 'flow_point', 'sample', 'report']), payload: z.record(z.string(), z.unknown()) })) });
