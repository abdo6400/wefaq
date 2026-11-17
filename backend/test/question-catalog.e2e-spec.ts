import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureNestApp } from '../src/app.factory';
import { QuestionCatalogLoader } from '../src/question-catalog/question-catalog.loader';
import { QuestionCatalogModule } from '../src/question-catalog/question-catalog.module';
import { QuestionCatalogService } from '../src/question-catalog/question-catalog.service';
import {
  VALID_DEPTHS,
  VALID_SUITABLE_MODES,
  VALID_TOPICS,
} from '../src/question-catalog/question-catalog.types';

describe('Questions API Contract (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureNestApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET / returns service metadata without personal data', async () => {
    const res = await request(app.getHttpServer()).get('/').expect(200);

    expect(res.body).toMatchObject({
      service: 'wefaq-questions-api',
      contract: 'questions-api-contract v1',
      status: 'ok',
      endpoints: {
        dashboard: '/dashboard',
        questionCatalog: '/v1/question-catalog',
        questions: '/v1/questions',
        health: '/v1/health',
      },
      catalog: {
        schemaVersion: 1,
        revision: 1,
        questionCount: 600,
        containsDevelopmentOnlyQuestions: true,
      },
    });
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('GET /v1/health returns ok status', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/health')
      .expect(200);

    expect(res.body).toMatchObject({
      status: 'ok',
      schemaVersion: 1,
      revision: 1,
      questionCount: 600,
    });
  });

  it('GET /v1/question-catalog returns 200 UTF-8 JSON with ETag and contract schema', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('Accept', 'application/json')
      .expect(200);

    expect(res.headers['content-type']).toMatch(
      /^application\/json;\s*charset=utf-8$/i,
    );
    expect(res.headers.etag).toMatch(/^"v1-r1-[0-9a-f]{16}"$/);
    expect(res.headers['cache-control']).toBe(
      'public, max-age=0, must-revalidate',
    );

    const payload = res.body as {
      schemaVersion: number;
      revision: number;
      publishedAt: string;
      questions: Array<Record<string, unknown>>;
    };

    expect(payload.schemaVersion).toBe(1);
    expect(payload.revision).toBe(1);
    expect(payload.publishedAt).toBe('2026-11-12T17:00:00Z');
    expect(Array.isArray(payload.questions)).toBe(true);
    expect(payload.questions).toHaveLength(600);

    const seenIds = new Set<string>();
    for (const q of payload.questions) {
      expect(typeof q.id).toBe('string');
      expect((q.id as string).trim().length).toBeGreaterThan(0);
      expect(seenIds.has(q.id as string)).toBe(false);
      seenIds.add(q.id as string);

      expect(typeof q.text).toBe('string');
      expect((q.text as string).trim().length).toBeGreaterThan(0);
      expect(VALID_TOPICS).toContain(q.topic);
      expect(VALID_DEPTHS).toContain(q.depth);
      expect(Array.isArray(q.suitableModes)).toBe(true);
      expect((q.suitableModes as string[]).length).toBeGreaterThan(0);
      for (const mode of q.suitableModes as string[]) {
        expect(VALID_SUITABLE_MODES).toContain(mode);
      }
      expect(typeof q.isDevelopmentOnly).toBe('boolean');
    }
  });

  it('GET /v1/question-catalog returns 304 Not Modified with empty body when If-None-Match matches', async () => {
    const first = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('Accept', 'application/json')
      .expect(200);

    const etag = first.headers.etag;

    const notModified = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('Accept', 'application/json')
      .set('If-None-Match', etag)
      .expect(304);

    expect(notModified.headers.etag).toBe(etag);
    expect(notModified.text).toBe('');

    const weakNotModified = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('If-None-Match', `W/${etag}`)
      .expect(304);

    expect(weakNotModified.text).toBe('');
  });

  it('GET /v1/question-catalog returns 200 OK when If-None-Match is stale', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('Accept', 'application/json')
      .set('If-None-Match', '"v1-r0-staleetag"')
      .expect(200);

    expect(res.body.questions).toHaveLength(600);
  });

  it('HEAD /v1/question-catalog returns 200 headers with empty body', async () => {
    const res = await request(app.getHttpServer())
      .head('/v1/question-catalog')
      .set('Accept', 'application/json')
      .expect(200);

    expect(res.headers.etag).toMatch(/^"v1-r1-[0-9a-f]{16}"$/);
    expect(Number(res.headers['content-length'])).toBeGreaterThan(0);
  });

  it('GET /v1/question-catalog returns 406 when Accept excludes application/json', async () => {
    await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('Accept', 'text/plain')
      .expect(406);
  });

  it('fails closed with 503 when requireApprovedOnly=true and only development questions exist', async () => {
    const strictModule = await Test.createTestingModule({
      imports: [QuestionCatalogModule],
    })
      .overrideProvider(QuestionCatalogService)
      .useFactory({
        factory: (loader: QuestionCatalogLoader) =>
          new QuestionCatalogService(loader, { requireApprovedOnly: true }),
        inject: [QuestionCatalogLoader],
      })
      .compile();

    const strictApp = strictModule.createNestApplication();
    configureNestApp(strictApp);
    await strictApp.init();

    try {
      await request(strictApp.getHttpServer())
        .get('/v1/question-catalog')
        .set('Accept', 'application/json')
        .expect(503);
    } finally {
      await strictApp.close();
    }
  });
});
