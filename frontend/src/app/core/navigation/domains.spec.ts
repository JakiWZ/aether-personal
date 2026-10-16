import { DOMAINS, domainByPath } from './domains';

describe('domainByPath', () => {
  it('returns the domain registered under a path', () => {
    expect(domainByPath('missions').squad).toBe('PHOENIX');
  });

  it('rejects an unknown path', () => {
    expect(() => domainByPath('unknown')).toThrowError('Unknown domain: unknown');
  });

  it('has unique paths', () => {
    expect(new Set(DOMAINS.map((d) => d.path)).size).toBe(DOMAINS.length);
  });
});
