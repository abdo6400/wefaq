import {
  Inject,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import {
  createJsonDocumentStore,
  JsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import {
  ActivityCatalogSnapshot,
  ActivityItem,
} from './activities.types';
import {
  ListActivitiesQuery,
  parseCreateActivityInput,
  parseUpdateActivityInput,
} from './activities.validator';

export const ACTIVITIES_STORE = Symbol('ACTIVITIES_STORE');

export const FALLBACK_ACTIVITIES_SEED: ActivityCatalogSnapshot = {
  schemaVersion: 1,
  revision: 1,
  publishedAt: '2026-11-16T00:00:00Z',
  activities: [
    {
      id: 'act_scen_comm_01',
      type: 'scenario',
      topic: 'communication',
      title: 'موقف للنقاش: زيارة عائلية مفاجئة',
      situation:
        'اتصل أحد أفراد العائلة لإعلامكم برغبته في الزيارة اليوم بعد ساعتين، بينما كان اليوم مخصصًا للراحة أو لارتباط خاص بينكما.',
      prompts: [
        'كيف يفضل كل منا التعامل مع التغييرات المفاجئة في المواعيد؟',
        'ما الطريقة المثالية للتنسيق والاتفاق بيننا قبل تأكيد أي موعد خارجي؟',
      ],
      options: [],
      isDevelopmentOnly: true,
    },
  ],
};

@Injectable()
export class ActivitiesService {
  private readonly store: JsonDocumentStore<ActivityCatalogSnapshot>;
  private cached: ActivityCatalogSnapshot | null = null;
  private versionTag: string | undefined;
  private mutationTail: Promise<unknown> = Promise.resolve();

  constructor(
    @Optional()
    @Inject(ACTIVITIES_STORE)
    store?: JsonDocumentStore<ActivityCatalogSnapshot>,
  ) {
    this.store =
      store ??
      createJsonDocumentStore<ActivityCatalogSnapshot>({
        filename: 'activities-catalog.v1.json',
        blobPathname: 'wefaq/activities-catalog.v1.json',
        envPathVar: 'ACTIVITIES_FILE_PATH',
        seedFactory: () =>
          loadSeedFileOrFallback(
            'activities-catalog.v1.json',
            () => FALLBACK_ACTIVITIES_SEED,
          ),
      });
  }

  async getSnapshot(): Promise<{
    readonly snapshot: ActivityCatalogSnapshot;
    readonly etag: string;
    readonly serializedJson: string;
  }> {
    const loaded = await this.store.loadLatest(this.versionTag);
    if (loaded) {
      this.cached = loaded.data;
      this.versionTag = loaded.versionTag;
    }
    const snapshot = this.cached ?? FALLBACK_ACTIVITIES_SEED;
    const serializedJson = JSON.stringify(snapshot);
    const hash = createHash('sha256')
      .update(serializedJson, 'utf8')
      .digest('hex')
      .slice(0, 16);
    const etag = `"act-v${snapshot.schemaVersion}-r${snapshot.revision}-${hash}"`;
    return { snapshot, etag, serializedJson };
  }

  async listActivities(query: ListActivitiesQuery) {
    const { snapshot, etag } = await this.getSnapshot();
    const filtered = snapshot.activities.filter((item) => {
      if (query.type && item.type !== query.type) return false;
      if (query.topic && item.topic !== query.topic) return false;
      if (
        query.isDevelopmentOnly !== undefined &&
        item.isDevelopmentOnly !== query.isDevelopmentOnly
      ) {
        return false;
      }
      if (query.search) {
        const hay = `${item.id}\n${item.title}\n${item.situation}\n${item.prompts.join('\n')}\n${(item.options ?? []).join('\n')}`.toLowerCase();
        if (!hay.includes(query.search)) return false;
      }
      return true;
    });

    const counts = {
      total: snapshot.activities.length,
      scenarios: snapshot.activities.filter((a) => a.type === 'scenario').length,
      priorityOrdering: snapshot.activities.filter(
        (a) => a.type === 'priorityOrdering',
      ).length,
      approved: snapshot.activities.filter((a) => !a.isDevelopmentOnly).length,
      developmentOnly: snapshot.activities.filter((a) => a.isDevelopmentOnly)
        .length,
    };

    return {
      schemaVersion: snapshot.schemaVersion,
      revision: snapshot.revision,
      publishedAt: snapshot.publishedAt,
      etag,
      counts,
      total: filtered.length,
      items: filtered,
    };
  }

  async createActivity(rawBody: unknown) {
    return this.mutate((current) => {
      const existingIds = new Set(current.activities.map((a) => a.id));
      const created = parseCreateActivityInput(rawBody, existingIds);
      return {
        activities: [...current.activities, created],
        result: created,
      };
    });
  }

  async updateActivity(id: string, rawBody: unknown) {
    return this.mutate((current) => {
      const idx = current.activities.findIndex((a) => a.id === id);
      if (idx === -1) {
        throw new NotFoundException(`Activity "${id}" was not found.`);
      }
      const updated = parseUpdateActivityInput(rawBody, current.activities[idx]);
      const next = [...current.activities];
      next[idx] = updated;
      return {
        activities: next,
        result: updated,
      };
    });
  }

  async deleteActivity(id: string) {
    return this.mutate((current) => {
      const idx = current.activities.findIndex((a) => a.id === id);
      if (idx === -1) {
        throw new NotFoundException(`Activity "${id}" was not found.`);
      }
      return {
        activities: current.activities.filter((a) => a.id !== id),
        result: id,
      };
    });
  }

  private mutate<T>(
    mutator: (current: ActivityCatalogSnapshot) => {
      readonly activities: ActivityItem[];
      readonly result: T;
    },
  ): Promise<{ readonly snapshot: ActivityCatalogSnapshot; readonly result: T }> {
    const task = this.mutationTail.then(async () => {
      const { snapshot } = await this.getSnapshot();
      const { activities, result } = mutator(snapshot);
      const nextSnapshot: ActivityCatalogSnapshot = {
        schemaVersion: 1,
        revision: snapshot.revision + 1,
        publishedAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        activities,
      };
      const saved = await this.store.save(nextSnapshot, this.versionTag);
      this.cached = nextSnapshot;
      this.versionTag = saved.versionTag ?? this.versionTag;
      return { snapshot: nextSnapshot, result };
    });

    this.mutationTail = task.catch(() => undefined);
    return task;
  }
}
