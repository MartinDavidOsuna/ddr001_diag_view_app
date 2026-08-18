import type { AppConfig } from '../config.js';
import { HttpError } from '../http/errors.js';

export type HydrantLookup = {
  status: 'FOUND_WITH_SURVEY' | 'FOUND_NO_SURVEY' | 'NOT_FOUND';
  account_number: string;
  data?: Record<string, unknown>;
};

export class HydrantsClient {
  constructor(private readonly config: AppConfig) {}

  async findByAccount(accountNumber: string): Promise<HydrantLookup> {
    const baseUrl = this.config.HYDRANTS_API_BASE_URL?.replace(/\/$/, '');
    const token = this.config.HYDRANTS_API_TOKEN;
    if (!baseUrl || !token) {
      throw new HttpError(503, 'EXTERNAL_API_UNAVAILABLE', 'API de hidrantes no configurada.');
    }

    let response: Response;
    try {
      response = await fetch(`${baseUrl}/api/v1/hydrants/${encodeURIComponent(accountNumber)}`, {
        headers: { authorization: `Bearer ${token}`, accept: 'application/json' },
        signal: AbortSignal.timeout(8_000),
      });
    } catch {
      throw new HttpError(503, 'EXTERNAL_API_UNAVAILABLE', 'API de hidrantes no disponible.');
    }
    if (response.status === 404) return { status: 'NOT_FOUND', account_number: accountNumber };
    if (!response.ok) throw new HttpError(503, 'EXTERNAL_API_UNAVAILABLE', 'La consulta de hidrantes no pudo completarse.');

    const body = await response.json() as Record<string, unknown>;
    const hasInspection = typeof body.officialInspectionId === 'string' || typeof body.latestInspectionId === 'string';
    return {
      status: hasInspection ? 'FOUND_WITH_SURVEY' : 'FOUND_NO_SURVEY',
      account_number: accountNumber,
      data: body,
    };
  }
}
