import { afterEach, describe, expect, it, vi } from 'vitest';
import { HydrantsClient } from '../src/external/hydrants_client.js';

const config = {
  DATABASE_URL: 'postgresql://unused',
  JWT_SECRET: '01234567890123456789012345678901',
  PORT: 3000,
  EVIDENCE_STORAGE_PATH: 'unused',
  HYDRANTS_API_BASE_URL: 'https://hidrantes.example',
  HYDRANTS_API_TOKEN: 'field-token',
};

describe('HydrantsClient', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('uses the inspected read-only account route and maps an existing inspection', async () => {
    const fetchMock = vi.fn(async (url: string, options: RequestInit) => {
      void url;
      void options;
      return new Response(JSON.stringify({ account_number: 'A/12', officialInspectionId: 'inspection-1' }), { status: 200 });
    });
    vi.stubGlobal('fetch', fetchMock);
    const result = await new HydrantsClient(config).findByAccount('A/12');
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, options] = fetchMock.mock.calls[0]!;
    expect(url).toBe('https://hidrantes.example/api/v1/hydrants/A%2F12');
    expect(options.headers).toMatchObject({ authorization: 'Bearer field-token' });
    expect(result.status).toBe('FOUND_WITH_SURVEY');
  });

  it('maps 404 without blocking the verification workflow', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response(null, { status: 404 })));
    await expect(new HydrantsClient(config).findByAccount('NEW')).resolves.toEqual({ status: 'NOT_FOUND', account_number: 'NEW' });
  });

  it('reports unconfigured and unreachable services as external unavailability', async () => {
    await expect(new HydrantsClient({ ...config, HYDRANTS_API_TOKEN: '' }).findByAccount('A')).rejects.toMatchObject({ status: 503 });
    vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('offline'); }));
    await expect(new HydrantsClient(config).findByAccount('A')).rejects.toMatchObject({ status: 503 });
  });
});
