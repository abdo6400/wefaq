import { BadRequestException, ConflictException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import {
  Depth,
  QuestionItem,
  SuitableMode,
  Topic,
} from '../question-catalog/question-catalog.types';
import {
  CatalogValidationError,
  isPlainObject,
  parseDepth,
  parseOptionalClarification,
  parseSuitableModes,
  parseTopic,
} from '../question-catalog/question-catalog.validator';

const SAFE_ID_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9_-]{1,79}$/;

export interface ListQuestionsQuery {
  readonly topic?: Topic;
  readonly depth?: Depth;
  readonly mode?: SuitableMode;
  readonly isDevelopmentOnly?: boolean;
  readonly search?: string;
  readonly page: number;
  readonly limit: number;
}

export function parseListQuestionsQuery(
  rawQuery: Record<string, unknown>,
): ListQuestionsQuery {
  try {
    const topicRaw = readOptionalQueryString(rawQuery.topic);
    const topic = topicRaw ? parseTopic(topicRaw, 'query') : undefined;

    const depthRaw = readOptionalQueryString(rawQuery.depth);
    const depth = depthRaw ? parseDepth(depthRaw, 'query') : undefined;

    const modeRaw = readOptionalQueryString(rawQuery.mode);
    const mode = modeRaw
      ? parseSuitableModes([modeRaw], 'query')[0]
      : undefined;

    const devRaw = readOptionalQueryString(rawQuery.isDevelopmentOnly);
    let isDevelopmentOnly: boolean | undefined;
    if (devRaw !== undefined) {
      if (devRaw === 'true') {
        isDevelopmentOnly = true;
      } else if (devRaw === 'false') {
        isDevelopmentOnly = false;
      } else {
        throw new BadRequestException(
          'Query parameter "isDevelopmentOnly" must be "true" or "false".',
        );
      }
    }

    const search =
      readOptionalQueryString(rawQuery.search) ??
      readOptionalQueryString(rawQuery.q);

    const page = parseBoundedInt(rawQuery.page, 'page', 1, 10000, 1);
    const limit = parseBoundedInt(rawQuery.limit, 'limit', 1, 600, 50);

    return {
      topic,
      depth,
      mode,
      isDevelopmentOnly,
      search: search?.toLowerCase(),
      page,
      limit,
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

export function parseCreateQuestionInput(
  raw: unknown,
  existingIds: ReadonlySet<string>,
): QuestionItem {
  if (!isPlainObject(raw)) {
    throw new BadRequestException('Request body must be a JSON object.');
  }

  try {
    const rawTopic = parseTopic(raw.topic, 'new');
    const rawDepth = parseDepth(raw.depth, 'new');
    const suitableModes = parseSuitableModes(raw.suitableModes, 'new');

    let id: string;
    if (typeof raw.id === 'string' && raw.id.trim().length > 0) {
      id = raw.id.trim();
      if (!SAFE_ID_PATTERN.test(id)) {
        throw new BadRequestException(
          'Field "id" must be 2-80 characters using letters, numbers, "-" or "_".',
        );
      }
      if (existingIds.has(id)) {
        throw new ConflictException(`Question id "${id}" already exists.`);
      }
    } else if (raw.id !== undefined && raw.id !== null && raw.id !== '') {
      throw new BadRequestException('Field "id" must be a non-empty string.');
    } else {
      id = generateUniqueQuestionId(rawTopic, rawDepth, existingIds);
    }

    if (typeof raw.text !== 'string' || raw.text.trim().length === 0) {
      throw new BadRequestException('Field "text" must be a non-empty string.');
    }
    const text = raw.text.trim();

    const clarification = parseOptionalClarification(raw.clarification, id);

    let isDevelopmentOnly = true;
    if (raw.isDevelopmentOnly !== undefined) {
      if (typeof raw.isDevelopmentOnly !== 'boolean') {
        throw new BadRequestException(
          'Field "isDevelopmentOnly" must be a boolean.',
        );
      }
      isDevelopmentOnly = raw.isDevelopmentOnly;
    }

    return {
      id,
      text,
      ...(clarification !== undefined ? { clarification } : {}),
      topic: rawTopic,
      depth: rawDepth,
      suitableModes,
      isDevelopmentOnly,
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

export function parseUpdateQuestionInput(
  raw: unknown,
  existing: QuestionItem,
): QuestionItem {
  if (!isPlainObject(raw)) {
    throw new BadRequestException('Request body must be a JSON object.');
  }

  if (raw.id !== undefined && raw.id !== existing.id) {
    throw new BadRequestException(
      'Question "id" is immutable and cannot be changed.',
    );
  }

  const editableKeys = [
    'text',
    'clarification',
    'topic',
    'depth',
    'suitableModes',
    'isDevelopmentOnly',
  ];
  const hasAnyEditable = editableKeys.some((key) => raw[key] !== undefined);
  if (!hasAnyEditable) {
    throw new BadRequestException(
      'At least one editable field (text, clarification, topic, depth, suitableModes, isDevelopmentOnly) must be provided.',
    );
  }

  try {
    let text = existing.text;
    if (raw.text !== undefined) {
      if (typeof raw.text !== 'string' || raw.text.trim().length === 0) {
        throw new BadRequestException(
          'Field "text" must be a non-empty string.',
        );
      }
      text = raw.text.trim();
    }

    const clarification =
      'clarification' in raw
        ? parseOptionalClarification(raw.clarification, existing.id)
        : existing.clarification;

    const topic =
      raw.topic !== undefined
        ? parseTopic(raw.topic, existing.id)
        : existing.topic;

    const depth =
      raw.depth !== undefined
        ? parseDepth(raw.depth, existing.id)
        : existing.depth;

    const suitableModes =
      raw.suitableModes !== undefined
        ? parseSuitableModes(raw.suitableModes, existing.id)
        : [...existing.suitableModes];

    const contentChanged =
      text !== existing.text ||
      clarification !== existing.clarification ||
      topic !== existing.topic ||
      depth !== existing.depth ||
      JSON.stringify(suitableModes) !== JSON.stringify(existing.suitableModes);

    let isDevelopmentOnly: boolean;
    if (raw.isDevelopmentOnly !== undefined) {
      if (typeof raw.isDevelopmentOnly !== 'boolean') {
        throw new BadRequestException(
          'Field "isDevelopmentOnly" must be a boolean.',
        );
      }
      isDevelopmentOnly = raw.isDevelopmentOnly;
    } else if (contentChanged) {
      // Per docs/production-plan.md, editing content resets approval until reviewed.
      isDevelopmentOnly = true;
    } else {
      isDevelopmentOnly = existing.isDevelopmentOnly;
    }

    return {
      id: existing.id,
      text,
      ...(clarification !== undefined ? { clarification } : {}),
      topic,
      depth,
      suitableModes,
      isDevelopmentOnly,
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

function generateUniqueQuestionId(
  topic: Topic,
  depth: Depth,
  existingIds: ReadonlySet<string>,
): string {
  const topicCode = topic.toLowerCase().slice(0, 5);
  const depthCode = depth === 'introductory' ? 'intro' : 'deep';
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const candidate = `custom-${topicCode}-${depthCode}-${randomBytes(3).toString('hex')}`;
    if (!existingIds.has(candidate)) {
      return candidate;
    }
  }
  return `custom-${Date.now()}-${randomBytes(4).toString('hex')}`;
}

function readOptionalQueryString(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function parseBoundedInt(
  raw: unknown,
  field: string,
  min: number,
  max: number,
  fallback: number,
): number {
  if (raw === undefined || raw === null || raw === '') {
    return fallback;
  }
  const str = typeof raw === 'string' ? raw.trim() : String(raw);
  if (!/^\d+$/.test(str)) {
    throw new BadRequestException(
      `Query parameter "${field}" must be an integer between ${min} and ${max}.`,
    );
  }
  const parsed = Number.parseInt(str, 10);
  if (parsed < min || parsed > max) {
    throw new BadRequestException(
      `Query parameter "${field}" must be between ${min} and ${max}.`,
    );
  }
  return parsed;
}
