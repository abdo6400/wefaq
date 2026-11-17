import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendDir = path.resolve(__dirname, '..');
const sourcePath = path.resolve(backendDir, '..', 'assets', 'content', 'questions_v1.json');
const targetPath = path.resolve(backendDir, 'data', 'question-catalog.v1.json');

const VALID_TOPICS = new Set([
  'communication',
  'dailyLife',
  'familyRelations',
  'finances',
  'coreValues',
]);
const VALID_DEPTHS = new Set(['introductory', 'deeper']);
const VALID_MODES = new Set(['together', 'phone']);

const checkOnly = process.argv.includes('--check');

function normalizeQuestion(raw, index) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new Error(`Question at index ${index} must be an object`);
  }
  if (typeof raw.id !== 'string' || raw.id.trim().length === 0) {
    throw new Error(`Question at index ${index} has invalid id`);
  }
  if (typeof raw.text !== 'string' || raw.text.trim().length === 0) {
    throw new Error(`Question "${raw.id}" has empty text`);
  }
  if (!VALID_TOPICS.has(raw.topic)) {
    throw new Error(`Question "${raw.id}" has invalid topic "${raw.topic}"`);
  }
  if (!VALID_DEPTHS.has(raw.depth)) {
    throw new Error(`Question "${raw.id}" has invalid depth "${raw.depth}"`);
  }
  if (!Array.isArray(raw.suitableModes) || raw.suitableModes.length === 0) {
    throw new Error(`Question "${raw.id}" must have nonempty suitableModes`);
  }
  const seenModes = new Set();
  for (const mode of raw.suitableModes) {
    if (!VALID_MODES.has(mode) || seenModes.has(mode)) {
      throw new Error(`Question "${raw.id}" has invalid or duplicate mode "${mode}"`);
    }
    seenModes.add(mode);
  }
  if (typeof raw.isDevelopmentOnly !== 'boolean') {
    throw new Error(`Question "${raw.id}" must include boolean isDevelopmentOnly`);
  }
  if (
    raw.clarification !== undefined &&
    raw.clarification !== null &&
    typeof raw.clarification !== 'string'
  ) {
    throw new Error(`Question "${raw.id}" has non-string clarification`);
  }

  const normalized = {
    id: raw.id,
    text: raw.text,
  };
  if (typeof raw.clarification === 'string' && raw.clarification.trim().length > 0) {
    normalized.clarification = raw.clarification;
  }
  normalized.topic = raw.topic;
  normalized.depth = raw.depth;
  normalized.suitableModes = [...raw.suitableModes];
  normalized.isDevelopmentOnly = raw.isDevelopmentOnly;
  return normalized;
}

function main() {
  if (checkOnly) {
    if (!fs.existsSync(targetPath)) {
      throw new Error(`Catalog file not found: ${targetPath}`);
    }
    const existing = JSON.parse(fs.readFileSync(targetPath, 'utf8'));
    if (existing.schemaVersion !== 1 || !Number.isInteger(existing.revision) || existing.revision < 1) {
      throw new Error('Invalid schemaVersion or revision in target catalog');
    }
    if (!Array.isArray(existing.questions) || existing.questions.length === 0) {
      throw new Error('Target catalog questions must be nonempty');
    }
    const seenIds = new Set();
    existing.questions.forEach((item, index) => {
      const normalized = normalizeQuestion(item, index);
      if (seenIds.has(normalized.id)) {
        throw new Error(`Duplicate question id: ${normalized.id}`);
      }
      seenIds.add(normalized.id);
    });
    console.log(
      `Validated ${targetPath}: schemaVersion=${existing.schemaVersion}, revision=${existing.revision}, questions=${existing.questions.length}`,
    );
    return;
  }

  if (!fs.existsSync(sourcePath)) {
    throw new Error(`Source question bank not found: ${sourcePath}`);
  }

  const source = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
  if (source.version !== 1) {
    throw new Error(`Unsupported source version: ${source.version}`);
  }
  if (!Array.isArray(source.questions) || source.questions.length === 0) {
    throw new Error('Source questions must be nonempty');
  }

  const seenIds = new Set();
  const normalizedQuestions = source.questions.map((raw, index) => {
    const q = normalizeQuestion(raw, index);
    if (seenIds.has(q.id)) {
      throw new Error(`Duplicate question id in source: ${q.id}`);
    }
    seenIds.add(q.id);
    return q;
  });

  let revision = 1;
  let publishedAt =
    typeof source.generatedAt === 'string' && source.generatedAt.endsWith('Z')
      ? source.generatedAt
      : new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

  if (fs.existsSync(targetPath)) {
    const previous = JSON.parse(fs.readFileSync(targetPath, 'utf8'));
    const previousSerialized = JSON.stringify(previous.questions);
    const nextSerialized = JSON.stringify(normalizedQuestions);
    if (previousSerialized === nextSerialized) {
      revision = previous.revision;
      publishedAt = previous.publishedAt;
    } else {
      revision = (Number.isInteger(previous.revision) ? previous.revision : 0) + 1;
      publishedAt = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    }
  }

  const snapshot = {
    schemaVersion: 1,
    revision,
    publishedAt,
    questions: normalizedQuestions,
  };

  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  fs.writeFileSync(targetPath, `${JSON.stringify(snapshot, null, 2)}\n`, 'utf8');
  console.log(
    `Synced ${targetPath}: schemaVersion=1, revision=${revision}, publishedAt=${publishedAt}, questions=${normalizedQuestions.length}`,
  );
}

main();
