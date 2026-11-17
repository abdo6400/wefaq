import { ServiceUnavailableException } from '@nestjs/common';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { QuestionCatalogLoader } from './question-catalog.loader';
import { QuestionCatalogService } from './question-catalog.service';
import { CatalogStore, FileCatalogStore, MemoryCatalogStore } from './question-catalog.store';
import { BlobPreconditionFailedError } from '@vercel/blob';

describe('QuestionCatalogService', () => {
  it('rejects a competing serverless write rather than losing an edit', async () => {
    const loader = new QuestionCatalogLoader();
    let raw: unknown = loader.loadRawSnapshot();
    let tag = 'seed';
    let arrivals = 0;
    let release!: () => void;
    const barrier = new Promise<void>((resolve) => { release = resolve; });
    const store: CatalogStore = {
      getStatus: () => ({ mode: 'vercel-blob', persistent: true }),
      loadLatest: async (current) => current === tag ? null : { rawSnapshot: raw, versionTag: tag },
      saveSnapshot: async (snapshot, _json, expected) => {
        arrivals += 1;
        if (arrivals === 2) release();
        await barrier;
        if (expected !== tag) throw new BlobPreconditionFailedError();
        raw = snapshot;
        tag = 'new-tag';
        return { versionTag: tag };
      },
    };
    const a = new QuestionCatalogService(loader, {}, store);
    const b = new QuestionCatalogService(loader, {}, store);
    await Promise.all([a.getCatalog(), b.getCatalog()]);
    const mutate = (service: QuestionCatalogService, id: string) => service.mutateQuestions((current) => ({
      questions: [...current.snapshot.questions, { id, text: 'سؤال', topic: 'communication', depth: 'introductory', suitableModes: ['together'], isDevelopmentOnly: true }],
      result: id,
    }));
    const results = await Promise.allSettled([mutate(a, 'new-a'), mutate(b, 'new-b')]);
    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter((result) => result.status === 'rejected')).toHaveLength(1);
    expect((raw as { questions: unknown[] }).questions).toHaveLength(601);
  });
  it('loads the repository question-catalog.v1.json snapshot', async () => {
    const loader = new QuestionCatalogLoader();
    const service = new QuestionCatalogService(
      loader,
      {},
      new MemoryCatalogStore(loader),
    );
    const catalog = await service.getCatalog();

    expect(catalog.snapshot.schemaVersion).toBe(1);
    expect(catalog.snapshot.revision).toBeGreaterThanOrEqual(1);
    expect(catalog.snapshot.questions).toHaveLength(600);
    expect(catalog.containsDevelopmentOnlyQuestions).toBe(true);
    expect(catalog.etag).toMatch(/^"v1-r\d+-[0-9a-f]{16}"$/);
  });

  it('preserves the previous validated snapshot if a new publish attempt fails', async () => {
    const loader = new QuestionCatalogLoader();
    const service = new QuestionCatalogService(
      loader,
      {},
      new MemoryCatalogStore(loader),
    );
    const initial = await service.getCatalog();

    expect(() =>
      service.publishSnapshot({
        schemaVersion: 1,
        revision: initial.snapshot.revision,
        publishedAt: '2026-11-15T12:00:00Z',
        questions: [
          {
            id: 'mutated-without-revision-bump',
            text: 'سؤال معدل',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
            isDevelopmentOnly: true,
          },
        ],
      }),
    ).toThrow();

    const current = await service.getCatalog();
    expect(current.etag).toBe(initial.etag);
    expect(current.snapshot.questions).toHaveLength(600);
  });

  it('persists mutations atomically to FileCatalogStore with incremented revision', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'wefaq-catalog-test-'));
    try {
      const loader = new QuestionCatalogLoader();
      const tempFile = join(dir, 'catalog.json');
      writeFileSync(
        tempFile,
        JSON.stringify(loader.loadRawSnapshot(), null, 2),
        'utf8',
      );
      const store = new FileCatalogStore(loader, tempFile);
      const service = new QuestionCatalogService(loader, {}, store);

      const initial = await service.getCatalog();
      const { prepared } = await service.mutateQuestions((current) => ({
        questions: [
          ...current.snapshot.questions,
          {
            id: 'test-new-1',
            text: 'سؤال تجريبي جديد',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
            isDevelopmentOnly: true,
          },
        ],
        result: true,
      }));

      expect(prepared.snapshot.revision).toBe(initial.snapshot.revision + 1);
      expect(prepared.snapshot.questions).toHaveLength(601);

      const savedOnDisk = JSON.parse(readFileSync(tempFile, 'utf8')) as {
        revision: number;
        questions: unknown[];
      };
      expect(savedOnDisk.revision).toBe(initial.snapshot.revision + 1);
      expect(savedOnDisk.questions).toHaveLength(601);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it('fails closed with ServiceUnavailableException when strict approved-only mode has zero approved questions', async () => {
    const loader = new QuestionCatalogLoader();
    const service = new QuestionCatalogService(
      loader,
      { requireApprovedOnly: true },
      new MemoryCatalogStore(loader),
    );

    await expect(service.getCatalog()).rejects.toThrow(
      ServiceUnavailableException,
    );
  });
});
