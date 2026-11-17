import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import {
  BlobAccessError,
  BlobError,
  BlobPreconditionFailedError,
  get,
  list,
  put,
} from '@vercel/blob';
import { ConflictException } from '@nestjs/common';

export type BlobAccessMode = 'public' | 'private';

/** Resolves the initial Vercel Blob access mode from environment configuration. */
export function resolveInitialBlobAccess(): BlobAccessMode {
  return process.env.BLOB_ACCESS?.trim().toLowerCase() === 'private'
    ? 'private'
    : 'public';
}

/**
 * Returns true when Vercel Blob rejected a request due to store access mode
 * mismatch (public vs private store, which may throw BlobError or BlobAccessError).
 */
export function isBlobAccessModeMismatchError(error: unknown): boolean {
  if (error instanceof BlobAccessError) {
    return true;
  }
  if (error instanceof BlobError || error instanceof Error) {
    return /cannot use (?:public|private) access|private store|public store/i.test(
      error.message,
    );
  }
  return false;
}

/**
 * Writes JSON to Vercel Blob with optimistic ETag preconditions and automatic
 * public/private access fallback so private Blob stores work out-of-the-box.
 */
export async function putBlobWithAccessFallback(params: {
  readonly pathname: string;
  readonly content: string;
  readonly expectedVersionTag?: string;
  readonly preferredAccess: BlobAccessMode;
}): Promise<{ readonly versionTag?: string; readonly access: BlobAccessMode }> {
  const baseOptions = {
    addRandomSuffix: false,
    ...(params.expectedVersionTag && params.expectedVersionTag !== 'seed'
      ? { ifMatch: params.expectedVersionTag }
      : { allowOverwrite: false }),
    contentType: 'application/json; charset=utf-8',
  } as const;

  try {
    const result = await put(params.pathname, params.content, {
      ...baseOptions,
      access: params.preferredAccess,
    });
    return { versionTag: result.etag, access: params.preferredAccess };
  } catch (error) {
    if (!isBlobAccessModeMismatchError(error)) {
      throw error;
    }
    const fallbackAccess: BlobAccessMode =
      params.preferredAccess === 'public' ? 'private' : 'public';
    const result = await put(params.pathname, params.content, {
      ...baseOptions,
      access: fallbackAccess,
    });
    return { versionTag: result.etag, access: fallbackAccess };
  }
}

/** Reads text from a Vercel Blob entry, falling back to private Blob SDK fetch when needed. */
export async function readBlobTextWithAccess(
  url: string,
  preferredAccess: BlobAccessMode,
  label = 'document',
): Promise<{ readonly text: string; readonly access: BlobAccessMode }> {
  if (preferredAccess === 'public') {
    const response = await fetch(url);
    if (response.ok) {
      return { text: await response.text(), access: 'public' };
    }
    if (response.status !== 401 && response.status !== 403) {
      throw new Error(
        `Failed to fetch blob ${label} (${response.status} ${response.statusText})`,
      );
    }
  }

  const blob = await get(url, { access: 'private' });
  if (!blob || blob.statusCode !== 200 || !blob.stream) {
    throw new Error(`Blob ${label} object was not found after listing.`);
  }
  return {
    text: await new Response(blob.stream).text(),
    access: 'private',
  };
}

export type DocumentStorageMode = 'file' | 'vercel-blob' | 'memory-ephemeral';

export interface DocumentStoreStatus {
  readonly mode: DocumentStorageMode;
  readonly persistent: boolean;
}

export interface LoadedDocument<T> {
  readonly data: T;
  readonly versionTag?: string;
}

export interface JsonDocumentStore<T> {
  getStatus(): DocumentStoreStatus;
  loadLatest(currentVersionTag?: string): Promise<LoadedDocument<T> | null>;
  save(
    data: T,
    expectedVersionTag?: string,
  ): Promise<{ readonly versionTag?: string }>;
}

export interface JsonDocumentStoreOptions<T> {
  readonly filename: string;
  readonly blobPathname: string;
  readonly envPathVar?: string;
  readonly seedFactory: () => T;
}

export class MemoryJsonDocumentStore<T> implements JsonDocumentStore<T> {
  private current: T | null = null;
  private versionTag = 'seed';

  constructor(private readonly seedFactory: () => T) {}

  getStatus(): DocumentStoreStatus {
    return { mode: 'memory-ephemeral', persistent: false };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedDocument<T> | null> {
    if (this.current === null) {
      this.current = structuredClone(this.seedFactory());
      this.versionTag = 'seed';
    }
    if (currentVersionTag === this.versionTag) {
      return null;
    }
    return {
      data: structuredClone(this.current),
      versionTag: this.versionTag,
    };
  }

  async save(data: T): Promise<{ readonly versionTag?: string }> {
    this.current = structuredClone(data);
    this.versionTag = `mem-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
    return { versionTag: this.versionTag };
  }
}

export class FileJsonDocumentStore<T> implements JsonDocumentStore<T> {
  private readonly targetPath: string;

  constructor(
    private readonly options: JsonDocumentStoreOptions<T>,
    explicitPath?: string,
  ) {
    this.targetPath = resolveDocumentPath(
      options.filename,
      explicitPath ??
        (options.envPathVar ? process.env[options.envPathVar] : undefined),
    );
  }

  getStatus(): DocumentStoreStatus {
    return { mode: 'file', persistent: true };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedDocument<T> | null> {
    if (!existsSync(this.targetPath)) {
      if (currentVersionTag === 'seed') {
        return null;
      }
      return {
        data: structuredClone(this.options.seedFactory()),
        versionTag: 'seed',
      };
    }

    const tag = this.computeFileTag();
    if (currentVersionTag && tag === currentVersionTag) {
      return null;
    }

    const raw = JSON.parse(readFileSync(this.targetPath, 'utf8')) as T;
    return {
      data: raw,
      versionTag: tag,
    };
  }

  async save(data: T): Promise<{ readonly versionTag?: string }> {
    const dir = dirname(this.targetPath);
    mkdirSync(dir, { recursive: true });
    const tempPath = join(
      dir,
      `.${this.options.filename}.${process.pid}.${Date.now()}.tmp`,
    );
    writeFileSync(tempPath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
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

export class BlobJsonDocumentStore<T> implements JsonDocumentStore<T> {
  private preferredAccess: BlobAccessMode;

  constructor(private readonly options: JsonDocumentStoreOptions<T>) {
    this.preferredAccess = resolveInitialBlobAccess();
  }

  getStatus(): DocumentStoreStatus {
    return { mode: 'vercel-blob', persistent: true };
  }

  async loadLatest(
    currentVersionTag?: string,
  ): Promise<LoadedDocument<T> | null> {
    const listing = await list({
      prefix: this.options.blobPathname,
      limit: 10,
    });
    const entry = listing.blobs.find(
      (item) => item.pathname === this.options.blobPathname,
    );

    if (!entry) {
      if (currentVersionTag === 'seed') {
        return null;
      }
      return {
        data: structuredClone(this.options.seedFactory()),
        versionTag: 'seed',
      };
    }

    if (currentVersionTag && entry.etag === currentVersionTag) {
      return null;
    }

    const loaded = await readBlobTextWithAccess(
      entry.url,
      this.preferredAccess,
      'document',
    );
    this.preferredAccess = loaded.access;
    return {
      data: JSON.parse(loaded.text) as T,
      versionTag: entry.etag,
    };
  }

  async save(
    data: T,
    expectedVersionTag?: string,
  ): Promise<{ readonly versionTag?: string }> {
    const prettyJson = `${JSON.stringify(data, null, 2)}\n`;
    try {
      const saved = await putBlobWithAccessFallback({
        pathname: this.options.blobPathname,
        content: prettyJson,
        expectedVersionTag,
        preferredAccess: this.preferredAccess,
      });
      this.preferredAccess = saved.access;
      return { versionTag: saved.versionTag };
    } catch (error) {
      if (error instanceof BlobPreconditionFailedError) {
        throw new ConflictException('Data changed remotely; reload and retry.');
      }
      throw error;
    }
  }
}

export function createJsonDocumentStore<T>(
  options: JsonDocumentStoreOptions<T>,
  explicitPath?: string,
): JsonDocumentStore<T> {
  if ((process.env.BLOB_READ_WRITE_TOKEN?.trim() ?? '').length > 0) {
    return new BlobJsonDocumentStore(options);
  }

  if (
    process.env.VERCEL === '1' ||
    (process.env.AWS_LAMBDA_FUNCTION_NAME?.trim() ?? '').length > 0
  ) {
    return new MemoryJsonDocumentStore(options.seedFactory);
  }

  if (process.env.NODE_ENV === 'test' || process.env.JEST_WORKER_ID) {
    const configured =
      explicitPath ??
      (options.envPathVar ? process.env[options.envPathVar] : undefined);
    if (!configured) {
      return new MemoryJsonDocumentStore(options.seedFactory);
    }
  }

  return new FileJsonDocumentStore(options, explicitPath);
}

export function loadSeedFileOrFallback<T>(
  filename: string,
  fallback: () => T,
): T {
  const candidates = [
    join(process.cwd(), 'data', filename),
    resolve(__dirname, '..', '..', '..', 'data', filename),
    resolve(__dirname, '..', '..', '..', '..', 'data', filename),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      try {
        return JSON.parse(readFileSync(candidate, 'utf8')) as T;
      } catch {
        // Fall through to in-code seed fallback.
      }
    }
  }

  return fallback();
}

function resolveDocumentPath(filename: string, explicitPath?: string): string {
  if (explicitPath && explicitPath.trim().length > 0) {
    return resolve(explicitPath.trim());
  }

  const candidates = [
    join(process.cwd(), 'data', filename),
    resolve(__dirname, '..', '..', '..', 'data', filename),
    resolve(__dirname, '..', '..', '..', '..', 'data', filename),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }

  return join(process.cwd(), 'data', filename);
}
