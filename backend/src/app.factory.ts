import { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';

export function configureNestApp(app: INestApplication): INestApplication {
  const httpAdapter = app.getHttpAdapter();
  const instance = httpAdapter.getInstance() as {
    disable?: (setting: string) => void;
    set?: (setting: string, value: unknown) => void;
    use?: (
      handler: (req: Request, res: Response, next: NextFunction) => void,
    ) => void;
  };

  if (typeof instance.disable === 'function') {
    instance.disable('x-powered-by');
  }
  if (typeof instance.set === 'function') {
    // Use explicit deterministic opaque ETags generated from validated snapshots.
    instance.set('etag', false);
  }
  if (typeof instance.use === 'function') {
    instance.use((_req: Request, res: Response, next: NextFunction) => {
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('Referrer-Policy', 'no-referrer');
      next();
    });
  }

  app.enableCors({
    origin: true,
    methods: ['GET', 'HEAD', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Accept',
      'If-None-Match',
      'Content-Type',
      'Authorization',
      'X-Admin-Token',
    ],
    exposedHeaders: ['ETag', 'Cache-Control', 'Content-Length'],
  });

  return app;
}

export async function createConfiguredApp(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  return configureNestApp(app);
}
