import { acceptsJson } from './accept.util';

describe('acceptsJson', () => {
  it('allows missing or empty Accept header', () => {
    expect(acceptsJson(undefined)).toBe(true);
    expect(acceptsJson('')).toBe(true);
  });

  it('allows application/json, wildcards, and browser headers with */*', () => {
    expect(acceptsJson('application/json')).toBe(true);
    expect(acceptsJson('application/json; charset=utf-8')).toBe(true);
    expect(acceptsJson('application/*')).toBe(true);
    expect(acceptsJson('*/*')).toBe(true);
    expect(acceptsJson('application/problem+json')).toBe(true);
    expect(
      acceptsJson(
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      ),
    ).toBe(true);
  });

  it('rejects explicitly incompatible Accept headers or q=0 exclusions', () => {
    expect(acceptsJson('text/plain')).toBe(false);
    expect(acceptsJson('application/xml')).toBe(false);
    expect(acceptsJson('application/json;q=0')).toBe(false);
    expect(acceptsJson('application/json;q=0, text/plain;q=1')).toBe(false);
  });
});
