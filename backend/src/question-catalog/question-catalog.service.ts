import {
  Inject,
  ConflictException,
  Injectable,
  Logger,
  OnModuleInit,
  Optional,
  ServiceUnavailableException,
} from '@nestjs/common';
import { BlobPreconditionFailedError } from '@vercel/blob';
import { QuestionCatalogLoader } from './question-catalog.loader';
import {
  CatalogStore,
  CatalogStoreStatus,
  createDefaultCatalogStore,
} from './question-catalog.store';
import {
  PreparedCatalogSnapshot,
  QuestionItem,
} from './question-catalog.types';
import {
  ValidateCatalogOptions,
  validateCatalogSnapshot,
} from './question-catalog.validator';

export interface QuestionCatalogConfig {
  readonly filterDevelopmentOnly?: boolean;
  readonly requireApprovedOnly?: boolean;
  readonly catalogFilePath?: string;
}

export const QUESTION_CATALOG_CONFIG = Symbol('QUESTION_CATALOG_CONFIG');
export const QUESTION_CATALOG_STORE = Symbol('QUESTION_CATALOG_STORE');

@Injectable()
export class QuestionCatalogService implements OnModuleInit {
  private readonly logger = new Logger(QuestionCatalogService.name);
  private readonly store: CatalogStore;
  private currentCatalog: PreparedCatalogSnapshot | null = null;
  private currentVersionTag: string | undefined;
  private initializationError: Error | null = null;
  private pendingSync: Promise<void> | null = null;
  private mutationTail: Promise<unknown> = Promise.resolve();

  constructor(
    @Inject(QuestionCatalogLoader)
    private readonly loader: QuestionCatalogLoader,
    @Optional()
    @Inject(QUESTION_CATALOG_CONFIG)
    private readonly config: QuestionCatalogConfig = {},
    @Optional()
    @Inject(QUESTION_CATALOG_STORE)
    store?: CatalogStore,
  ) {
    this.store =
      store ?? createDefaultCatalogStore(loader, config.catalogFilePath);
  }

  async onModuleInit(): Promise<void> {
    await this.ensureSynced();
  }

  getStorageStatus(): CatalogStoreStatus {
    return this.store.getStatus();
  }

  /**
   * Returns the latest validated catalog snapshot, refreshing from the
   * configured store when external changes (e.g. Blob updates) exist.
   */
  async getCatalog(): Promise<PreparedCatalogSnapshot> {
    await this.ensureSynced();
    if (!this.currentCatalog) {
      throw new ServiceUnavailableException(
        this.initializationError?.message ??
          'Question catalog is currently unavailable.',
      );
    }
    return this.currentCatalog;
  }

  /**
   * Validates and atomically replaces the in-memory snapshot only when
   * contract invariants (schema, uniqueness, monotonic revision) hold.
   */
  publishSnapshot(rawSnapshot: unknown): PreparedCatalogSnapshot {
    const options = this.buildValidationOptions();
    const prepared = validateCatalogSnapshot(rawSnapshot, options);
    this.currentCatalog = prepared;
    this.initializationError = null;
    return prepared;
  }

  /**
   * Serializes catalog mutations, checks latest store state, validates the
   * resulting snapshot with an incremented revision, and persists atomically.
   */
  mutateQuestions<T>(
    mutator: (current: PreparedCatalogSnapshot) => {
      readonly questions: QuestionItem[];
      readonly result: T;
    },
  ): Promise<{ readonly prepared: PreparedCatalogSnapshot; readonly result: T }> {
    const task = this.mutationTail.then(async () => {
      const current = await this.getCatalog();
      const { questions, result } = mutator(current);
      const nextRaw = {
        schemaVersion: 1,
        revision: current.snapshot.revision + 1,
        publishedAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        questions,
      };
      const prepared = validateCatalogSnapshot(
        nextRaw,
        this.buildValidationOptions(),
      );
      const prettyJson = `${JSON.stringify(prepared.snapshot, null, 2)}\n`;
      let saved: { versionTag?: string };
      try {
        saved = await this.store.saveSnapshot(prepared.snapshot, prettyJson, this.currentVersionTag);
      } catch (error) {
        if (error instanceof BlobPreconditionFailedError) {
          this.currentVersionTag = undefined;
          throw new ConflictException('Catalog changed; reload and retry.');
        }
        throw error;
      }
      this.currentCatalog = prepared;
      this.currentVersionTag = saved.versionTag ?? this.currentVersionTag;
      this.initializationError = null;
      return { prepared, result };
    });

    this.mutationTail = task.catch(() => undefined);
    return task;
  }

  private async ensureSynced(): Promise<void> {
    if (!this.pendingSync) {
      this.pendingSync = this.syncFromStore().finally(() => {
        this.pendingSync = null;
      });
    }
    await this.pendingSync;
  }

  private async syncFromStore(): Promise<void> {
    try {
      const loaded = await this.store.loadLatest(this.currentVersionTag);
      if (!loaded) {
        return;
      }
      const prepared = this.publishSnapshot(loaded.rawSnapshot);
      this.currentVersionTag = loaded.versionTag;
      this.logger.log(
        `Loaded catalog mode=${this.store.getStatus().mode} schemaVersion=${prepared.snapshot.schemaVersion} revision=${prepared.snapshot.revision} questions=${prepared.snapshot.questions.length} devOnlyPresent=${prepared.containsDevelopmentOnlyQuestions}`,
      );
    } catch (error) {
      const err =
        error instanceof Error ? error : new Error(String(error));
      if (!this.currentCatalog) {
        this.initializationError = err;
      }
      this.logger.error(`Failed to sync catalog from store: ${err.message}`);
    }
  }

  private buildValidationOptions(): ValidateCatalogOptions {
    const requireApprovedOnly =
      this.config.requireApprovedOnly ??
      parseBooleanEnv(process.env.CATALOG_REQUIRE_APPROVED_ONLY);
    const filterDevelopmentOnly =
      this.config.filterDevelopmentOnly ??
      parseBooleanEnv(process.env.CATALOG_FILTER_DEVELOPMENT_ONLY);

    return {
      requireApprovedOnly,
      filterDevelopmentOnly,
      previous: this.currentCatalog
        ? {
            revision: this.currentCatalog.snapshot.revision,
            sha256: this.currentCatalog.sha256,
          }
        : undefined,
    };
  }
}

function parseBooleanEnv(value: string | undefined): boolean {
  return value?.trim().toLowerCase() === 'true';
}
