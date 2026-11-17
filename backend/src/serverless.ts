import 'reflect-metadata';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { createConfiguredApp } from './app.factory';

export type HttpRequestHandler = (
  req: IncomingMessage,
  res: ServerResponse,
) => void | Promise<void>;

let cachedHandlerPromise: Promise<HttpRequestHandler> | null = null;

/**
 * Lazily initializes and caches the NestJS Express handler for serverless
 * invocations, ensuring concurrent cold-start requests share one boot cycle.
 */
export function getServerlessHandler(): Promise<HttpRequestHandler> {
  if (!cachedHandlerPromise) {
    cachedHandlerPromise = (async () => {
      const app = await createConfiguredApp();
      await app.init();
      return app.getHttpAdapter().getInstance() as HttpRequestHandler;
    })().catch((error: unknown) => {
      cachedHandlerPromise = null;
      throw error;
    });
  }
  return cachedHandlerPromise;
}
