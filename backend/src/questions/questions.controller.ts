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
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import { QuestionsService } from './questions.service';
import { parseListQuestionsQuery } from './questions.validator';

@Controller('v1/questions')
export class QuestionsController {
  constructor(
    @Inject(QuestionsService)
    private readonly questionsService: QuestionsService,
  ) {}

  @Get('meta')
  @Header('Cache-Control', 'no-store')
  async getMeta() {
    return await this.questionsService.getMeta();
  }

  @Get('export')
  @Header('Cache-Control', 'no-store')
  async exportCatalog(
    @Query('format') format: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const exported = await this.questionsService.exportCatalog(format);
    const body = `${JSON.stringify(exported.payload, null, 2)}\n`;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${exported.filename}"`,
    );
    res.status(HttpStatus.OK).end(Buffer.from(body, 'utf8'));
  }

  @Post('auth/verify')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AdminTokenGuard)
  verifyAdminToken() {
    return { ok: true };
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  async listQuestions(@Query() rawQuery: Record<string, unknown>) {
    const query = parseListQuestionsQuery(rawQuery);
    return await this.questionsService.listQuestions(query);
  }

  @Get(':id')
  @Header('Cache-Control', 'no-store')
  async getQuestionById(@Param('id') id: string) {
    return await this.questionsService.getQuestionById(id);
  }

  @Post('bulk')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AdminTokenGuard)
  async bulkCreateQuestions(@Body() body: unknown) {
    return await this.questionsService.bulkCreateQuestions(body);
  }

  @Post('bulk-action')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AdminTokenGuard)
  async bulkActionQuestions(@Body() body: unknown) {
    return await this.questionsService.bulkActionQuestions(body);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AdminTokenGuard)
  async createQuestion(@Body() body: unknown) {
    return await this.questionsService.createQuestion(body);
  }

  @Patch(':id')
  @UseGuards(AdminTokenGuard)
  async updateQuestion(@Param('id') id: string, @Body() body: unknown) {
    return await this.questionsService.updateQuestion(id, body);
  }

  @Delete(':id')
  @UseGuards(AdminTokenGuard)
  async deleteQuestion(@Param('id') id: string) {
    return await this.questionsService.deleteQuestion(id);
  }
}
