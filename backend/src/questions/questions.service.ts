import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { isAdminAuthConfigured } from '../common/guards/admin-token.guard';
import { QuestionCatalogService } from '../question-catalog/question-catalog.service';
import { isPlainObject } from '../question-catalog/question-catalog.validator';
import {
  PreparedCatalogSnapshot,
  QuestionItem,
  VALID_DEPTHS,
  VALID_TOPICS,
} from '../question-catalog/question-catalog.types';
import {
  ListQuestionsQuery,
  parseCreateQuestionInput,
  parseListQuestionsQuery,
  parseUpdateQuestionInput,
} from './questions.validator';

export interface CatalogSummaryDto {
  readonly schemaVersion: 1;
  readonly revision: number;
  readonly publishedAt: string;
  readonly etag: string;
  readonly questionCount: number;
  readonly containsDevelopmentOnlyQuestions: boolean;
}

@Injectable()
export class QuestionsService {
  constructor(
    @Inject(QuestionCatalogService)
    private readonly catalogService: QuestionCatalogService,
  ) {}

  async getMeta() {
    const storage = this.catalogService.getStorageStatus();
    const authRequired = isAdminAuthConfigured();
    try {
      const prepared = await this.catalogService.getCatalog();
      return {
        storageMode: storage.mode,
        persistent: storage.persistent,
        authRequired,
        catalog: toCatalogSummary(prepared),
        counts: computeCounts(prepared.snapshot.questions),
      };
    } catch {
      return {
        storageMode: storage.mode,
        persistent: storage.persistent,
        authRequired,
        catalog: null,
        counts: null,
      };
    }
  }

  async listQuestions(query: ListQuestionsQuery) {
    const prepared = await this.catalogService.getCatalog();
    const all = prepared.snapshot.questions;
    const filtered = all.filter((q) => matchesQuery(q, query));

    const totalPages = Math.max(1, Math.ceil(filtered.length / query.limit));
    const safePage = Math.min(query.page, totalPages);
    const offset = (safePage - 1) * query.limit;
    const items = filtered.slice(offset, offset + query.limit);

    return {
      schemaVersion: prepared.snapshot.schemaVersion,
      revision: prepared.snapshot.revision,
      publishedAt: prepared.snapshot.publishedAt,
      etag: prepared.etag,
      total: all.length,
      filteredTotal: filtered.length,
      page: safePage,
      limit: query.limit,
      totalPages,
      counts: computeCounts(all),
      items,
    };
  }

  async getQuestionById(id: string): Promise<QuestionItem> {
    const prepared = await this.catalogService.getCatalog();
    const found = prepared.snapshot.questions.find((q) => q.id === id);
    if (!found) {
      throw new NotFoundException(`Question "${id}" was not found.`);
    }
    return found;
  }

  async createQuestion(rawBody: unknown) {
    const { prepared, result } = await this.catalogService.mutateQuestions(
      (current) => {
        const existingIds = new Set(
          current.snapshot.questions.map((item) => item.id),
        );
        const created = parseCreateQuestionInput(rawBody, existingIds);
        return {
          questions: [...current.snapshot.questions, created],
          result: created,
        };
      },
    );

    return {
      question: result,
      catalog: toCatalogSummary(prepared),
    };
  }

  async bulkCreateQuestions(rawBody: unknown) {
    if (
      !rawBody ||
      typeof rawBody !== 'object' ||
      Array.isArray(rawBody) ||
      !Array.isArray((rawBody as { questions?: unknown }).questions)
    ) {
      throw new BadRequestException(
        'Request body must contain a non-empty "questions" array.',
      );
    }

    const rawItems = (rawBody as { questions: unknown[] }).questions;
    if (rawItems.length === 0 || rawItems.length > 200) {
      throw new BadRequestException(
        'Bulk import supports between 1 and 200 questions per request.',
      );
    }

    const { prepared, result } = await this.catalogService.mutateQuestions(
      (current) => {
        const existingIds = new Set(
          current.snapshot.questions.map((item) => item.id),
        );
        const added: QuestionItem[] = [];
        for (const item of rawItems) {
          const parsed = parseCreateQuestionInput(item, existingIds);
          existingIds.add(parsed.id);
          added.push(parsed);
        }
        return {
          questions: [...current.snapshot.questions, ...added],
          result: added,
        };
      },
    );

    return {
      createdCount: result.length,
      questions: result,
      catalog: toCatalogSummary(prepared),
    };
  }

  async bulkActionQuestions(rawBody: unknown) {
    if (!isPlainObject(rawBody)) {
      throw new BadRequestException('Request body must be a JSON object.');
    }

    const action = rawBody.action;
    if (action !== 'approve' && action !== 'draft' && action !== 'delete') {
      throw new BadRequestException(
        'Field "action" must be "approve", "draft", or "delete".',
      );
    }

    let idSet: Set<string> | null = null;
    if (rawBody.ids !== undefined) {
      if (!Array.isArray(rawBody.ids)) {
        throw new BadRequestException('Field "ids" must be an array.');
      }
      const cleaned = rawBody.ids
        .filter((v): v is string => typeof v === 'string')
        .map((v) => v.trim())
        .filter((v) => v.length > 0);
      if (cleaned.length === 0 || cleaned.length > 1000) {
        throw new BadRequestException(
          'Field "ids" must contain between 1 and 1000 question IDs.',
        );
      }
      idSet = new Set(cleaned);
    }

    let filterQuery: ListQuestionsQuery | null = null;
    if (idSet === null) {
      if (!isPlainObject(rawBody.filter)) {
        throw new BadRequestException(
          'Provide either "ids" or a "filter" object for bulk action.',
        );
      }
      if (action === 'delete') {
        throw new BadRequestException(
          'Bulk delete requires explicit "ids" selection.',
        );
      }
      filterQuery = parseListQuestionsQuery(rawBody.filter);
    }

    const { prepared, result } = await this.catalogService.mutateQuestions(
      (current) => {
        const matchesTarget = (q: QuestionItem): boolean => {
          if (idSet !== null) return idSet.has(q.id);
          return filterQuery ? matchesQuery(q, filterQuery) : false;
        };

        let affectedCount = 0;
        if (action === 'delete') {
          const remaining = current.snapshot.questions.filter((q) => {
            if (matchesTarget(q)) {
              affectedCount += 1;
              return false;
            }
            return true;
          });
          if (remaining.length < 1) {
            throw new BadRequestException(
              'Cannot delete all remaining questions in the catalog.',
            );
          }
          if (affectedCount === 0) {
            throw new NotFoundException('No matching questions found.');
          }
          return { questions: remaining, result: affectedCount };
        }

        const nextDevFlag = action === 'draft';
        const updated = current.snapshot.questions.map((q) => {
          if (!matchesTarget(q)) return q;
          if (q.isDevelopmentOnly !== nextDevFlag) {
            affectedCount += 1;
            return { ...q, isDevelopmentOnly: nextDevFlag };
          }
          return q;
        });

        return { questions: updated, result: affectedCount };
      },
    );

    return {
      action,
      affectedCount: result,
      catalog: toCatalogSummary(prepared),
    };
  }

  async updateQuestion(id: string, rawBody: unknown) {
    const { prepared, result } = await this.catalogService.mutateQuestions(
      (current) => {
        const index = current.snapshot.questions.findIndex(
          (item) => item.id === id,
        );
        if (index === -1) {
          throw new NotFoundException(`Question "${id}" was not found.`);
        }
        const existing = current.snapshot.questions[index];
        const updated = parseUpdateQuestionInput(rawBody, existing);
        const nextQuestions = [...current.snapshot.questions];
        nextQuestions[index] = updated;
        return {
          questions: nextQuestions,
          result: updated,
        };
      },
    );

    return {
      question: result,
      catalog: toCatalogSummary(prepared),
    };
  }

  async deleteQuestion(id: string) {
    const { prepared } = await this.catalogService.mutateQuestions(
      (current) => {
        const index = current.snapshot.questions.findIndex(
          (item) => item.id === id,
        );
        if (index === -1) {
          throw new NotFoundException(`Question "${id}" was not found.`);
        }
        if (current.snapshot.questions.length <= 1) {
          throw new BadRequestException(
            'Cannot delete the last remaining question in the catalog.',
          );
        }
        return {
          questions: current.snapshot.questions.filter(
            (item) => item.id !== id,
          ),
          result: id,
        };
      },
    );

    return {
      deletedId: id,
      catalog: toCatalogSummary(prepared),
    };
  }

  async exportCatalog(format: string | undefined) {
    const prepared = await this.catalogService.getCatalog();
    if (format === 'asset') {
      return {
        filename: 'questions_v1.json',
        payload: {
          version: prepared.snapshot.schemaVersion,
          generatedAt: prepared.snapshot.publishedAt,
          note: prepared.containsDevelopmentOnlyQuestions
            ? 'Includes development-only questions. Review before production release.'
            : 'Reviewed Wefaq question bank.',
          questions: prepared.snapshot.questions,
        },
      };
    }

    return {
      filename: `question-catalog.v1.r${prepared.snapshot.revision}.json`,
      payload: prepared.snapshot,
    };
  }
}

function matchesQuery(q: QuestionItem, query: ListQuestionsQuery): boolean {
  if (query.topic && q.topic !== query.topic) {
    return false;
  }
  if (query.depth && q.depth !== query.depth) {
    return false;
  }
  if (query.mode && !q.suitableModes.includes(query.mode)) {
    return false;
  }
  if (
    query.isDevelopmentOnly !== undefined &&
    q.isDevelopmentOnly !== query.isDevelopmentOnly
  ) {
    return false;
  }
  if (query.search) {
    const haystack = `${q.id}\n${q.text}\n${q.clarification ?? ''}`.toLowerCase();
    if (!haystack.includes(query.search)) {
      return false;
    }
  }
  return true;
}

function computeCounts(questions: readonly QuestionItem[]) {
  const byTopic: Record<string, number> = {};
  for (const topic of VALID_TOPICS) {
    byTopic[topic] = 0;
  }

  const byDepth: Record<string, number> = {};
  for (const depth of VALID_DEPTHS) {
    byDepth[depth] = 0;
  }

  let developmentOnly = 0;
  let approved = 0;

  for (const q of questions) {
    byTopic[q.topic] = (byTopic[q.topic] ?? 0) + 1;
    byDepth[q.depth] = (byDepth[q.depth] ?? 0) + 1;
    if (q.isDevelopmentOnly) {
      developmentOnly += 1;
    } else {
      approved += 1;
    }
  }

  return {
    total: questions.length,
    byTopic,
    byDepth,
    developmentOnly,
    approved,
  };
}

function toCatalogSummary(prepared: PreparedCatalogSnapshot): CatalogSummaryDto {
  return {
    schemaVersion: prepared.snapshot.schemaVersion,
    revision: prepared.snapshot.revision,
    publishedAt: prepared.snapshot.publishedAt,
    etag: prepared.etag,
    questionCount: prepared.snapshot.questions.length,
    containsDevelopmentOnlyQuestions: prepared.containsDevelopmentOnlyQuestions,
  };
}
