import { Module } from '@nestjs/common';
import { QuestionCatalogController } from './question-catalog.controller';
import { QuestionCatalogLoader } from './question-catalog.loader';
import {
  QUESTION_CATALOG_CONFIG,
  QUESTION_CATALOG_STORE,
  QuestionCatalogService,
} from './question-catalog.service';
import { createDefaultCatalogStore } from './question-catalog.store';

@Module({
  controllers: [QuestionCatalogController],
  providers: [
    QuestionCatalogLoader,
    {
      provide: QUESTION_CATALOG_CONFIG,
      useValue: {},
    },
    {
      provide: QUESTION_CATALOG_STORE,
      inject: [QuestionCatalogLoader],
      useFactory: (loader: QuestionCatalogLoader) =>
        createDefaultCatalogStore(loader),
    },
    QuestionCatalogService,
  ],
  exports: [QuestionCatalogService],
})
export class QuestionCatalogModule {}
