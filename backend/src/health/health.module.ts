import { Module } from '@nestjs/common';
import { QuestionCatalogModule } from '../question-catalog/question-catalog.module';
import { HealthController } from './health.controller';

@Module({
  imports: [QuestionCatalogModule],
  controllers: [HealthController],
})
export class HealthModule {}
