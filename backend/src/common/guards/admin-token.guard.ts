import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import {
  extractBearerOrHeaderToken,
  getAdminAuthConfig,
  matchesConfiguredSecret,
  readSessionFromRequest,
} from '../../auth/auth.util';

export function isAdminAuthConfigured(): boolean {
  return getAdminAuthConfig().authConfigured;
}

/**
 * Protects admin endpoints via Bearer/X-Admin-Token or signed HttpOnly session cookie.
 * Fails closed in production/Vercel when neither ADMIN_API_TOKEN nor ADMIN_PASSWORD is set.
 */
@Injectable()
export class AdminTokenGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const config = getAdminAuthConfig();
    if (!config.authConfigured && config.isProduction) {
      throw new ServiceUnavailableException(
        'Admin authentication is not configured.',
      );
    }

    const req = context.switchToHttp().getRequest<Request>();
    const providedToken = extractBearerOrHeaderToken(req);

    if (providedToken !== null) {
      if (config.authConfigured && matchesConfiguredSecret(providedToken, config)) {
        return true;
      }
      if (!config.authConfigured && !config.isProduction) {
        return true;
      }
      throw new UnauthorizedException(
        'Valid admin token is required to modify resources.',
      );
    }

    const session = readSessionFromRequest(req, config);
    if (session !== null) {
      return true;
    }

    if (!config.authConfigured) {
      return true;
    }

    throw new UnauthorizedException(
      'Valid admin sign-in or token is required to modify resources.',
    );
  }
}
