import { Module } from '@nestjs/common';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import {
  createJsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import { AppConfigController } from './app-config.controller';
import {
  APP_CONFIG_STORE,
  AppConfigService,
  FALLBACK_APP_CONFIG,
} from './app-config.service';
import { AppConfigSnapshot } from './app-config.types';

@Module({
  controllers: [AppConfigController],
  providers: [
    {
      provide: APP_CONFIG_STORE,
      useFactory: () =>
        createJsonDocumentStore<AppConfigSnapshot>({
          filename: 'app-config.v1.json',
          blobPathname: 'wefaq/app-config.v1.json',
          envPathVar: 'APP_CONFIG_FILE_PATH',
          seedFactory: () =>
            loadSeedFileOrFallback(
              'app-config.v1.json',
              () => FALLBACK_APP_CONFIG,
            ),
        }),
    },
    AppConfigService,
    AdminTokenGuard,
  ],
  exports: [AppConfigService],
})
export class AppConfigModule {}
