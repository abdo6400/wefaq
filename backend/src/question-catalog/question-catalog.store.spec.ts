import { BlobError, BlobPreconditionFailedError, put } from '@vercel/blob';
import { BlobJsonDocumentStore } from '../common/storage/json-document.store';
import { QuestionCatalogLoader } from './question-catalog.loader';
import { BlobCatalogStore } from './question-catalog.store';
import { QuestionCatalogSnapshot } from './question-catalog.types';

jest.mock('@vercel/blob', () => {
  const actual = jest.requireActual<typeof import('@vercel/blob')>('@vercel/blob');
  return { ...actual, put: jest.fn() };
});

describe('BlobCatalogStore conditional writes', () => {
  const putMock = jest.mocked(put);
  const loader = new QuestionCatalogLoader();
  const snapshot = loader.loadRawSnapshot() as QuestionCatalogSnapshot;
  beforeEach(() => putMock.mockReset());

  it('uses create-only semantics for the initial snapshot', async () => {
    putMock.mockResolvedValue({ etag: 'new-tag' } as Awaited<ReturnType<typeof put>>);
    const store = new BlobCatalogStore(loader);
    await store.saveSnapshot(snapshot, '{}', 'seed');
    expect(putMock).toHaveBeenCalledWith(expect.any(String), '{}', expect.objectContaining({ allowOverwrite: false }));
  });

  it('requires the observed etag and surfaces a conflicting write', async () => {
    putMock.mockRejectedValue(new BlobPreconditionFailedError());
    const store = new BlobCatalogStore(loader);
    await expect(store.saveSnapshot(snapshot, '{}', 'old-tag')).rejects.toBeInstanceOf(BlobPreconditionFailedError);
    expect(putMock).toHaveBeenCalledTimes(1);
    expect(putMock).toHaveBeenCalledWith(expect.any(String), '{}', expect.objectContaining({ ifMatch: 'old-tag' }));
  });

  it('falls back to private access when Vercel Blob throws BlobError for a private store', async () => {
    const privateStoreError = new BlobError(
      'Vercel Blob: Cannot use public access on a private store. The store is configured with private access.',
    );
    putMock
      .mockRejectedValueOnce(privateStoreError)
      .mockResolvedValue({ etag: 'priv-tag-1' } as Awaited<ReturnType<typeof put>>);

    const docStore = new BlobJsonDocumentStore<{ ok: boolean }>({
      filename: 'licenses-registry.v1.json',
      blobPathname: 'wefaq/licenses-registry.v1.json',
      seedFactory: () => ({ ok: true }),
    });

    const saved = await docStore.save({ ok: true }, 'seed');
    expect(saved.versionTag).toBe('priv-tag-1');
    expect(putMock).toHaveBeenNthCalledWith(
      1,
      'wefaq/licenses-registry.v1.json',
      expect.any(String),
      expect.objectContaining({ access: 'public', allowOverwrite: false }),
    );
    expect(putMock).toHaveBeenNthCalledWith(
      2,
      'wefaq/licenses-registry.v1.json',
      expect.any(String),
      expect.objectContaining({ access: 'private', allowOverwrite: false }),
    );

    // Subsequent saves remember private access directly without a failed retry
    await docStore.save({ ok: false }, 'priv-tag-1');
    expect(putMock).toHaveBeenNthCalledWith(
      3,
      'wefaq/licenses-registry.v1.json',
      expect.any(String),
      expect.objectContaining({ access: 'private', ifMatch: 'priv-tag-1' }),
    );
  });
});
