import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import type { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createApp } from '../src/app.js';

describe('DDR001 API', () => {
  let storage: string;
  let users: Array<{ id: string; email: string; phone: string; displayName: string | null; createdAt: Date; lastLoginAt: Date | null }>;
  let sessions: Array<{ id: string; userId: string; tokenHash: string; revokedAt: Date | null }>;
  let prisma: PrismaClient;

  beforeEach(async () => {
    storage = await mkdtemp(path.join(tmpdir(), 'ddr001-api-'));
    users = [];
    sessions = [];
    const client = {
      user: {
        findUnique: vi.fn(async ({ where }: { where: { email_phone: { email: string; phone: string } } }) => users.find((u) => u.email === where.email_phone.email && u.phone === where.email_phone.phone) ?? null),
        create: vi.fn(async ({ data }: { data: typeof users[number] }) => { const value = { ...data, createdAt: new Date(), lastLoginAt: data.lastLoginAt ?? null }; users.push(value); return value; }),
        update: vi.fn(async ({ where, data }: { where: { id: string }; data: Partial<typeof users[number]> }) => { const index = users.findIndex((u) => u.id === where.id); users[index] = { ...users[index]!, ...data }; return users[index]!; }),
      },
      authSession: {
        create: vi.fn(async ({ data }: { data: typeof sessions[number] }) => { sessions.push({ ...data, revokedAt: null }); return data; }),
        findUnique: vi.fn(async ({ where }: { where: { id: string } }) => { const session = sessions.find((s) => s.id === where.id); if (!session) return null; const user = users.find((u) => u.id === session.userId)!; return { ...session, user }; }),
        update: vi.fn(async ({ where, data }: { where: { id: string }; data: { revokedAt: Date } }) => { const session = sessions.find((s) => s.id === where.id)!; session.revokedAt = data.revokedAt; return session; }),
      },
    };
    prisma = client as unknown as PrismaClient;
  });

  afterEach(async () => rm(storage, { recursive: true, force: true }));

  const app = () => createApp(prisma, {
    DATABASE_URL: 'postgresql://unused',
    JWT_SECRET: '01234567890123456789012345678901',
    PORT: 3000,
    EVIDENCE_STORAGE_PATH: storage,
  });

  it('reports liveness without database access', async () => {
    const response = await request(await app()).get('/api/v1/health/live');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  it('creates a passwordless user, reuses identity and revokes logout', async () => {
    const first = await request(await app()).post('/api/v1/auth/login').send({ display_name: 'Ana Campo', email: 'ANA@EXAMPLE.COM', phone: '+52 662 123 4567' });
    expect(first.status).toBe(200);
    expect(first.body.user.display_name).toBe('Ana Campo');
    const token = first.body.token as string;

    const second = await request(await app()).post('/api/v1/auth/login').send({ display_name: 'Nombre distinto', email: 'ana@example.com', phone: '+526621234567' });
    expect(second.body.user.user_id).toBe(first.body.user.user_id);
    expect(second.body.user.display_name).toBe('Ana Campo');
    expect(users).toHaveLength(1);

    const me = await request(await app()).get('/api/v1/auth/me').set('Authorization', `Bearer ${token}`);
    expect(me.status).toBe(200);
    const logout = await request(await app()).post('/api/v1/auth/logout').set('Authorization', `Bearer ${token}`);
    expect(logout.status).toBe(204);
    const revoked = await request(await app()).get('/api/v1/auth/me').set('Authorization', `Bearer ${token}`);
    expect(revoked.status).toBe(401);
  });

  it('validates login input at the HTTP boundary', async () => {
    const response = await request(await app()).post('/api/v1/auth/login').send({ display_name: '', email: 'bad', phone: '1' });
    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
});
