export const VALID_TOPICS = [
  'communication',
  'dailyLife',
  'familyRelations',
  'finances',
  'coreValues',
] as const;

export type Topic = (typeof VALID_TOPICS)[number];

export const VALID_DEPTHS = ['introductory', 'deeper'] as const;

export type Depth = (typeof VALID_DEPTHS)[number];

export const VALID_SUITABLE_MODES = ['together', 'phone'] as const;

export type SuitableMode = (typeof VALID_SUITABLE_MODES)[number];

/**
 * Single discussion prompt conforming to docs/questions-api-contract.md.
 */
export interface QuestionItem {
  readonly id: string;
  readonly text: string;
  readonly clarification?: string;
  readonly topic: Topic;
  readonly depth: Depth;
  readonly suitableModes: readonly SuitableMode[];
  readonly isDevelopmentOnly: boolean;
}

/**
 * Complete catalog snapshot served by GET /v1/question-catalog.
 */
export interface QuestionCatalogSnapshot {
  readonly schemaVersion: 1;
  readonly revision: number;
  readonly publishedAt: string;
  readonly questions: readonly QuestionItem[];
}

/**
 * Validated, pre-serialized catalog snapshot and its opaque HTTP cache validators.
 */
export interface PreparedCatalogSnapshot {
  readonly snapshot: QuestionCatalogSnapshot;
  readonly serializedJson: string;
  readonly payloadBuffer: Buffer;
  readonly sha256: string;
  readonly etag: string;
  readonly containsDevelopmentOnlyQuestions: boolean;
}
