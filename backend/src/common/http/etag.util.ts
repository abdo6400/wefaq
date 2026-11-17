/**
 * Parses an HTTP If-None-Match header value (comma-separated entity-tags or "*")
 * and performs RFC 9110 weak comparison against the current ETag.
 *
 * Weak comparison strips any leading "W/" prefix so proxy/CDN compression
 * transformations of the same opaque tag still resolve cleanly to 304.
 */
export function matchesIfNoneMatch(
  ifNoneMatchHeader: string | string[] | undefined,
  currentEtag: string,
): boolean {
  if (!ifNoneMatchHeader) {
    return false;
  }

  const rawHeader = Array.isArray(ifNoneMatchHeader)
    ? ifNoneMatchHeader.join(',')
    : ifNoneMatchHeader;

  const trimmedHeader = rawHeader.trim();
  if (trimmedHeader.length === 0) {
    return false;
  }

  const currentNormalized = normalizeWeakTag(currentEtag);
  if (!currentNormalized) {
    return false;
  }

  for (const token of splitEntityTags(trimmedHeader)) {
    if (token === '*') {
      return true;
    }
    const candidate = normalizeWeakTag(token);
    if (candidate !== null && candidate === currentNormalized) {
      return true;
    }
  }

  return false;
}

function normalizeWeakTag(tag: string): string | null {
  let value = tag.trim();
  if (value.startsWith('W/')) {
    value = value.slice(2).trim();
  }
  if (value.length < 2 || !value.startsWith('"') || !value.endsWith('"')) {
    return null;
  }
  return value;
}

function splitEntityTags(header: string): string[] {
  const tags: string[] = [];
  let inQuotes = false;
  let escaped = false;
  let start = 0;

  for (let i = 0; i < header.length; i += 1) {
    const ch = header[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === '\\' && inQuotes) {
      escaped = true;
      continue;
    }
    if (ch === '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (ch === ',' && !inQuotes) {
      const segment = header.slice(start, i).trim();
      if (segment.length > 0) {
        tags.push(segment);
      }
      start = i + 1;
    }
  }

  const tail = header.slice(start).trim();
  if (tail.length > 0) {
    tags.push(tail);
  }
  return tags;
}
