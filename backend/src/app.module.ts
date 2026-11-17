import { Module } from '@nestjs/common';
import { ActivitiesModule } from './activities/activities.module';
import { AppConfigModule } from './app-config/app-config.module';
import { AuthModule } from './auth/auth.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { HealthModule } from './health/health.module';
import { LicensesModule } from './licenses/licenses.module';
import { QuestionCatalogModule } from './question-catalog/question-catalog.module';
import { QuestionsModule } from './questions/questions.module';

@Module({
  imports: [
    AuthModule,
    QuestionCatalogModule,
    QuestionsModule,
    ActivitiesModule,
    AppConfigModule,
    LicensesModule,
    DashboardModule,
    HealthModule,
  ],
})
export class AppModule {}
