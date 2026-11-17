import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import type { Request } from 'express';

export const ADMIN_SESSION_COOKIE = 'wefaq_admin_session';
export const ADMIN_SESSION_TTL_SECONDS = 60 * 60 * 12; // 12 hours

const EPHEMERAL_DEV_SESSION_SECRET = randomBytes(32);

export interface AdminAuthConfig {
  readonly username: string;
  readonly password: string;
  readonly apiToken: string;
  readonly authConfigured: boolean;
  readonly isProduction: boolean;
  readonly devBypassAvailable: boolean;
}

export interface AdminSessionPayload {
  readonly sub: string;
  readonly mode: 'configured' | 'dev';
  readonly iat: number;
  readonly exp: number;
}

export function getAdminAuthConfig(): AdminAuthConfig {
  const username = process.env.ADMIN_USERNAME?.trim() || 'admin';
  const password = process.env.ADMIN_PASSWORD?.trim() ?? '';
  const apiToken = process.env.ADMIN_API_TOKEN?.trim() ?? '';
  const authConfigured = password.length > 0 || apiToken.length > 0;
  const isProduction =
    process.env.VERCEL === '1' || process.env.NODE_ENV === 'production';

  return {
    username,
    password,
    apiToken,
    authConfigured,
    isProduction,
    devBypassAvailable: !authConfigured && !isProduction,
  };
}

export function constantTimeEquals(a: string, b: string): boolean {
  const hashA = createHash('sha256').update(a, 'utf8').digest();
  const hashB = createHash('sha256').update(b, 'utf8').digest();
  return timingSafeEqual(hashA, hashB);
}

export function extractBearerOrHeaderToken(req: Request): string | null {
  const authHeader = req.headers.authorization;
  if (typeof authHeader === 'string') {
    const match = /^Bearer\s+(.+)$/i.exec(authHeader.trim());
    if (match && match[1].trim().length > 0) {
      return match[1].trim();
    }
  }

  const adminHeader = req.headers['x-admin-token'];
  if (typeof adminHeader === 'string' && adminHeader.trim().length > 0) {
    return adminHeader.trim();
  }

  return null;
}

export function matchesConfiguredSecret(
  provided: string,
  config: AdminAuthConfig,
): boolean {
  if (!provided) return false;
  if (config.apiToken && constantTimeEquals(provided, config.apiToken)) {
    return true;
  }
  if (config.password && constantTimeEquals(provided, config.password)) {
    return true;
  }
  return false;
}

function getSessionSigningKey(config: AdminAuthConfig): Buffer {
  const explicit = process.env.ADMIN_SESSION_SECRET?.trim() ?? '';
  if (explicit.length > 0) {
    return createHash('sha256').update(explicit, 'utf8').digest();
  }
  const secretSource = config.password || config.apiToken;
  if (secretSource.length > 0) {
    return createHmac('sha256', 'wefaq-admin-session-v1')
      .update(secretSource, 'utf8')
      .digest();
  }
  return EPHEMERAL_DEV_SESSION_SECRET;
}

export function createSessionCookieToken(
  username: string,
  config: AdminAuthConfig,
): { readonly token: string; readonly expiresAt: string } {
  const nowSec = Math.floor(Date.now() / 1000);
  const expSec = nowSec + ADMIN_SESSION_TTL_SECONDS;
  const payload: AdminSessionPayload = {
    sub: username,
    mode: config.authConfigured ? 'configured' : 'dev',
    iat: nowSec,
    exp: expSec,
  };
  const encodedPayload = Buffer.from(JSON.stringify(payload), 'utf8').toString(
    'base64url',
  );
  const sig = createHmac('sha256', getSessionSigningKey(config))
    .update(encodedPayload, 'utf8')
    .digest('base64url');
  return {
    token: `${encodedPayload}.${sig}`,
    expiresAt: new Date(expSec * 1000).toISOString(),
  };
}

export function verifySessionCookieToken(
  rawToken: string | undefined,
  config: AdminAuthConfig,
): AdminSessionPayload | null {
  if (!rawToken || rawToken.length > 2048) {
    return null;
  }
  const parts = rawToken.split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    return null;
  }

  const [encodedPayload, providedSig] = parts;
  const expectedSig = createHmac('sha256', getSessionSigningKey(config))
    .update(encodedPayload, 'utf8')
    .digest('base64url');

  if (!constantTimeEquals(providedSig, expectedSig)) {
    return null;
  }

  try {
    const parsed = JSON.parse(
      Buffer.from(encodedPayload, 'base64url').toString('utf8'),
    ) as unknown;
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return null;
    }
    const obj = parsed as Record<string, unknown>;
    if (
      typeof obj.sub !== 'string' ||
      obj.sub.trim().length === 0 ||
      (obj.mode !== 'configured' && obj.mode !== 'dev') ||
      typeof obj.iat !== 'number' ||
      typeof obj.exp !== 'number'
    ) {
      return null;
    }
    const nowSec = Math.floor(Date.now() / 1000);
    if (obj.exp <= nowSec) {
      return null;
    }
    if (config.authConfigured && obj.mode !== 'configured') {
      return null;
    }
    if (config.isProduction && obj.mode !== 'configured') {
      return null;
    }
    return {
      sub: obj.sub,
      mode: obj.mode,
      iat: obj.iat,
      exp: obj.exp,
    };
  } catch {
    return null;
  }
}

export function parseCookieHeader(
  cookieHeader: string | undefined,
): Record<string, string> {
  if (!cookieHeader) return {};
  const result: Record<string, string> = {};
  for (const part of cookieHeader.split(';')) {
    const idx = part.indexOf('=');
    if (idx <= 0) continue;
    const key = part.slice(0, idx).trim();
    const value = part.slice(idx + 1).trim();
    if (key) {
      try {
        result[key] = decodeURIComponent(value);
      } catch {
        result[key] = value;
      }
    }
  }
  return result;
}

export function readSessionFromRequest(
  req: Request,
  config: AdminAuthConfig = getAdminAuthConfig(),
): AdminSessionPayload | null {
  const cookies = parseCookieHeader(req.headers.cookie);
  return verifySessionCookieToken(cookies[ADMIN_SESSION_COOKIE], config);
}

export function isHttpsRequest(req: Request): boolean {
  if (req.secure) return true;
  const forwarded = req.headers['x-forwarded-proto'];
  if (typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim().toLowerCase() === 'https';
  }
  return process.env.VERCEL === '1';
}
