import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { createConfiguredApp } from './app.factory';

async function bootstrap(): Promise<void> {
  const app = await createConfiguredApp();
  const port = Number.parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(Number.isFinite(port) ? port : 3000);
  Logger.log(
    `Wefaq Questions API listening on port ${Number.isFinite(port) ? port : 3000}`,
    'Bootstrap',
  );
}

void bootstrap();
