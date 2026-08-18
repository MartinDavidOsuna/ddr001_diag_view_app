import { PrismaClient } from '@prisma/client';
import { createApp } from './app.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const prisma = new PrismaClient();
const app = await createApp(prisma, config);
const server = app.listen(config.PORT, () => process.stdout.write(`DDR001 API listening on ${String(config.PORT)}\n`));

const shutdown = async () => {
  server.close();
  await prisma.$disconnect();
};
process.on('SIGINT', () => { void shutdown(); });
process.on('SIGTERM', () => { void shutdown(); });
