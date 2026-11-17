import { Topic } from '../question-catalog/question-catalog.types';

export const VALID_ACTIVITY_TYPES = ['scenario', 'priorityOrdering'] as const;
export type ActivityType = (typeof VALID_ACTIVITY_TYPES)[number];

export interface ActivityItem {
  readonly id: string;
  readonly type: ActivityType;
  readonly topic: Topic;
  readonly title: string;
  readonly situation: string;
  readonly prompts: readonly string[];
  readonly options: readonly string[];
  readonly isDevelopmentOnly: boolean;
}

export interface ActivityCatalogSnapshot {
  readonly schemaVersion: 1;
  readonly revision: number;
  readonly publishedAt: string;
  readonly activities: readonly ActivityItem[];
}
