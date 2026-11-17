import {
  Controller,
  Get,
  HttpStatus,
  Inject,
  NotAcceptableException,
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { acceptsJson } from '../common/http/accept.util';
import { matchesIfNoneMatch } from '../common/http/etag.util';
import { QuestionCatalogService } from './question-catalog.service';

@Controller('v1/question-catalog')
export class QuestionCatalogController {
  constructor(
    @Inject(QuestionCatalogService)
    private readonly catalogService: QuestionCatalogService,
  ) {}

  @Get()
  async getQuestionCatalog(
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<void> {
    if (!acceptsJson(req.headers.accept)) {
      throw new NotAcceptableException(
        'This endpoint serves application/json only.',
      );
    }

    const prepared = await this.catalogService.getCatalog();

    res.setHeader('ETag', prepared.etag);
    res.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
    res.setHeader('Vary', 'Accept, Accept-Encoding');
    res.setHeader('X-Content-Type-Options', 'nosniff');

    if (matchesIfNoneMatch(req.headers['if-none-match'], prepared.etag)) {
      res.status(HttpStatus.NOT_MODIFIED).end();
      return;
    }

    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Content-Length', String(prepared.payloadBuffer.byteLength));
    res.status(HttpStatus.OK);

    if (req.method === 'HEAD') {
      res.end();
      return;
    }

    res.end(prepared.payloadBuffer);
  }
}
