import 'reflect-metadata';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { getServerlessHandler } from '../src/serverless';

export default async function handler(
  req: IncomingMessage,
  res: ServerResponse,
): Promise<void> {
  const appHandler = await getServerlessHandler();
  await appHandler(req, res);
}
