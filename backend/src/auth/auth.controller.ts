import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Inject,
  Post,
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AuthService } from './auth.service';
import {
  ADMIN_SESSION_COOKIE,
  ADMIN_SESSION_TTL_SECONDS,
  isHttpsRequest,
} from './auth.util';

@Controller('v1/auth')
export class AuthController {
  constructor(
    @Inject(AuthService)
    private readonly authService: AuthService,
  ) {}

  @Get('session')
  @Header('Cache-Control', 'no-store')
  getSession(@Req() req: Request) {
    return this.authService.getSessionStatus(req);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Header('Cache-Control', 'no-store')
  login(
    @Body() body: unknown,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = this.authService.login(body, req);
    const cookieParts = [
      `${ADMIN_SESSION_COOKIE}=${encodeURIComponent(result.cookieToken)}`,
      'Path=/',
      `Max-Age=${ADMIN_SESSION_TTL_SECONDS}`,
      'HttpOnly',
      'SameSite=Strict',
    ];
    if (isHttpsRequest(req)) {
      cookieParts.push('Secure');
    }
    res.setHeader('Set-Cookie', cookieParts.join('; '));

    return {
      ok: result.ok,
      username: result.username,
      devMode: result.devMode,
      expiresAt: result.expiresAt,
    };
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @Header('Cache-Control', 'no-store')
  logout(
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const cookieParts = [
      `${ADMIN_SESSION_COOKIE}=`,
      'Path=/',
      'Max-Age=0',
      'HttpOnly',
      'SameSite=Strict',
    ];
    if (isHttpsRequest(req)) {
      cookieParts.push('Secure');
    }
    res.setHeader('Set-Cookie', cookieParts.join('; '));
    return { ok: true };
  }
}
