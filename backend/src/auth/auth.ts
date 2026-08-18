import { createHash, randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import type { PrismaClient, User } from '@prisma/client';
import { HttpError } from '../http/errors.js';

export type AuthenticatedRequest = Request & { auth?: { user: User; sessionId: string; tokenHash: string } };
const hash = (value: string) => createHash('sha256').update(value).digest('hex');

export class AuthService {
  constructor(private readonly prisma: PrismaClient, private readonly secret: string) {}

  async login(input: { displayName: string; email: string; phone: string }) {
    const email = input.email.trim().toLowerCase();
    const phone = `${input.phone.trim().startsWith('+') ? '+' : ''}${input.phone.replace(/\D/g, '')}`;
    const displayName = input.displayName.trim();
    const existing = await this.prisma.user.findUnique({ where: { email_phone: { email, phone } } });
    const user = existing
      ? await this.prisma.user.update({ where: { id: existing.id }, data: { displayName: existing.displayName ?? displayName, lastLoginAt: new Date() } })
      : await this.prisma.user.create({ data: { id: randomUUID(), email, phone, displayName, lastLoginAt: new Date() } });
    const sessionId = randomUUID();
    const token = jwt.sign({ sub: user.id, sid: sessionId }, this.secret);
    await this.prisma.authSession.create({ data: { id: sessionId, userId: user.id, tokenHash: hash(token) } });
    return { token, user };
  }

  middleware = async (request: AuthenticatedRequest, _response: Response, next: NextFunction) => {
    try {
      const token = request.header('authorization')?.replace(/^Bearer\s+/i, '');
      if (!token) throw new HttpError(401, 'AUTH', 'Sesión requerida.');
      const payload = jwt.verify(token, this.secret) as jwt.JwtPayload;
      const sessionId = String(payload.sid ?? '');
      const session = await this.prisma.authSession.findUnique({ where: { id: sessionId }, include: { user: true } });
      if (!session || session.revokedAt || session.userId !== payload.sub || session.tokenHash !== hash(token)) {
        throw new HttpError(401, 'AUTH', 'Sesión inválida o revocada.');
      }
      request.auth = { user: session.user, sessionId, tokenHash: session.tokenHash };
      next();
    } catch (error) {
      next(error instanceof HttpError ? error : new HttpError(401, 'AUTH', 'Sesión inválida.'));
    }
  };

  async logout(sessionId: string) {
    await this.prisma.authSession.update({ where: { id: sessionId }, data: { revokedAt: new Date() } });
  }
}
