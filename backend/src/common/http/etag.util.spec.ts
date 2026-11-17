import { matchesIfNoneMatch } from './etag.util';

describe('matchesIfNoneMatch', () => {
  const currentEtag = '"v1-r1-0123456789abcdef"';

  it('returns false when If-None-Match is missing or blank', () => {
    expect(matchesIfNoneMatch(undefined, currentEtag)).toBe(false);
    expect(matchesIfNoneMatch('', currentEtag)).toBe(false);
    expect(matchesIfNoneMatch('   ', currentEtag)).toBe(false);
  });

  it('matches an identical strong ETag', () => {
    expect(matchesIfNoneMatch('"v1-r1-0123456789abcdef"', currentEtag)).toBe(
      true,
    );
  });

  it('matches a weak variant of the same ETag', () => {
    expect(matchesIfNoneMatch('W/"v1-r1-0123456789abcdef"', currentEtag)).toBe(
      true,
    );
  });

  it('matches wildcard *', () => {
    expect(matchesIfNoneMatch('*', currentEtag)).toBe(true);
  });

  it('matches when one of multiple comma-separated ETags matches', () => {
    expect(
      matchesIfNoneMatch(
        '"v1-r0-old", W/"v1-r1-0123456789abcdef"',
        currentEtag,
      ),
    ).toBe(true);
  });

  it('handles array headers and commas inside quoted opaque tags safely', () => {
    const commaTag = '"tag,with,commas"';
    expect(matchesIfNoneMatch(['"other"', commaTag], commaTag)).toBe(true);
    expect(matchesIfNoneMatch('"tag"', commaTag)).toBe(false);
  });

  it('returns false for stale or unquoted tags', () => {
    expect(matchesIfNoneMatch('"v1-r0-stale"', currentEtag)).toBe(false);
    expect(matchesIfNoneMatch('v1-r1-0123456789abcdef', currentEtag)).toBe(
      false,
    );
  });
});
