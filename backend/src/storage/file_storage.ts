import { createHash, randomUUID } from 'node:crypto';
import { mkdir, rename, stat } from 'node:fs/promises';
import path from 'node:path';
import { createReadStream } from 'node:fs';
import type { Response } from 'express';
import { HttpError } from '../http/errors.js';

export class FileStorage {
  constructor(private readonly root: string) {}

  async store(tempPath: string, expectedHash: string, extension: string) {
    const actualHash = await this.sha256(tempPath);
    if (actualHash !== expectedHash.toLowerCase()) throw new HttpError(400, 'STORAGE', 'SHA-256 de evidencia no coincide.');
    const key = `${actualHash.slice(0, 2)}/${actualHash}-${randomUUID()}${extension}`;
    const destination = this.resolve(key);
    await mkdir(path.dirname(destination), { recursive: true });
    await rename(tempPath, destination);
    return { key, sizeBytes: (await stat(destination)).size };
  }

  async send(key: string, response: Response, mimeType: string) {
    const file = this.resolve(key);
    await stat(file).catch(() => { throw new HttpError(404, 'NOT_FOUND', 'Evidencia no encontrada.'); });
    response.type(mimeType);
    createReadStream(file).pipe(response);
  }

  private resolve(key: string) {
    const full = path.resolve(this.root, key);
    const root = path.resolve(this.root);
    if (!full.startsWith(`${root}${path.sep}`)) throw new HttpError(400, 'STORAGE', 'Storage key inválida.');
    return full;
  }

  private async sha256(file: string) {
    const digest = createHash('sha256');
    for await (const chunk of createReadStream(file)) digest.update(chunk as Buffer);
    return digest.digest('hex');
  }
}
