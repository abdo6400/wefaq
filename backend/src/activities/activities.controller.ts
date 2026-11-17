import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  Patch,
  Post,
  Query,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import { matchesIfNoneMatch } from '../common/http/etag.util';
import { ActivitiesService } from './activities.service';
import { parseListActivitiesQuery } from './activities.validator';

@Controller('v1')
export class ActivitiesController {
  constructor(
    @Inject(ActivitiesService)
    private readonly activitiesService: ActivitiesService,
  ) {}

  @Get('activity-catalog')
  async getActivityCatalog(
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<void> {
    const { etag, serializedJson } =
      await this.activitiesService.getSnapshot();

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

  @Get('activities')
  @Header('Cache-Control', 'no-store')
  async listActivities(@Query() rawQuery: Record<string, unknown>) {
    const query = parseListActivitiesQuery(rawQuery);
    return await this.activitiesService.listActivities(query);
  }

  @Get('activities/export')
  @Header('Cache-Control', 'no-store')
  async exportActivities(@Res() res: Response): Promise<void> {
    const { snapshot } = await this.activitiesService.getSnapshot();
    const body = `${JSON.stringify(snapshot, null, 2)}\n`;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="activities-catalog.v1.r${snapshot.revision}.json"`,
    );
    res.status(HttpStatus.OK).end(Buffer.from(body, 'utf8'));
  }

  @Post('activities')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AdminTokenGuard)
  async createActivity(@Body() body: unknown) {
    const { snapshot, result } =
      await this.activitiesService.createActivity(body);
    return {
      activity: result,
      revision: snapshot.revision,
      publishedAt: snapshot.publishedAt,
    };
  }

  @Patch('activities/:id')
  @UseGuards(AdminTokenGuard)
  async updateActivity(@Param('id') id: string, @Body() body: unknown) {
    const { snapshot, result } = await this.activitiesService.updateActivity(
      id,
      body,
    );
    return {
      activity: result,
      revision: snapshot.revision,
      publishedAt: snapshot.publishedAt,
    };
  }

  @Delete('activities/:id')
  @UseGuards(AdminTokenGuard)
  async deleteActivity(@Param('id') id: string) {
    const { snapshot, result } =
      await this.activitiesService.deleteActivity(id);
    return {
      deletedId: result,
      revision: snapshot.revision,
      publishedAt: snapshot.publishedAt,
    };
  }
}
