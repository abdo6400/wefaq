import { createHash } from 'node:crypto';
import {
  Depth,
  PreparedCatalogSnapshot,
  QuestionCatalogSnapshot,
  QuestionItem,
  SuitableMode,
  Topic,
  VALID_DEPTHS,
  VALID_SUITABLE_MODES,
  VALID_TOPICS,
} from './question-catalog.types';

const VALID_TOPIC_SET: ReadonlySet<string> = new Set(VALID_TOPICS);
const VALID_DEPTH_SET: ReadonlySet<string> = new Set(VALID_DEPTHS);
const VALID_MODE_SET: ReadonlySet<string> = new Set(VALID_SUITABLE_MODES);

const RFC3339_UTC_PATTERN =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,9})?Z$/;

export class CatalogValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CatalogValidationError';
  }
}

export interface ValidateCatalogOptions {
  /**
   * When true, filters out questions where isDevelopmentOnly is true before
   * validating the non-empty catalog requirement.
   */
  readonly filterDevelopmentOnly?: boolean;
  /**
   * When true, rejects any catalog that still contains development-only
   * questions or ends up with zero approved questions.
   */
  readonly requireApprovedOnly?: boolean;
  /**
   * Previous published snapshot metadata used to enforce monotonic revisions
   * and prevent serving mutated content under an existing revision.
   */
  readonly previous?: {
    readonly revision: number;
    readonly sha256: string;
  };
}

/**
 * Validates raw parsed JSON against docs/questions-api-contract.md and returns
 * a canonical, pre-serialized snapshot with SHA-256 and opaque HTTP ETag.
 */
export function validateCatalogSnapshot(
  raw: unknown,
  options: ValidateCatalogOptions = {},
): PreparedCatalogSnapshot {
  if (!isPlainObject(raw)) {
    throw new CatalogValidationError(
      'Catalog snapshot root payload must be a JSON object.',
    );
  }

  const schemaVersion = raw.schemaVersion;
  if (schemaVersion !== 1) {
    throw new CatalogValidationError(
      `Unsupported catalog schemaVersion "${String(schemaVersion)}"; expected 1.`,
    );
  }

  const revision = raw.revision;
  if (
    typeof revision !== 'number' ||
    !Number.isInteger(revision) ||
    revision < 1
  ) {
    throw new CatalogValidationError(
      `Invalid catalog revision "${String(revision)}"; expected a positive integer.`,
    );
  }

  const publishedAt = raw.publishedAt;
  if (typeof publishedAt !== 'string' || !isValidRfc3339Utc(publishedAt)) {
    throw new CatalogValidationError(
      `Invalid catalog publishedAt "${String(publishedAt)}"; expected an RFC 3339 UTC timestamp.`,
    );
  }

  if (!Array.isArray(raw.questions) || raw.questions.length === 0) {
    throw new CatalogValidationError(
      'Catalog questions must be a non-empty array.',
    );
  }

  const seenIds = new Set<string>();
  const validatedQuestions: QuestionItem[] = [];

  for (let index = 0; index < raw.questions.length; index += 1) {
    const item = validateQuestionItem(raw.questions[index], index, seenIds);
    seenIds.add(item.id);
    validatedQuestions.push(item);
  }

  const effectiveQuestions = options.filterDevelopmentOnly
    ? validatedQuestions.filter((q) => !q.isDevelopmentOnly)
    : validatedQuestions;

  if (options.requireApprovedOnly) {
    const unapproved = effectiveQuestions.find((q) => q.isDevelopmentOnly);
    if (unapproved) {
      throw new CatalogValidationError(
        `Question "${unapproved.id}" is marked isDevelopmentOnly=true and cannot be served in approved-only mode.`,
      );
    }
    if (effectiveQuestions.length === 0) {
      throw new CatalogValidationError(
        'Approved-only catalog mode requires at least one expert-approved question.',
      );
    }
  }

  if (effectiveQuestions.length === 0) {
    throw new CatalogValidationError(
      'Catalog snapshot must contain at least one question.',
    );
  }

  const snapshot: QuestionCatalogSnapshot = {
    schemaVersion: 1,
    revision,
    publishedAt,
    questions: effectiveQuestions,
  };

  const serializedJson = JSON.stringify(snapshot);
  const payloadBuffer = Buffer.from(serializedJson, 'utf8');
  const sha256 = createHash('sha256').update(payloadBuffer).digest('hex');
  const etag = `"v${snapshot.schemaVersion}-r${snapshot.revision}-${sha256.slice(0, 16)}"`;

  if (options.previous) {
    if (snapshot.revision < options.previous.revision) {
      throw new CatalogValidationError(
        `Non-increasing catalog revision: received ${snapshot.revision}, current is ${options.previous.revision}.`,
      );
    }
    if (
      snapshot.revision === options.previous.revision &&
      sha256 !== options.previous.sha256
    ) {
      throw new CatalogValidationError(
        `Catalog content changed without incrementing revision ${snapshot.revision}.`,
      );
    }
  }

  return {
    snapshot,
    serializedJson,
    payloadBuffer,
    sha256,
    etag,
    containsDevelopmentOnlyQuestions: effectiveQuestions.some(
      (q) => q.isDevelopmentOnly,
    ),
  };
}

export function validateQuestionItem(
  raw: unknown,
  index: number,
  seenIds: ReadonlySet<string>,
): QuestionItem {
  if (!isPlainObject(raw)) {
    throw new CatalogValidationError(
      `Question at index ${index} must be a JSON object.`,
    );
  }

  const id = raw.id;
  if (typeof id !== 'string' || id.trim().length === 0) {
    throw new CatalogValidationError(
      `Question at index ${index} must have a non-empty string id.`,
    );
  }
  if (seenIds.has(id)) {
    throw new CatalogValidationError(`Duplicate question id "${id}".`);
  }

  const text = raw.text;
  if (typeof text !== 'string' || text.trim().length === 0) {
    throw new CatalogValidationError(
      `Question "${id}" must have a non-empty string text.`,
    );
  }

  const clarification = parseOptionalClarification(raw.clarification, id);
  const topic = parseTopic(raw.topic, id);
  const depth = parseDepth(raw.depth, id);
  const suitableModes = parseSuitableModes(raw.suitableModes, id);

  const isDevelopmentOnly = raw.isDevelopmentOnly;
  if (typeof isDevelopmentOnly !== 'boolean') {
    throw new CatalogValidationError(
      `Question "${id}" must include required boolean isDevelopmentOnly.`,
    );
  }

  return {
    id,
    text,
    ...(clarification !== undefined ? { clarification } : {}),
    topic,
    depth,
    suitableModes,
    isDevelopmentOnly,
  };
}

export function parseOptionalClarification(
  rawClarification: unknown,
  questionId: string,
): string | undefined {
  if (rawClarification === undefined || rawClarification === null) {
    return undefined;
  }
  if (typeof rawClarification !== 'string') {
    throw new CatalogValidationError(
      `Question "${questionId}" has non-string clarification.`,
    );
  }
  const trimmed = rawClarification.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function parseTopic(topic: unknown, questionId: string): Topic {
  if (typeof topic !== 'string' || !VALID_TOPIC_SET.has(topic)) {
    throw new CatalogValidationError(
      `Question "${questionId}" has invalid topic "${String(topic)}".`,
    );
  }
  return topic as Topic;
}

export function parseDepth(depth: unknown, questionId: string): Depth {
  if (typeof depth !== 'string' || !VALID_DEPTH_SET.has(depth)) {
    throw new CatalogValidationError(
      `Question "${questionId}" has invalid depth "${String(depth)}".`,
    );
  }
  return depth as Depth;
}

export function parseSuitableModes(
  rawModes: unknown,
  questionId: string,
): SuitableMode[] {
  if (!Array.isArray(rawModes) || rawModes.length === 0) {
    throw new CatalogValidationError(
      `Question "${questionId}" must include a non-empty suitableModes array.`,
    );
  }

  const seenModes = new Set<SuitableMode>();
  const suitableModes: SuitableMode[] = [];
  for (const mode of rawModes) {
    if (typeof mode !== 'string' || !VALID_MODE_SET.has(mode)) {
      throw new CatalogValidationError(
        `Question "${questionId}" has invalid suitableMode "${String(mode)}".`,
      );
    }
    const typedMode = mode as SuitableMode;
    if (seenModes.has(typedMode)) {
      throw new CatalogValidationError(
        `Question "${questionId}" has duplicate suitableMode "${typedMode}".`,
      );
    }
    seenModes.add(typedMode);
    suitableModes.push(typedMode);
  }
  return suitableModes;
}

export function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function isValidRfc3339Utc(value: string): boolean {
  const match = RFC3339_UTC_PATTERN.exec(value);
  if (!match) {
    return false;
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const hour = Number(match[4]);
  const minute = Number(match[5]);
  const second = Number(match[6]);

  if (
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > 31 ||
    hour > 23 ||
    minute > 59 ||
    second > 59
  ) {
    return false;
  }

  const date = new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day &&
    date.getUTCHours() === hour &&
    date.getUTCMinutes() === minute &&
    date.getUTCSeconds() === second
  );
}
