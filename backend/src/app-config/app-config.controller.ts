import {
  Body,
  Controller,
  Get,
  HttpStatus,
  Inject,
  Patch,
  Put,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import { matchesIfNoneMatch } from '../common/http/etag.util';
import { AppConfigService } from './app-config.service';

@Controller('v1/app-config')
export class AppConfigController {
  constructor(
    @Inject(AppConfigService)
    private readonly appConfigService: AppConfigService,
  ) {}

  @Get()
  async getConfig(@Req() req: Request, @Res() res: Response): Promise<void> {
    const { etag, serializedJson } = await this.appConfigService.getConfig();

    res.setHeader('ETag', etag);
    res.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
    res.setHeader('X-Content-Type-Options', 'nosniff');

    if (matchesIfNoneMatch(req.headers['if-none-match'], etag)) {
      res.status(HttpStatus.NOT_MODIFIED).end();
      return;
    }

    const buffer = Buffer.from(serializedJson, 'utf8');
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Content-Length', String(buffer.byteLength));
    res.status(HttpStatus.OK).end(req.method === 'HEAD' ? undefined : buffer);
  }

  @Put()
  @UseGuards(AdminTokenGuard)
  async putConfig(@Body() body: unknown) {
    const config = await this.appConfigService.updateConfig(body);
    return { config };
  }

  @Patch()
  @UseGuards(AdminTokenGuard)
  async patchConfig(@Body() body: unknown) {
    const config = await this.appConfigService.updateConfig(body);
    return { config };
  }
}
