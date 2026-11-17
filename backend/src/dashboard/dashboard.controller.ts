import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import {
  Controller,
  Get,
  HttpStatus,
  NotFoundException,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { renderActivatePageHtml } from './activate.template';
import { renderDashboardHtml } from './dashboard.template';

const LOGO_FILENAME = 'wefaq-logo.png';

@Controller()
export class DashboardController {
  private readonly dashboardHtmlBuffer: Buffer;
  private readonly activateHtmlBuffer: Buffer;
  private readonly logoBuffer: Buffer | null;
  private readonly scriptHash: string;
  private readonly activateScriptHash: string;

  constructor() {
    const html = renderDashboardHtml();
    const script = /<script>([\s\S]*?)<\/script>/.exec(html)?.[1];
    if (script === undefined) throw new Error('Dashboard script missing');
    this.scriptHash = createHash('sha256')
      .update(script, 'utf8')
      .digest('base64');
    this.dashboardHtmlBuffer = Buffer.from(html, 'utf8');

    const activateHtml = renderActivatePageHtml();
    const activateScript = /<script>([\s\S]*?)<\/script>/.exec(
      activateHtml,
    )?.[1];
    if (activateScript === undefined) {
      throw new Error('Activate page script missing');
    }
    this.activateScriptHash = createHash('sha256')
      .update(activateScript, 'utf8')
      .digest('base64');
    this.activateHtmlBuffer = Buffer.from(activateHtml, 'utf8');

    this.logoBuffer = loadLogoBuffer();
  }

  @Get('dashboard')
  getDashboard(@Res() res: Response): void {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader(
      'Content-Security-Policy',
      `default-src 'self'; script-src 'sha256-${this.scriptHash}'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'`,
    );
    res.status(HttpStatus.OK).end(this.dashboardHtmlBuffer);
  }

  @Get('activate')
  getActivatePage(@Res() res: Response): void {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader(
      'Content-Security-Policy',
      `default-src 'self'; script-src 'sha256-${this.activateScriptHash}'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`,
    );
    res.status(HttpStatus.OK).end(this.activateHtmlBuffer);
  }

  @Get('.well-known/assetlinks.json')
  getAssetLinks(@Res() res: Response): void {
    const fingerprintsRaw =
      process.env.ANDROID_SHA256_FINGERPRINTS?.trim() ??
      process.env.ANDROID_SHA256_FINGERPRINT?.trim() ??
      '';
    if (!fingerprintsRaw) {
      throw new NotFoundException('Android assetlinks not configured.');
    }
    const fingerprints = fingerprintsRaw
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
    const packageName =
      process.env.ANDROID_PACKAGE_NAME?.trim() || 'com.wefaq.wefaq';

    const payload = [
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: packageName,
          sha256_cert_fingerprints: fingerprints,
        },
      },
    ];
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.status(HttpStatus.OK).end(Buffer.from(JSON.stringify(payload, null, 2), 'utf8'));
  }

  @Get(['logo.png', 'favicon.png'])
  getLogo(@Res() res: Response): void {
    if (!this.logoBuffer) {
      throw new NotFoundException('Wefaq logo asset not found.');
    }
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Length', String(this.logoBuffer.byteLength));
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.status(HttpStatus.OK).end(this.logoBuffer);
  }
}

function loadLogoBuffer(): Buffer | null {
  const candidates = [
    join(process.cwd(), 'data', LOGO_FILENAME),
    resolve(__dirname, '..', '..', 'data', LOGO_FILENAME),
    resolve(__dirname, '..', '..', '..', 'data', LOGO_FILENAME),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return readFileSync(candidate);
    }
  }
  return null;
}
