import {
  CatalogValidationError,
  isValidRfc3339Utc,
  validateCatalogSnapshot,
} from './question-catalog.validator';

function makeValidCatalog(overrides: Record<string, unknown> = {}) {
  return {
    schemaVersion: 1,
    revision: 42,
    publishedAt: '2026-11-15T12:00:00Z',
    questions: [
      {
        id: 'comm-intro-1',
        text: 'إيه اللي بيساعدك تتكلم براحة عن يومك؟',
        clarification: 'الهدف معرفة أسلوب الاستماع والتواصل المفضل.',
        topic: 'communication',
        depth: 'introductory',
        suitableModes: ['together', 'phone'],
        isDevelopmentOnly: false,
      },
    ],
    ...overrides,
  };
}

describe('isValidRfc3339Utc', () => {
  it('accepts valid RFC 3339 UTC timestamps', () => {
    expect(isValidRfc3339Utc('2026-11-15T12:00:00Z')).toBe(true);
    expect(isValidRfc3339Utc('2026-11-15T12:00:00.123Z')).toBe(true);
  });

  it('rejects non-UTC offsets or impossible calendar dates', () => {
    expect(isValidRfc3339Utc('2026-11-15T12:00:00+02:00')).toBe(false);
    expect(isValidRfc3339Utc('2026-02-30T12:00:00Z')).toBe(false);
    expect(isValidRfc3339Utc('not-a-timestamp')).toBe(false);
  });
});

describe('validateCatalogSnapshot', () => {
  it('validates and prepares a contract-compliant snapshot with ETag', () => {
    const prepared = validateCatalogSnapshot(makeValidCatalog());

    expect(prepared.snapshot.schemaVersion).toBe(1);
    expect(prepared.snapshot.revision).toBe(42);
    expect(prepared.snapshot.publishedAt).toBe('2026-11-15T12:00:00Z');
    expect(prepared.snapshot.questions).toHaveLength(1);
    expect(prepared.etag).toMatch(/^"v1-r42-[0-9a-f]{16}"$/);
    expect(prepared.containsDevelopmentOnlyQuestions).toBe(false);
    expect(prepared.payloadBuffer.toString('utf8')).toContain(
      'إيه اللي بيساعدك تتكلم براحة عن يومك؟',
    );
  });

  it('omits optional clarification when omitted or blank', () => {
    const prepared = validateCatalogSnapshot(
      makeValidCatalog({
        questions: [
          {
            id: 'comm-intro-1',
            text: 'سؤال بدون توضيح',
            clarification: '   ',
            topic: 'communication',
            depth: 'introductory',
            suitableModes: ['together'],
            isDevelopmentOnly: true,
          },
        ],
      }),
    );

    expect(prepared.snapshot.questions[0]).not.toHaveProperty('clarification');
    expect(prepared.containsDevelopmentOnlyQuestions).toBe(true);
  });

  it('rejects unsupported schemaVersion, non-positive revisions, and empty questions', () => {
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ schemaVersion: 2 })),
    ).toThrow(CatalogValidationError);
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ revision: 0 })),
    ).toThrow(CatalogValidationError);
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ revision: -3 })),
    ).toThrow(CatalogValidationError);
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ questions: [] })),
    ).toThrow(CatalogValidationError);
  });

  it('rejects duplicate question IDs, invalid enums, and missing isDevelopmentOnly', () => {
    const baseItem = makeValidCatalog().questions[0] as Record<string, unknown>;

    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({ questions: [baseItem, { ...baseItem }] }),
      ),
    ).toThrow(/Duplicate question id/);

    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({
          questions: [{ ...baseItem, topic: 'unknownTopic' }],
        }),
      ),
    ).toThrow(/invalid topic/);

    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({
          questions: [{ ...baseItem, depth: 'expert' }],
        }),
      ),
    ).toThrow(/invalid depth/);

    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({
          questions: [{ ...baseItem, suitableModes: [] }],
        }),
      ),
    ).toThrow(/suitableModes/);

    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({
          questions: [{ ...baseItem, suitableModes: ['together', 'together'] }],
        }),
      ),
    ).toThrow(/duplicate suitableMode/);

    const withoutDevFlag = { ...baseItem };
    delete withoutDevFlag.isDevelopmentOnly;
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ questions: [withoutDevFlag] })),
    ).toThrow(/isDevelopmentOnly/);
  });

  it('enforces approved-only policy when requireApprovedOnly is enabled', () => {
    const devItem = {
      ...(makeValidCatalog().questions[0] as Record<string, unknown>),
      id: 'dev-1',
      isDevelopmentOnly: true,
    };
    const approvedItem = {
      ...(makeValidCatalog().questions[0] as Record<string, unknown>),
      id: 'approved-1',
      isDevelopmentOnly: false,
    };

    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ questions: [devItem] }), {
        requireApprovedOnly: true,
      }),
    ).toThrow(/isDevelopmentOnly=true/);

    const filtered = validateCatalogSnapshot(
      makeValidCatalog({ questions: [devItem, approvedItem] }),
      {
        filterDevelopmentOnly: true,
        requireApprovedOnly: true,
      },
    );
    expect(filtered.snapshot.questions.map((q) => q.id)).toEqual([
      'approved-1',
    ]);
    expect(filtered.containsDevelopmentOnlyQuestions).toBe(false);

    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ questions: [devItem] }), {
        filterDevelopmentOnly: true,
        requireApprovedOnly: true,
      }),
    ).toThrow(/at least one expert-approved question/);
  });

  it('enforces monotonic revision and prevents serving different content under the same revision', () => {
    const first = validateCatalogSnapshot(makeValidCatalog({ revision: 10 }));

    // Idempotent reload of identical content and revision succeeds
    const identical = validateCatalogSnapshot(
      makeValidCatalog({ revision: 10 }),
      { previous: { revision: first.snapshot.revision, sha256: first.sha256 } },
    );
    expect(identical.etag).toBe(first.etag);

    // Lower revision is rejected
    expect(() =>
      validateCatalogSnapshot(makeValidCatalog({ revision: 9 }), {
        previous: { revision: first.snapshot.revision, sha256: first.sha256 },
      }),
    ).toThrow(/Non-increasing catalog revision/);

    // Different content with same revision is rejected
    const modifiedItem = {
      ...(makeValidCatalog().questions[0] as Record<string, unknown>),
      text: 'نص مختلف بنفس رقم المراجعة',
    };
    expect(() =>
      validateCatalogSnapshot(
        makeValidCatalog({ revision: 10, questions: [modifiedItem] }),
        { previous: { revision: first.snapshot.revision, sha256: first.sha256 } },
      ),
    ).toThrow(/without incrementing revision/);

    // Higher revision with new content succeeds with a distinct ETag
    const upgraded = validateCatalogSnapshot(
      makeValidCatalog({ revision: 11, questions: [modifiedItem] }),
      { previous: { revision: first.snapshot.revision, sha256: first.sha256 } },
    );
    expect(upgraded.snapshot.revision).toBe(11);
    expect(upgraded.etag).not.toBe(first.etag);
  });
});
