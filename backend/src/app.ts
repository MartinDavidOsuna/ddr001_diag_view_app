import { mkdir, unlink } from 'node:fs/promises';
import path from 'node:path';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import multer from 'multer';
import { Prisma, type PrismaClient } from '@prisma/client';
import type { AppConfig } from './config.js';
import { AuthService, type AuthenticatedRequest } from './auth/auth.js';
import { errorHandler, HttpError, notFound } from './http/errors.js';
import { caseSchema, flowSchema, loginSchema, reportSchema, sampleSchema, syncSchema } from './http/schemas.js';
import { FileStorage } from './storage/file_storage.js';
import { HydrantsClient } from './external/hydrants_client.js';

const json = (value: unknown) => value as Prisma.InputJsonValue;
const date = (value: unknown) => typeof value === 'string' ? new Date(value) : undefined;

export async function createApp(prisma: PrismaClient, config: AppConfig) {
  const app = express();
  const auth = new AuthService(prisma, config.JWT_SECRET);
  const storage = new FileStorage(config.EVIDENCE_STORAGE_PATH);
  const hydrants = new HydrantsClient(config);
  const uploadRoot = path.join(config.EVIDENCE_STORAGE_PATH, '.upload');
  await mkdir(uploadRoot, { recursive: true });
  const upload = multer({ dest: uploadRoot, limits: { fileSize: 25 * 1024 * 1024, files: 1 } });
  app.use(helmet({ contentSecurityPolicy: false }), cors(), express.json({ limit: '5mb' }));

  app.get('/api/v1/health/live', (_request, response) => response.json({ status: 'ok' }));
  app.post('/api/v1/auth/login', async (request, response, next) => {
    try {
      const body = loginSchema.parse(request.body);
      const result = await auth.login({ displayName: body.display_name, email: body.email, phone: body.phone });
      response.status(200).json({ token: result.token, user: userJson(result.user) });
    } catch (error) { next(error); }
  });

  app.use('/api/v1', auth.middleware);
  app.get('/api/v1/auth/me', (request: AuthenticatedRequest, response) => response.json({ user: userJson(requireAuth(request).user) }));
  app.post('/api/v1/auth/logout', async (request: AuthenticatedRequest, response, next) => {
    try { await auth.logout(requireAuth(request).sessionId); response.status(204).end(); } catch (error) { next(error); }
  });

  app.get('/api/v1/users', async (_request, response, next) => {
    try { response.json({ items: await prisma.user.findMany({ orderBy: { createdAt: 'desc' }, take: 100 }) }); } catch (error) { next(error); }
  });
  app.get('/api/v1/meters', async (request, response, next) => {
    try {
      const query = stringQuery(request.query.query);
      response.json({ items: await prisma.meter.findMany({ where: query ? { id: { contains: query, mode: 'insensitive' } } : {}, orderBy: { updatedAt: 'desc' }, take: 100 }) });
    } catch (error) { next(error); }
  });

  app.post('/api/v1/cases', async (request, response, next) => {
    try { const body = caseSchema.parse(request.body as unknown); response.status(await upsertCase(prisma, body)); responseJson(response, await prisma.verificationCase.findUniqueOrThrow({ where: { id: body.case_id } })); } catch (error) { next(error); }
  });
  app.get('/api/v1/cases/:id', async (request, response, next) => {
    try {
      const found = await prisma.verificationCase.findUnique({ where: { id: request.params.id }, include: { flowPoints: { include: { samples: { include: { evidence: true } } } }, reports: true } });
      if (!found) throw new HttpError(404, 'NOT_FOUND', 'Expediente no encontrado.');
      response.json(found);
    } catch (error) { next(error); }
  });
  app.get('/api/v1/cases', async (request, response, next) => {
    try {
      const limit = Math.min(Number(request.query.limit ?? 50), 100);
      const items = await prisma.verificationCase.findMany({ where: compactWhere({ meterId: stringQuery(request.query.meter_id), userId: stringQuery(request.query.user_id), status: stringQuery(request.query.status), overallVerdict: stringQuery(request.query.verdict) }), take: limit, orderBy: { createdAt: 'desc' } });
      response.json({ items, next_cursor: items.length === limit ? items.at(-1)?.id : null });
    } catch (error) { next(error); }
  });
  app.post('/api/v1/cases/:id/close', async (request, response, next) => {
    try {
      const body = caseSchema.partial().parse(request.body);
      const updated = await prisma.verificationCase.update({ where: { id: request.params.id }, data: { status: 'CLOSED', overallVerdict: body.overall_verdict ?? null, closedAt: date(body.closed_at) ?? new Date(), checksum: body.checksum ?? null, payload: json(request.body) } });
      response.json(updated);
    } catch (error) { next(error); }
  });

  app.post('/api/v1/cases/:caseId/flow-points', async (request, response, next) => {
    try { const body = flowSchema.parse(request.body as unknown); const caseId = request.params.caseId; const item = await prisma.flowPoint.upsert({ where: { caseId_code: { caseId, code: body.code } }, update: { status: body.status, checksum: body.checksum ?? null, payload: json(body) }, create: { id: body.flow_point_id, caseId, code: body.code, status: body.status, checksum: body.checksum ?? null, payload: json(body), createdAt: new Date(body.created_at) } }); response.status(201).json(item); } catch (error) { next(error); }
  });
  app.get('/api/v1/cases/:caseId/flow-points', async (request, response, next) => { try { response.json({ items: await prisma.flowPoint.findMany({ where: { caseId: request.params.caseId } }) }); } catch (error) { next(error); } });
  app.get('/api/v1/flow-points/:id', async (request, response, next) => { try { const item = await prisma.flowPoint.findUnique({ where: { id: request.params.id }, include: { samples: true } }); if (!item) throw new HttpError(404, 'NOT_FOUND', 'Caudal no encontrado.'); response.json(item); } catch (error) { next(error); } });

  app.post('/api/v1/samples', async (request, response, next) => {
    try { const body = sampleSchema.parse(request.body); const existing = await prisma.sample.findUnique({ where: { id: body.sample_id } }); if (existing && existing.checksum !== body.checksum) throw new HttpError(409, 'CONFLICT', 'La muestra cerrada existe con checksum distinto.'); if (existing) { response.json({ status: 'exists', sample: existing }); return; } const item = await prisma.sample.create({ data: { id: body.sample_id, flowPointId: body.flow_point_id, sampleNumber: body.sample_number, status: body.status, checksum: body.checksum, payload: json(body), createdAt: new Date(body.created_at), startedAt: date(body.started_at) ?? null, endedAt: date(body.ended_at) ?? null } }); await prisma.evidence.updateMany({ where: { pendingSampleId: body.sample_id }, data: { sampleId: body.sample_id, pendingSampleId: null } }); response.status(201).json({ status: 'created', sample: item }); } catch (error) { next(error); }
  });
  app.get('/api/v1/samples/:id', async (request, response, next) => { try { const item = await prisma.sample.findUnique({ where: { id: request.params.id }, include: { evidence: true } }); if (!item) throw new HttpError(404, 'NOT_FOUND', 'Muestra no encontrada.'); response.json(item); } catch (error) { next(error); } });
  app.get('/api/v1/samples', async (request, response, next) => { try { const caseId = stringQuery(request.query.case_id); response.json({ items: await prisma.sample.findMany({ where: caseId ? { flowPoint: { caseId } } : {}, take: Math.min(Number(request.query.limit ?? 50), 100), orderBy: { createdAt: 'desc' } }) }); } catch (error) { next(error); } });

  app.post('/api/v1/evidence', upload.single('file'), async (request, response, next) => {
    try {
      if (!request.file) throw new HttpError(400, 'VALIDATION', 'Archivo requerido.');
      const body = request.body as Record<string, unknown>;
      const metadata = JSON.parse(typeof body.metadata === 'string' ? body.metadata : '{}') as Record<string, unknown>;
      const evidenceId = typeof metadata.evidence_id === 'string' ? metadata.evidence_id : ''; const sampleId = typeof metadata.sample_id === 'string' ? metadata.sample_id : ''; const sha256 = typeof metadata.sha256 === 'string' ? metadata.sha256.toLowerCase() : '';
      if (!/^[0-9a-f]{64}$/.test(sha256)) throw new HttpError(400, 'VALIDATION', 'SHA-256 inválido.');
      const existing = await prisma.evidence.findUnique({ where: { id: evidenceId } });
      if (existing) { if (existing.sha256 !== sha256) throw new HttpError(409, 'CONFLICT', 'Evidence ID con hash distinto.'); response.json({ status: 'exists', evidence: existing }); return; }
      const stored = await storage.store(request.file.path, sha256, path.extname(request.file.originalname).toLowerCase());
      const sampleExists = await prisma.sample.findUnique({ where: { id: sampleId }, select: { id: true } });
      const item = await prisma.evidence.create({ data: { id: evidenceId, sampleId: sampleExists?.id ?? null, pendingSampleId: sampleExists == null ? sampleId : null, sha256, storageKey: stored.key, originalFilename: request.file.originalname, mimeType: request.file.mimetype, sizeBytes: stored.sizeBytes, payload: json(metadata) } });
      response.status(201).json({ status: 'created', evidence: item });
    } catch (error) {
      if (request.file) await unlink(request.file.path).catch(() => undefined);
      next(error);
    }
  });
  app.get('/api/v1/evidence/:id', async (request, response, next) => { try { const item = await prisma.evidence.findUnique({ where: { id: request.params.id } }); if (!item) throw new HttpError(404, 'NOT_FOUND', 'Evidencia no encontrada.'); await storage.send(item.storageKey, response, item.mimeType); } catch (error) { next(error); } });
  app.get('/api/v1/evidence', async (request, response, next) => {
    try { response.json({ items: await prisma.evidence.findMany({ where: compactWhere({ sampleId: stringQuery(request.query.sample_id), pendingSampleId: stringQuery(request.query.pending_sample_id) }), orderBy: { createdAt: 'desc' }, take: 100 }) }); } catch (error) { next(error); }
  });

  app.post('/api/v1/cases/:id/reports', async (request, response, next) => { try { const body = reportSchema.parse(request.body as unknown); const item = await prisma.report.create({ data: { id: body.report_id, caseId: request.params.id, version: body.version, checksum: body.checksum, htmlKey: body.html_key ?? null, pdfKey: body.pdf_key ?? null, payload: json(body) } }); response.status(201).json(item); } catch (error) { next(error); } });
  app.get('/api/v1/cases/:id/report', async (request, response, next) => { try { const item = await prisma.report.findFirst({ where: { caseId: request.params.id }, orderBy: { version: 'desc' } }); if (!item) throw new HttpError(404, 'NOT_FOUND', 'Reporte no encontrado.'); response.json(item); } catch (error) { next(error); } });

  app.post('/api/v1/sync/push', async (request, response, next) => { try { const body = syncSchema.parse(request.body); const results: unknown[] = []; for (const item of body.items) { results.push(await pushItem(prisma, item.entity_type, item.payload)); } response.json({ items: results }); } catch (error) { next(error); } });
  app.get('/api/v1/sync/pull', async (request, response, next) => { try { const sinceValue = stringQuery(request.query.since); const since = sinceValue ? new Date(sinceValue) : new Date(0); response.json({ server_time: new Date().toISOString(), cases: await prisma.verificationCase.findMany({ where: { updatedAt: { gt: since } } }), flow_points: await prisma.flowPoint.findMany({ where: { updatedAt: { gt: since } } }) }); } catch (error) { next(error); } });

  app.get('/api/v1/external/hydrants/accounts/:meterId', async (request, response, next) => {
    try { response.json(await hydrants.findByAccount(request.params.meterId)); } catch (error) { next(error); }
  });
  app.use(notFound, errorHandler);
  return app;
}

const userJson = (user: { id: string; email: string; phone: string; displayName: string | null }) => ({ user_id: user.id, email: user.email, phone: user.phone, display_name: user.displayName });
const stringQuery = (value: unknown) => typeof value === 'string' && value.length > 0 ? value : undefined;
const compactWhere = (value: Record<string, string | undefined>) => Object.fromEntries(Object.entries(value).filter((entry): entry is [string, string] => entry[1] !== undefined));
const responseJson = (response: express.Response, value: unknown) => response.json(value);
const requireAuth = (request: AuthenticatedRequest) => { if (!request.auth) throw new HttpError(401, 'AUTH', 'Sesión requerida.'); return request.auth; };

async function upsertCase(prisma: PrismaClient, body: ReturnType<typeof caseSchema.parse>) {
  const existing = await prisma.verificationCase.findUnique({ where: { id: body.case_id } });
  if (existing?.checksum && body.checksum && existing.checksum !== body.checksum) throw new HttpError(409, 'CONFLICT', 'Expediente cerrado con checksum distinto.');
  if (existing) return 200;
  await prisma.meter.upsert({ where: { id: body.meter_id }, update: {}, create: { id: body.meter_id, externalStatus: 'UNKNOWN_OFFLINE' } });
  await prisma.verificationCase.create({ data: { id: body.case_id, meterId: body.meter_id, userId: body.user_id, status: body.status, overallVerdict: body.overall_verdict ?? null, reportVersion: body.report_version, checksum: body.checksum ?? null, payload: json(body), createdAt: new Date(body.created_at), closedAt: date(body.closed_at) ?? null } });
  return 201;
}

async function pushItem(prisma: PrismaClient, type: string, payload: Record<string, unknown>) {
  if (type === 'case') { const body = caseSchema.parse(payload); return { entity_type: type, entity_id: body.case_id, status: (await upsertCase(prisma, body)) === 201 ? 'created' : 'exists' }; }
  if (type === 'sample') { const body = sampleSchema.parse(payload); const existing = await prisma.sample.findUnique({ where: { id: body.sample_id } }); if (existing && existing.checksum !== body.checksum) return { entity_type: type, entity_id: body.sample_id, status: 'conflict' }; if (!existing) await prisma.sample.create({ data: { id: body.sample_id, flowPointId: body.flow_point_id, sampleNumber: body.sample_number, status: body.status, checksum: body.checksum, payload: json(body), createdAt: new Date(body.created_at), startedAt: date(body.started_at) ?? null, endedAt: date(body.ended_at) ?? null } }); return { entity_type: type, entity_id: body.sample_id, status: existing ? 'exists' : 'created' }; }
  throw new HttpError(400, 'VALIDATION', `Entidad sync ${type} aún no es aceptada en lote.`);
}
