import { Controller, Get, Header, Inject } from '@nestjs/common';
import { QuestionCatalogService } from '../question-catalog/question-catalog.service';

@Controller()
export class HealthController {
  constructor(
    @Inject(QuestionCatalogService)
    private readonly catalogService: QuestionCatalogService,
  ) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  async getServiceInfo() {
    let catalogSummary: Record<string, unknown> | null = null;
    try {
      const prepared = await this.catalogService.getCatalog();
      catalogSummary = {
        schemaVersion: prepared.snapshot.schemaVersion,
        revision: prepared.snapshot.revision,
        publishedAt: prepared.snapshot.publishedAt,
        questionCount: prepared.snapshot.questions.length,
        containsDevelopmentOnlyQuestions:
          prepared.containsDevelopmentOnlyQuestions,
      };
    } catch {
      catalogSummary = null;
    }

    return {
      service: 'wefaq-questions-api',
      contract: 'questions-api-contract v1',
      status: catalogSummary ? 'ok' : 'unavailable',
      endpoints: {
        dashboard: '/dashboard',
        questionCatalog: '/v1/question-catalog',
        questions: '/v1/questions',
        activityCatalog: '/v1/activity-catalog',
        activities: '/v1/activities',
        appConfig: '/v1/app-config',
        health: '/v1/health',
      },
      catalog: catalogSummary,
    };
  }

  @Get(['health', 'v1/health'])
  @Header('Cache-Control', 'no-store')
  async getHealth() {
    const prepared = await this.catalogService.getCatalog();
    return {
      status: 'ok',
      schemaVersion: prepared.snapshot.schemaVersion,
      revision: prepared.snapshot.revision,
      publishedAt: prepared.snapshot.publishedAt,
      questionCount: prepared.snapshot.questions.length,
    };
  }
}
