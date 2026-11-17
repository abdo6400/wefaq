import { Module } from '@nestjs/common';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import {
  createJsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import { LicensesController } from './licenses.controller';
import {
  FALLBACK_LICENSES_REGISTRY,
  LICENSES_STORE,
  LicensesService,
} from './licenses.service';
import { LicensesRegistrySnapshot } from './licenses.types';

@Module({
  controllers: [LicensesController],
  providers: [
    {
      provide: LICENSES_STORE,
      useFactory: () =>
        createJsonDocumentStore<LicensesRegistrySnapshot>({
          filename: 'licenses-registry.v1.json',
          blobPathname: 'wefaq/licenses-registry.v1.json',
          envPathVar: 'LICENSES_FILE_PATH',
          seedFactory: () =>
            loadSeedFileOrFallback(
              'licenses-registry.v1.json',
              () => FALLBACK_LICENSES_REGISTRY,
            ),
        }),
    },
    LicensesService,
    AdminTokenGuard,
  ],
  exports: [LicensesService],
})
export class LicensesModule {}
