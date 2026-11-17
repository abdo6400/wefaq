import { Module } from '@nestjs/common';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import {
  createJsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import { ActivitiesController } from './activities.controller';
import { ACTIVITIES_STORE, ActivitiesService, FALLBACK_ACTIVITIES_SEED } from './activities.service';
import { ActivityCatalogSnapshot } from './activities.types';

@Module({
  controllers: [ActivitiesController],
  providers: [
    {
      provide: ACTIVITIES_STORE,
      useFactory: () =>
        createJsonDocumentStore<ActivityCatalogSnapshot>({
          filename: 'activities-catalog.v1.json',
          blobPathname: 'wefaq/activities-catalog.v1.json',
          envPathVar: 'ACTIVITIES_FILE_PATH',
          seedFactory: () =>
            loadSeedFileOrFallback(
              'activities-catalog.v1.json',
              () => FALLBACK_ACTIVITIES_SEED,
            ),
        }),
    },
    ActivitiesService,
    AdminTokenGuard,
  ],
  exports: [ActivitiesService],
})
export class ActivitiesModule {}
