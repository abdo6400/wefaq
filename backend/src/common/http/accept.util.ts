/**
 * Checks whether an HTTP Accept header permits an application/json response.
 * Missing or empty headers are treated as accepting any media type per RFC 9110.
 */
export function acceptsJson(
  acceptHeader: string | string[] | undefined,
): boolean {
  if (!acceptHeader) {
    return true;
  }

  const raw = Array.isArray(acceptHeader)
    ? acceptHeader.join(',')
    : acceptHeader;

  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    return true;
  }

  const ranges = trimmed.split(',');
  for (const range of ranges) {
    const [mediaTypeRaw, ...params] = range.split(';');
    const mediaType = mediaTypeRaw.trim().toLowerCase();
    if (!mediaType) {
      continue;
    }

    const quality = parseQuality(params);
    if (quality <= 0) {
      continue;
    }

    if (
      mediaType === 'application/json' ||
      mediaType === 'application/*' ||
      mediaType === '*/*' ||
      (mediaType.startsWith('application/') && mediaType.endsWith('+json'))
    ) {
      return true;
    }
  }

  return false;
}

function parseQuality(params: string[]): number {
  for (const param of params) {
    const [key, value] = param.split('=').map((part) => part.trim());
    if (key.toLowerCase() === 'q' && value !== undefined) {
      const parsed = Number.parseFloat(value);
      return Number.isFinite(parsed) ? parsed : 0;
    }
  }
  return 1;
}
