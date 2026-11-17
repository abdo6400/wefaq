import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash } from 'node:crypto';
import request from 'supertest';
import { ACTIVITIES_STORE } from '../src/activities/activities.service';
import { ActivityCatalogSnapshot } from '../src/activities/activities.types';
import {
  APP_CONFIG_STORE,
  FALLBACK_APP_CONFIG,
} from '../src/app-config/app-config.service';
import { AppConfigSnapshot } from '../src/app-config/app-config.types';
import { configureNestApp } from '../src/app.factory';
import { AppModule } from '../src/app.module';
import { MemoryJsonDocumentStore } from '../src/common/storage/json-document.store';
import { verifyOfflineLicense } from '../src/licenses/licenses.crypto';
import { LICENSES_STORE } from '../src/licenses/licenses.service';
import { LicensesRegistrySnapshot } from '../src/licenses/licenses.types';
import { QuestionCatalogLoader } from '../src/question-catalog/question-catalog.loader';
import { QUESTION_CATALOG_STORE } from '../src/question-catalog/question-catalog.service';
import { MemoryCatalogStore } from '../src/question-catalog/question-catalog.store';

describe('Wefaq Full Backend System (Auth, Activities, AppConfig, Licenses, Bulk)', () => {
  let app: INestApplication;
  const savedEnv = { ...process.env };

  beforeAll(async () => {
    process.env.ADMIN_USERNAME = 'wefaq-admin';
    process.env.ADMIN_PASSWORD = 'strong-admin-password-2026';
    process.env.ADMIN_API_TOKEN = 'legacy-bearer-token-2026';
    delete process.env.LICENSE_PRIVATE_SEED;

    const loader = new QuestionCatalogLoader();
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(QUESTION_CATALOG_STORE)
      .useValue(new MemoryCatalogStore(loader))
      .overrideProvider(ACTIVITIES_STORE)
      .useValue(
        new MemoryJsonDocumentStore<ActivityCatalogSnapshot>(() => ({
          schemaVersion: 1,
          revision: 1,
          publishedAt: '2026-11-16T00:00:00Z',
          activities: [
            {
              id: 'act_seed_1',
              type: 'scenario',
              topic: 'communication',
              title: 'نشاط مبدئي',
              situation: 'وصف موقف للنقاش الهادئ',
              prompts: ['كيف نبدأ الحوار؟'],
              options: [],
              isDevelopmentOnly: true,
            },
          ],
        })),
      )
      .overrideProvider(APP_CONFIG_STORE)
      .useValue(
        new MemoryJsonDocumentStore<AppConfigSnapshot>(() => ({
          ...FALLBACK_APP_CONFIG,
          contact: {
            ...FALLBACK_APP_CONFIG.contact,
            supportHours: '10ص - 10م',
            contactMessageTemplate: 'السلام عليكم',
          },
          branding: {
            badgeText: 'وفاق',
            heroTitle: 'حوار يقرّب الفهم',
            heroSubtitle: 'وصف',
            siteNotice: 'تواصل فقط',
          },
        })),
      )
      .overrideProvider(LICENSES_STORE)
      .useValue(
        new MemoryJsonDocumentStore<LicensesRegistrySnapshot>(() => ({
          schemaVersion: 1,
          revision: 1,
          updatedAt: '2026-11-16T00:00:00Z',
          licenses: [],
        })),
      )
      .compile();

    app = moduleFixture.createNestApplication();
    configureNestApp(app);
    await app.init();
  });

  afterAll(async () => {
    process.env = savedEnv;
    await app.close();
  });

  it('serves /activate fallback page with strict CSP and no external network', async () => {
    const res = await request(app.getHttpServer()).get('/activate').expect(200);
    const script = /<script>([\s\S]*?)<\/script>/.exec(res.text)?.[1];
    expect(script).toBeDefined();
    const hash = createHash('sha256').update(script!, 'utf8').digest('base64');
    expect(res.headers['content-security-policy']).toContain(`script-src 'sha256-${hash}'`);
    expect(res.headers['content-security-policy']).toContain("connect-src 'none'");
    expect(res.text).toContain('dir="rtl"');
  });

  it('signs in with HttpOnly session cookie, protects admin routes, and logs out cleanly', async () => {
    const server = app.getHttpServer();
    const initialSession = await request(server).get('/v1/auth/session').expect(200);
    expect(initialSession.body.authenticated).toBe(false);
    expect(initialSession.body.authRequired).toBe(true);

    // Unauthenticated mutations & license reads fail with 401
    await request(server).get('/v1/licenses').expect(401);
    await request(server)
      .post('/v1/activities')
      .send({
        type: 'scenario',
        topic: 'communication',
        title: 'اختبار',
        situation: 'وصف',
        prompts: ['سؤال'],
      })
      .expect(401);

    // Wrong password fails
    await request(server)
      .post('/v1/auth/login')
      .send({ username: 'wefaq-admin', password: 'wrong' })
      .expect(401);

    // Valid login sets HttpOnly cookie
    const loginRes = await request(server)
      .post('/v1/auth/login')
      .send({
        username: 'wefaq-admin',
        password: 'strong-admin-password-2026',
      })
      .expect(200);

    expect(loginRes.body.ok).toBe(true);
    const rawSetCookie = loginRes.headers['set-cookie'] as unknown as string[] | string;
    const setCookie = Array.isArray(rawSetCookie) ? rawSetCookie : [rawSetCookie];
    expect(setCookie[0]).toContain('wefaq_admin_session=');
    expect(setCookie[0]).toContain('HttpOnly');

    const cookieHeader = setCookie[0].split(';')[0];

    const sessionRes = await request(server)
      .get('/v1/auth/session')
      .set('Cookie', cookieHeader)
      .expect(200);
    expect(sessionRes.body.authenticated).toBe(true);
    expect(sessionRes.body.username).toBe('wefaq-admin');

    // Cookie allows bulk question creation
    const bulkRes = await request(server)
      .post('/v1/questions/bulk')
      .set('Cookie', cookieHeader)
      .send({
        questions: [
          {
            text: 'سؤال دفعة 1',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
          },
          {
            text: 'سؤال دفعة 2',
            topic: 'finances',
            depth: 'deeper',
            suitableModes: ['phone'],
          },
        ],
      })
      .expect(201);
    expect(bulkRes.body.createdCount).toBe(2);

    const createdIds = (bulkRes.body.questions as Array<{ id: string }>).map(
      (q) => q.id,
    );
    const bulkApproveRes = await request(server)
      .post('/v1/questions/bulk-action')
      .set('Cookie', cookieHeader)
      .send({ action: 'approve', ids: createdIds })
      .expect(200);
    expect(bulkApproveRes.body.affectedCount).toBe(2);

    const bulkDraftRes = await request(server)
      .post('/v1/questions/bulk-action')
      .set('Cookie', cookieHeader)
      .send({ action: 'draft', ids: createdIds })
      .expect(200);
    expect(bulkDraftRes.body.affectedCount).toBe(2);

    const bulkDeleteRes = await request(server)
      .post('/v1/questions/bulk-action')
      .set('Cookie', cookieHeader)
      .send({ action: 'delete', ids: createdIds })
      .expect(200);
    expect(bulkDeleteRes.body.affectedCount).toBe(2);

    // Logout invalidates cookie
    const logoutRes = await request(server)
      .post('/v1/auth/logout')
      .set('Cookie', cookieHeader)
      .expect(200);
    expect(logoutRes.headers['set-cookie'][0]).toContain('Max-Age=0');
  });

  it('supports activities CRUD + ETag caching and app-config management via cookie session', async () => {
    const server = app.getHttpServer();
    const loginRes = await request(server)
      .post('/v1/auth/login')
      .send({
        username: 'wefaq-admin',
        password: 'strong-admin-password-2026',
      })
      .expect(200);
    const rawSetCookie = loginRes.headers['set-cookie'] as unknown as string[] | string;
    const cookieHeader = (Array.isArray(rawSetCookie) ? rawSetCookie[0] : rawSetCookie).split(';')[0];

    // Create activity
    const created = await request(server)
      .post('/v1/activities')
      .set('Cookie', cookieHeader)
      .send({
        type: 'priorityOrdering',
        topic: 'finances',
        title: 'ترتيب أولويات اختبارية',
        situation: 'اختر الأولويات المناسبة',
        options: ['الأولى', 'الثانية', 'الثالثة'],
        prompts: ['لماذا اخترت هذا الترتيب؟'],
        isDevelopmentOnly: false,
      })
      .expect(201);
    const createdId = created.body.activity.id as string;
    expect(created.body.activity.isDevelopmentOnly).toBe(false);

    // Catalog snapshot supports ETag + 304
    const cat = await request(server).get('/v1/activity-catalog').expect(200);
    expect(cat.body.activities).toHaveLength(2);
    await request(server)
      .get('/v1/activity-catalog')
      .set('If-None-Match', cat.headers.etag)
      .expect(304);

    // Delete created activity
    await request(server)
      .delete(`/v1/activities/${createdId}`)
      .set('Cookie', cookieHeader)
      .expect(200);

    // App config + full Site CMS update (contact-only, no payment)
    const cfgRes = await request(server)
      .put('/v1/app-config')
      .set('Cookie', cookieHeader)
      .send({
        contact: {
          whatsappNumber: '+20 100-123-4567',
          email: 'hello@wefaq.app',
          telegramUrl: 'https://t.me/wefaq_support',
          phoneDisplay: '+20 100 123 4567',
          websiteUrl: 'https://wefaq-site.vercel.app',
        },
        announcement: {
          enabled: true,
          title: 'إشعار',
          message: 'مرحبًا بكم في النسخة المحدثة',
          style: 'success',
        },
      })
      .expect(200);
    expect(cfgRes.body.config.contact.whatsappNumber).toBe('201001234567');
    expect(cfgRes.body.config.contact.telegramUrl).toBe(
      'https://t.me/wefaq_support',
    );
    expect(cfgRes.body.config.announcement.enabled).toBe(true);

    const cmsRes = await request(server)
      .patch('/v1/app-config')
      .set('Cookie', cookieHeader)
      .send({
        branding: {
          heroTitle: 'عنوان محدث من لوحة التحكم',
        },
        site: {
          meta: {
            brandName: 'وفاق',
            footerText: 'تذييل محدث من لوحة التحكم',
          },
          sections: {
            showFaq: false,
          },
          faq: [
            {
              question: 'سؤال مخصص من الإدارة؟',
              answer: 'إجابة واضحة ومحدثة من لوحة الإدارة.',
            },
          ],
          sampleQuestions: {
            communication: [
              {
                question: 'سؤال نموذجي محدث للموقع؟',
                clarification: 'توضيح من لوحة الإدارة',
              },
            ],
          },
        },
      })
      .expect(200);

    expect(cmsRes.body.config.branding.heroTitle).toBe(
      'عنوان محدث من لوحة التحكم',
    );
    expect(cmsRes.body.config.contact.whatsappNumber).toBe('201001234567');
    expect(cmsRes.body.config.site.meta.footerText).toBe(
      'تذييل محدث من لوحة التحكم',
    );
    expect(cmsRes.body.config.site.sections.showFaq).toBe(false);
    expect(cmsRes.body.config.site.faq).toHaveLength(1);
    expect(cmsRes.body.config.site.sampleQuestions.communication).toHaveLength(1);

    await request(server)
      .patch('/v1/app-config')
      .set('Cookie', cookieHeader)
      .send({
        contact: {
          telegramUrl: 'http://insecure.example/chat',
        },
      })
      .expect(400);

    const publicCfg = await request(server).get('/v1/app-config').expect(200);
    expect(publicCfg.body.announcement.message).toBe(
      'مرحبًا بكم في النسخة المحدثة',
    );
    expect(publicCfg.body.site.meta.footerText).toBe(
      'تذييل محدث من لوحة التحكم',
    );
  });

  it('generates Ed25519 keypairs, signs compatible activation codes, and tracks/revokes registry records', async () => {
    const server = app.getHttpServer();
    const loginRes = await request(server)
      .post('/v1/auth/login')
      .send({
        username: 'wefaq-admin',
        password: 'strong-admin-password-2026',
      })
      .expect(200);
    const rawSetCookie = loginRes.headers['set-cookie'] as unknown as string[] | string;
    const cookieHeader = (Array.isArray(rawSetCookie) ? rawSetCookie[0] : rawSetCookie).split(';')[0];

    const keygenRes = await request(server)
      .post('/v1/licenses/keygen')
      .set('Cookie', cookieHeader)
      .expect(200);
    const { privateSeedBase64Url, publicKeyBase64Url } = keygenRes.body as {
      privateSeedBase64Url: string;
      publicKeyBase64Url: string;
    };

    const dev1 = 'inst_12345678-1234-4234-8234-123456789abc';
    const dev2 = 'inst_87654321-1234-4234-8234-123456789abc';
    const genRes = await request(server)
      .post('/v1/licenses/generate')
      .set('Cookie', cookieHeader)
      .send({
        label: 'ترخيص تجربة',
        devices: [dev1, dev2],
        sessionLimit: 20,
        durationDays: 180,
        linkHost: 'wefaq.example',
        privateSeed: privateSeedBase64Url,
      })
      .expect(201);

    expect(genRes.body.publicKeyUsed).toBe(publicKeyBase64Url);
    expect(genRes.body.activationLink).toBe(
      `https://wefaq.example/activate#${genRes.body.code}`,
    );

    const verified = verifyOfflineLicense(genRes.body.code, publicKeyBase64Url);
    expect(verified.devices).toEqual([dev1, dev2]);
    expect(verified.sessionLimit).toBe(20);

    const listRes = await request(server)
      .get('/v1/licenses')
      .set('Cookie', cookieHeader)
      .expect(200);
    expect(listRes.body.items).toHaveLength(1);
    expect(listRes.body.items[0].status).toBe('active');

    await request(server)
      .patch(`/v1/licenses/${genRes.body.record.id}/revoke`)
      .set('Cookie', cookieHeader)
      .send({ reason: 'تم الاستبدال' })
      .expect(200);

    const listAfter = await request(server)
      .get('/v1/licenses?status=revoked')
      .set('Cookie', cookieHeader)
      .expect(200);
    expect(listAfter.body.items).toHaveLength(1);
    expect(listAfter.body.items[0].revokedReason).toBe('تم الاستبدال');
  });
});
