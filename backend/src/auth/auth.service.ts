import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import {
  constantTimeEquals,
  createSessionCookieToken,
  getAdminAuthConfig,
  matchesConfiguredSecret,
  readSessionFromRequest,
} from './auth.util';

interface AttemptBucket {
  count: number;
  resetAt: number;
}

const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const RATE_LIMIT_MAX_FAILURES = 12;

@Injectable()
export class AuthService {
  private readonly failedAttempts = new Map<string, AttemptBucket>();

  getSessionStatus(req: Request) {
    const config = getAdminAuthConfig();
    const session = readSessionFromRequest(req, config);
    return {
      authenticated: session !== null,
      authRequired: config.authConfigured || config.isProduction,
      devBypassAvailable: config.devBypassAvailable,
      username: session?.sub ?? null,
      expiresAt: session ? new Date(session.exp * 1000).toISOString() : null,
      configuredUsername: config.username,
    };
  }

  login(rawBody: unknown, req: Request) {
    const config = getAdminAuthConfig();
    if (!config.authConfigured && config.isProduction) {
      throw new ServiceUnavailableException(
        'Admin authentication is not configured.',
      );
    }

    if (
      rawBody !== undefined &&
      rawBody !== null &&
      (typeof rawBody !== 'object' || Array.isArray(rawBody))
    ) {
      throw new BadRequestException('Login payload must be a JSON object.');
    }

    const body = (rawBody ?? {}) as Record<string, unknown>;
    const clientKey = extractClientKey(req);
    this.assertNotRateLimited(clientKey);

    const rawUsername =
      typeof body.username === 'string' ? body.username.trim() : '';
    const rawCredential =
      typeof body.password === 'string'
        ? body.password.trim()
        : typeof body.token === 'string'
          ? body.token.trim()
          : typeof body.credential === 'string'
            ? body.credential.trim()
            : '';
    const devModeRequested = body.devMode === true;

    if (!config.authConfigured) {
      if (
        !devModeRequested &&
        rawCredential.length === 0 &&
        rawUsername.length === 0
      ) {
        throw new BadRequestException(
          'أدخل بيانات الدخول أو اختر الدخول بوضع التطوير المحلي.',
        );
      }
      const resolvedUser = rawUsername || config.username;
      this.failedAttempts.delete(clientKey);
      const issued = createSessionCookieToken(resolvedUser, config);
      return {
        ok: true,
        username: resolvedUser,
        devMode: true,
        expiresAt: issued.expiresAt,
        cookieToken: issued.token,
      };
    }

    const effectiveUsername = rawUsername || config.username;
    const usernameMatches = constantTimeEquals(
      effectiveUsername.toLowerCase(),
      config.username.toLowerCase(),
    );
    const credentialMatches = matchesConfiguredSecret(rawCredential, config);

    if (!usernameMatches || !credentialMatches) {
      this.recordFailure(clientKey);
      throw new UnauthorizedException(
        'اسم المستخدم أو كلمة المرور / رمز الإدارة غير صحيح.',
      );
    }

    this.failedAttempts.delete(clientKey);
    const issued = createSessionCookieToken(config.username, config);
    return {
      ok: true,
      username: config.username,
      devMode: false,
      expiresAt: issued.expiresAt,
      cookieToken: issued.token,
    };
  }

  private assertNotRateLimited(clientKey: string): void {
    const now = Date.now();
    const bucket = this.failedAttempts.get(clientKey);
    if (!bucket) return;
    if (now >= bucket.resetAt) {
      this.failedAttempts.delete(clientKey);
      return;
    }
    if (bucket.count >= RATE_LIMIT_MAX_FAILURES) {
      throw new HttpException(
        'تم تجاوز عدد محاولات تسجيل الدخول. يرجى المحاولة لاحقًا.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private recordFailure(clientKey: string): void {
    const now = Date.now();
    if (this.failedAttempts.size > 500) {
      for (const [k, v] of this.failedAttempts.entries()) {
        if (now >= v.resetAt) this.failedAttempts.delete(k);
      }
    }
    const existing = this.failedAttempts.get(clientKey);
    if (!existing || now >= existing.resetAt) {
      this.failedAttempts.set(clientKey, {
        count: 1,
        resetAt: now + RATE_LIMIT_WINDOW_MS,
      });
      return;
    }
    existing.count += 1;
  }
}

function extractClientKey(req: Request): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim().length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || 'unknown';
}
