import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureNestApp } from '../src/app.factory';
import { QuestionCatalogLoader } from '../src/question-catalog/question-catalog.loader';
import { QUESTION_CATALOG_STORE } from '../src/question-catalog/question-catalog.service';
import { MemoryCatalogStore } from '../src/question-catalog/question-catalog.store';
import { createHash } from 'node:crypto';

describe('Questions Management APIs & Dashboard (e2e)', () => {
  let app: INestApplication;
  const originalAdminToken = process.env.ADMIN_API_TOKEN;

  beforeAll(async () => {
    delete process.env.ADMIN_API_TOKEN;
    const loader = new QuestionCatalogLoader();
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(QUESTION_CATALOG_STORE)
      .useValue(new MemoryCatalogStore(loader))
      .compile();

    app = moduleFixture.createNestApplication();
    configureNestApp(app);
    await app.init();
  });

  afterEach(() => {
    if (originalAdminToken === undefined) {
      delete process.env.ADMIN_API_TOKEN;
    } else {
      process.env.ADMIN_API_TOKEN = originalAdminToken;
    }
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /dashboard serves Wefaq Arabic RTL dashboard with Wefaq colors and logo', async () => {
    const res = await request(app.getHttpServer())
      .get('/dashboard')
      .expect(200);

    expect(res.headers['content-type']).toMatch(/^text\/html;\s*charset=utf-8$/i);
    expect(res.headers['x-frame-options']).toBe('DENY');
    expect(res.headers['content-security-policy']).toContain("frame-ancestors 'none'");
    const script = /<script>([\s\S]*?)<\/script>/.exec(res.text)?.[1];
    expect(script).toBeDefined();
    expect(() => new Function(script!)).not.toThrow();
    const hash = createHash('sha256').update(script!, 'utf8').digest('base64');
    expect(res.headers['content-security-policy']).toContain(`script-src 'sha256-${hash}'`);
    expect(res.text).toContain('dir="rtl"');
    expect(res.text).toContain('#205C4A');
    expect(res.text).toContain('#FAF8F2');
    expect(res.text).toContain('#B58A45');
    expect(res.text).toContain('/logo.png');
    expect(res.text).not.toContain('sessionStorage.setItem');
    expect(res.text).not.toContain('localStorage.setItem');
  });

  it('GET /logo.png and /favicon.png serve the Wefaq PNG logo', async () => {
    const res = await request(app.getHttpServer()).get('/logo.png').expect(200);
    expect(res.headers['content-type']).toBe('image/png');
    expect(Number(res.headers['content-length'])).toBeGreaterThan(1000);
  });

  it('GET /v1/questions filters, searches, and paginates questions', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/questions?topic=finances&depth=deeper&limit=10&page=1')
      .expect(200);

    expect(res.body.total).toBe(600);
    expect(res.body.filteredTotal).toBe(60);
    expect(res.body.items).toHaveLength(10);
    expect(res.body.counts.byTopic.finances).toBe(120);
    for (const item of res.body.items as Array<Record<string, unknown>>) {
      expect(item.topic).toBe('finances');
      expect(item.depth).toBe('deeper');
    }
  });

  it('supports full create, edit, catalog ETag propagation, and delete flow', async () => {
    const initialCatalog = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .expect(200);
    const initialEtag = initialCatalog.headers.etag;
    const initialRevision = initialCatalog.body.revision as number;

    const created = await request(app.getHttpServer())
      .post('/v1/questions')
      .send({
        id: 'dashboard-test-1',
        text: 'سؤال مضاف من لوحة التحكم',
        clarification: 'توضيح السؤال التجريبي',
        topic: 'communication',
        depth: 'introductory',
        suitableModes: ['together', 'phone'],
      })
      .expect(201);

    expect(created.body.question.id).toBe('dashboard-test-1');
    expect(created.body.question.isDevelopmentOnly).toBe(true);
    expect(created.body.catalog.revision).toBe(initialRevision + 1);

    const updated = await request(app.getHttpServer())
      .patch('/v1/questions/dashboard-test-1')
      .send({
        text: 'نص محدث من لوحة التحكم',
        isDevelopmentOnly: false,
      })
      .expect(200);

    expect(updated.body.question.text).toBe('نص محدث من لوحة التحكم');
    expect(updated.body.question.isDevelopmentOnly).toBe(false);
    expect(updated.body.catalog.revision).toBe(initialRevision + 2);

    const refreshedCatalog = await request(app.getHttpServer())
      .get('/v1/question-catalog')
      .set('If-None-Match', initialEtag)
      .expect(200);

    expect(refreshedCatalog.headers.etag).not.toBe(initialEtag);
    expect(refreshedCatalog.body.revision).toBe(initialRevision + 2);
    expect(refreshedCatalog.body.questions).toHaveLength(601);

    await request(app.getHttpServer())
      .delete('/v1/questions/dashboard-test-1')
      .expect(200);

    await request(app.getHttpServer())
      .get('/v1/questions/dashboard-test-1')
      .expect(404);
  });

  it('enforces ADMIN_API_TOKEN when configured while leaving reads public', async () => {
    process.env.ADMIN_API_TOKEN = 'super-secret-wefaq-token';

    await request(app.getHttpServer()).get('/v1/questions/meta').expect(200);

    await request(app.getHttpServer())
      .post('/v1/questions')
      .send({
        text: 'محاولة بدون تصريح',
        topic: 'communication',
        depth: 'introductory',
        suitableModes: ['together'],
      })
      .expect(401);

    await request(app.getHttpServer())
      .post('/v1/questions/auth/verify')
      .set('Authorization', 'Bearer wrong-token')
      .expect(401);

    await request(app.getHttpServer())
      .post('/v1/questions/auth/verify')
      .set('Authorization', 'Bearer super-secret-wefaq-token')
      .expect(200);
  });

  it('fails closed on Vercel if no admin token is configured', async () => {
    const originalVercel = process.env.VERCEL;
    const originalToken = process.env.ADMIN_API_TOKEN;
    try {
      process.env.VERCEL = '1';
      delete process.env.ADMIN_API_TOKEN;
      await request(app.getHttpServer()).get('/v1/questions/meta').expect(200);
      await request(app.getHttpServer())
        .post('/v1/questions')
        .send({ text: 'سؤال', topic: 'communication', depth: 'introductory', suitableModes: ['together'] })
        .expect(503);
    } finally {
      if (originalVercel === undefined) delete process.env.VERCEL;
      else process.env.VERCEL = originalVercel;
      if (originalToken === undefined) delete process.env.ADMIN_API_TOKEN;
      else process.env.ADMIN_API_TOKEN = originalToken;
    }
  });
});
