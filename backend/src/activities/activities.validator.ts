import { BadRequestException, ConflictException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { Topic } from '../question-catalog/question-catalog.types';
import {
  CatalogValidationError,
  isPlainObject,
  parseTopic,
} from '../question-catalog/question-catalog.validator';
import {
  ActivityItem,
  ActivityType,
  VALID_ACTIVITY_TYPES,
} from './activities.types';

const SAFE_ID_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9_-]{1,79}$/;
const VALID_ACTIVITY_TYPE_SET: ReadonlySet<string> = new Set(
  VALID_ACTIVITY_TYPES,
);

export interface ListActivitiesQuery {
  readonly type?: ActivityType;
  readonly topic?: Topic;
  readonly isDevelopmentOnly?: boolean;
  readonly search?: string;
}

export function parseListActivitiesQuery(
  rawQuery: Record<string, unknown>,
): ListActivitiesQuery {
  try {
    const typeRaw = readOptionalString(rawQuery.type);
    const type = typeRaw ? parseActivityType(typeRaw, 'query') : undefined;

    const topicRaw = readOptionalString(rawQuery.topic);
    const topic = topicRaw ? parseTopic(topicRaw, 'query') : undefined;

    const devRaw = readOptionalString(rawQuery.isDevelopmentOnly);
    let isDevelopmentOnly: boolean | undefined;
    if (devRaw !== undefined) {
      if (devRaw === 'true') isDevelopmentOnly = true;
      else if (devRaw === 'false') isDevelopmentOnly = false;
      else {
        throw new BadRequestException(
          'Query parameter "isDevelopmentOnly" must be "true" or "false".',
        );
      }
    }

    const search =
      readOptionalString(rawQuery.search) ?? readOptionalString(rawQuery.q);

    return {
      type,
      topic,
      isDevelopmentOnly,
      search: search?.toLowerCase(),
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

export function parseCreateActivityInput(
  raw: unknown,
  existingIds: ReadonlySet<string>,
): ActivityItem {
  if (!isPlainObject(raw)) {
    throw new BadRequestException('Request body must be a JSON object.');
  }

  try {
    const type = parseActivityType(raw.type, 'new');
    const topic = parseTopic(raw.topic, 'new');

    let id: string;
    if (typeof raw.id === 'string' && raw.id.trim().length > 0) {
      id = raw.id.trim();
      if (!SAFE_ID_PATTERN.test(id)) {
        throw new BadRequestException(
          'Field "id" must be 2-80 characters using letters, numbers, "-" or "_".',
        );
      }
      if (existingIds.has(id)) {
        throw new ConflictException(`Activity id "${id}" already exists.`);
      }
    } else if (raw.id !== undefined && raw.id !== null && raw.id !== '') {
      throw new BadRequestException('Field "id" must be a non-empty string.');
    } else {
      id = generateUniqueActivityId(type, topic, existingIds);
    }

    const title = parseNonEmptyText(raw.title, 'title', 200);
    const situation = parseNonEmptyText(raw.situation, 'situation', 2000);
    const prompts = parseStringArray(raw.prompts, 'prompts', 0, 12);
    const options = parseStringArray(
      raw.options,
      'options',
      type === 'priorityOrdering' ? 2 : 0,
      12,
    );

    if (prompts.length === 0 && options.length === 0) {
      throw new BadRequestException(
        'Activity must include at least one discussion prompt or option.',
      );
    }

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
      type,
      topic,
      title,
      situation,
      prompts,
      options,
      isDevelopmentOnly,
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

export function parseUpdateActivityInput(
  raw: unknown,
  existing: ActivityItem,
): ActivityItem {
  if (!isPlainObject(raw)) {
    throw new BadRequestException('Request body must be a JSON object.');
  }

  if (raw.id !== undefined && raw.id !== existing.id) {
    throw new BadRequestException(
      'Activity "id" is immutable and cannot be changed.',
    );
  }

  const editableKeys = [
    'type',
    'topic',
    'title',
    'situation',
    'prompts',
    'options',
    'isDevelopmentOnly',
  ];
  if (!editableKeys.some((key) => raw[key] !== undefined)) {
    throw new BadRequestException(
      'At least one editable field must be provided.',
    );
  }

  try {
    const type =
      raw.type !== undefined
        ? parseActivityType(raw.type, existing.id)
        : existing.type;
    const topic =
      raw.topic !== undefined
        ? parseTopic(raw.topic, existing.id)
        : existing.topic;
    const title =
      raw.title !== undefined
        ? parseNonEmptyText(raw.title, 'title', 200)
        : existing.title;
    const situation =
      raw.situation !== undefined
        ? parseNonEmptyText(raw.situation, 'situation', 2000)
        : existing.situation;
    const prompts =
      raw.prompts !== undefined
        ? parseStringArray(raw.prompts, 'prompts', 0, 12)
        : [...existing.prompts];
    const options =
      raw.options !== undefined
        ? parseStringArray(
            raw.options,
            'options',
            type === 'priorityOrdering' ? 2 : 0,
            12,
          )
        : [...existing.options];

    if (type === 'priorityOrdering' && options.length < 2) {
      throw new BadRequestException(
        'Priority ordering activities require at least 2 options.',
      );
    }

    const contentChanged =
      type !== existing.type ||
      topic !== existing.topic ||
      title !== existing.title ||
      situation !== existing.situation ||
      JSON.stringify(prompts) !== JSON.stringify(existing.prompts) ||
      JSON.stringify(options) !== JSON.stringify(existing.options);

    let isDevelopmentOnly: boolean;
    if (raw.isDevelopmentOnly !== undefined) {
      if (typeof raw.isDevelopmentOnly !== 'boolean') {
        throw new BadRequestException(
          'Field "isDevelopmentOnly" must be a boolean.',
        );
      }
      isDevelopmentOnly = raw.isDevelopmentOnly;
    } else if (contentChanged) {
      isDevelopmentOnly = true;
    } else {
      isDevelopmentOnly = existing.isDevelopmentOnly;
    }

    return {
      id: existing.id,
      type,
      topic,
      title,
      situation,
      prompts,
      options,
      isDevelopmentOnly,
    };
  } catch (error) {
    if (error instanceof CatalogValidationError) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }
}

function parseActivityType(raw: unknown, id: string): ActivityType {
  if (typeof raw !== 'string' || !VALID_ACTIVITY_TYPE_SET.has(raw)) {
    throw new CatalogValidationError(
      `Activity "${id}" has invalid type "${String(raw)}".`,
    );
  }
  return raw as ActivityType;
}

function parseNonEmptyText(
  raw: unknown,
  field: string,
  maxLength: number,
): string {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    throw new BadRequestException(`Field "${field}" must be a non-empty string.`);
  }
  const trimmed = raw.trim();
  if (trimmed.length > maxLength) {
    throw new BadRequestException(
      `Field "${field}" must not exceed ${maxLength} characters.`,
    );
  }
  return trimmed;
}

function parseStringArray(
  raw: unknown,
  field: string,
  minItems: number,
  maxItems: number,
): string[] {
  if (raw === undefined || raw === null) {
    if (minItems > 0) {
      throw new BadRequestException(
        `Field "${field}" must include at least ${minItems} items.`,
      );
    }
    return [];
  }
  if (!Array.isArray(raw)) {
    throw new BadRequestException(`Field "${field}" must be an array.`);
  }
  const cleaned = raw
    .map((item) => (typeof item === 'string' ? item.trim() : ''))
    .filter((item) => item.length > 0);
  if (cleaned.length < minItems) {
    throw new BadRequestException(
      `Field "${field}" must include at least ${minItems} non-empty items.`,
    );
  }
  if (cleaned.length > maxItems) {
    throw new BadRequestException(
      `Field "${field}" must not exceed ${maxItems} items.`,
    );
  }
  return cleaned;
}

function generateUniqueActivityId(
  type: ActivityType,
  topic: Topic,
  existingIds: ReadonlySet<string>,
): string {
  const typePrefix = type === 'scenario' ? 'scen' : 'prio';
  const topicPrefix = topic.toLowerCase().slice(0, 4);
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const candidate = `act_${typePrefix}_${topicPrefix}_${randomBytes(2).toString('hex')}`;
    if (!existingIds.has(candidate)) {
      return candidate;
    }
  }
  return `act_${typePrefix}_${Date.now()}`;
}

function readOptionalString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
