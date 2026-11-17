import { Module } from '@nestjs/common';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import { QuestionCatalogModule } from '../question-catalog/question-catalog.module';
import { QuestionsController } from './questions.controller';
import { QuestionsService } from './questions.service';

@Module({
  imports: [QuestionCatalogModule],
  controllers: [QuestionsController],
  providers: [QuestionsService, AdminTokenGuard],
  exports: [QuestionsService],
})
export class QuestionsModule {}
