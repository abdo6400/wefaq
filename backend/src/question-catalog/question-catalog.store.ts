import { existsSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { list } from '@vercel/blob';
import {
  BlobAccessMode,
  putBlobWithAccessFallback,
  readBlobTextWithAccess,
  resolveInitialBlobAccess,
} from '../common/storage/json-document.store';
import { QuestionCatalogLoader } from './question-catalog.loader';
import { QuestionCatalogSnapshot } from './question-catalog.types';

export type CatalogStorageMode = 'file' | 'vercel-blob' | 'memory-ephemeral';

export interface CatalogStoreStatus {
  readonly mode: CatalogStorageMode;
  readonly persistent: boolean;
}

export interface LoadedCatalogResult {
  readonly rawSnapshot: unknown;
  readonly versionTag?: string;
}

export interface CatalogStore {
  getStatus(): CatalogStoreStatus;
  loadLatest(currentVersionTag?: string): Promise<LoadedCatalogResult | null>;
  saveSnapshot(
    snapshot: QuestionCatalogSnapshot,
    prettyJson: string,
    expectedVersionTag?: string,
  ): Promise<{ versionTag?: string }>;
}

/**
 * In-memory store seeded from bundled JSON, used on read-only serverless
 * deployments when no external persistent store (such as Vercel Blob) is configured.
 */
export class MemoryCatalogStore implements CatalogStore {
  private currentRaw: unknown | null = null;
  private currentTag = 'seed';

  constructor(private readonly seedLoader: QuestionCatalogLoader) {}

  getStatus(): CatalogStoreStatus {
    return { mode: 'memory-ephemeral', persistent: false };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedCatalogResult | null> {
    if (this.currentRaw === null) {
      this.currentRaw = this.seedLoader.loadRawSnapshot();
      this.currentTag = 'seed';
    }
    if (currentVersionTag === this.currentTag) {
      return null;
    }
    return {
      rawSnapshot: this.currentRaw,
      versionTag: this.currentTag,
    };
  }

  async saveSnapshot(
    snapshot: QuestionCatalogSnapshot,
  ): Promise<{ versionTag?: string }> {
    this.currentRaw = snapshot;
    this.currentTag = `mem-r${snapshot.revision}-${Date.now()}`;
    return { versionTag: this.currentTag };
  }
}

/**
 * Local filesystem store using atomic write-then-rename persistence.
 */
export class FileCatalogStore implements CatalogStore {
  private readonly targetPath: string;

  constructor(
    private readonly loader: QuestionCatalogLoader,
    explicitPath?: string,
  ) {
    this.targetPath = loader.resolveCatalogPath(explicitPath);
  }

  getStatus(): CatalogStoreStatus {
    return { mode: 'file', persistent: true };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedCatalogResult | null> {
    const tag = this.computeFileTag();
    if (currentVersionTag && tag === currentVersionTag) {
      return null;
    }
    const raw = JSON.parse(readFileSync(this.targetPath, 'utf8')) as unknown;
    return {
      rawSnapshot: raw,
      versionTag: this.computeFileTag(),
    };
  }

  async saveSnapshot(
    _snapshot: QuestionCatalogSnapshot,
    prettyJson: string,
  ): Promise<{ versionTag?: string }> {
    const dir = dirname(this.targetPath);
    const tempPath = join(
      dir,
      `.question-catalog.${process.pid}.${Date.now()}.tmp`,
    );
    writeFileSync(tempPath, prettyJson, 'utf8');
    renameSync(tempPath, this.targetPath);
    return { versionTag: this.computeFileTag() };
  }

  private computeFileTag(): string {
    if (!existsSync(this.targetPath)) {
      return 'missing';
    }
    const stats = statSync(this.targetPath);
    return `${stats.mtimeMs}:${stats.size}`;
  }
}

/**
 * Persistent Vercel Blob store synchronized across serverless instances.
 * Automatically adapts to either public or private Vercel Blob stores.
 */
export class BlobCatalogStore implements CatalogStore {
  private preferredAccess: BlobAccessMode;

  constructor(
    private readonly seedLoader: QuestionCatalogLoader,
    private readonly pathname = process.env.CATALOG_BLOB_PATHNAME?.trim() ||
      'wefaq/question-catalog.v1.json',
  ) {
    this.preferredAccess = resolveInitialBlobAccess();
  }

  getStatus(): CatalogStoreStatus {
    return { mode: 'vercel-blob', persistent: true };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedCatalogResult | null> {
    const listing = await list({ prefix: this.pathname, limit: 10 });
    const entry = listing.blobs.find((item) => item.pathname === this.pathname);

    if (!entry) {
      if (currentVersionTag === 'seed') {
        return null;
      }
      return {
        rawSnapshot: this.seedLoader.loadRawSnapshot(),
        versionTag: 'seed',
      };
    }

    if (currentVersionTag && entry.etag === currentVersionTag) {
      return null;
    }

    const content = await this.readBlobText(entry.url);
    return {
      rawSnapshot: JSON.parse(content) as unknown,
      versionTag: entry.etag,
    };
  }

  async saveSnapshot(
    _snapshot: QuestionCatalogSnapshot,
    prettyJson: string,
    expectedVersionTag?: string,
  ): Promise<{ versionTag?: string }> {
    const saved = await putBlobWithAccessFallback({
      pathname: this.pathname,
      content: prettyJson,
      expectedVersionTag,
      preferredAccess: this.preferredAccess,
    });
    this.preferredAccess = saved.access;
    return { versionTag: saved.versionTag };
  }

  private async readBlobText(url: string): Promise<string> {
    const loaded = await readBlobTextWithAccess(
      url,
      this.preferredAccess,
      'catalog',
    );
    this.preferredAccess = loaded.access;
    return loaded.text;
  }
}

export function createDefaultCatalogStore(
  loader: QuestionCatalogLoader,
  explicitFilePath?: string,
): CatalogStore {
  if ((process.env.BLOB_READ_WRITE_TOKEN?.trim() ?? '').length > 0) {
    return new BlobCatalogStore(loader);
  }

  if (
    process.env.VERCEL === '1' ||
    (process.env.AWS_LAMBDA_FUNCTION_NAME?.trim() ?? '').length > 0
  ) {
    return new MemoryCatalogStore(loader);
  }

  return new FileCatalogStore(loader, explicitFilePath);
}
