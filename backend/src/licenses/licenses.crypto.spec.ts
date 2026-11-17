import {
  generateEd25519KeyPairMaterial,
  parseEd25519Seed,
  signOfflineLicense,
  verifyOfflineLicense,
} from './licenses.crypto';
import { OfflineLicensePayload } from './licenses.types';

describe('Licenses Ed25519 Crypto', () => {
  it('generates keypair, derives identical public key from seed, and signs/verifies payload', () => {
    const { privateSeedBase64Url, publicKeyBase64Url } =
      generateEd25519KeyPairMaterial();
    const material = parseEd25519Seed(privateSeedBase64Url);
    expect(material.publicKeyBase64Url).toBe(publicKeyBase64Url);

    const payload: OfflineLicensePayload = {
      v: 1,
      id: 'lic_test_2026',
      devices: [
        'inst_12345678-1234-4234-8234-123456789abc',
        'inst_87654321-1234-4234-8234-123456789abc',
      ],
      issuedAt: '2026-11-16T00:00:00.000Z',
      expiresAt: '2027-11-16T00:00:00.000Z',
      sessionLimit: 20,
    };

    const code = signOfflineLicense(payload, material);
    expect(code.split('.')).toHaveLength(2);

    const verified = verifyOfflineLicense(code, publicKeyBase64Url);
    expect(verified).toEqual(payload);
  });

  it('rejects tampered codes and invalid installation IDs', () => {
    const { privateSeedBase64Url, publicKeyBase64Url } =
      generateEd25519KeyPairMaterial();
    const material = parseEd25519Seed(privateSeedBase64Url);

    const payload: OfflineLicensePayload = {
      v: 1,
      id: 'lic_tamper',
      devices: ['inst_12345678-1234-4234-8234-123456789abc'],
      issuedAt: '2026-11-16T00:00:00.000Z',
      sessionLimit: 5,
    };
    const code = signOfflineLicense(payload, material);
    const [rawPayload, sig] = code.split('.');
    const mutatedPayload = Buffer.from(
      JSON.stringify({ ...payload, sessionLimit: 999 }),
      'utf8',
    ).toString('base64url');

    expect(() =>
      verifyOfflineLicense(`${mutatedPayload}.${sig}`, publicKeyBase64Url),
    ).toThrow();
    const flippedSig = `${sig[0] === 'A' ? 'B' : 'A'}${sig.slice(1)}`;
    expect(() =>
      verifyOfflineLicense(`${rawPayload}.${flippedSig}`, publicKeyBase64Url),
    ).toThrow();

    expect(() =>
      signOfflineLicense(
        {
          ...payload,
          devices: ['not-an-inst-id'],
        },
        material,
      ),
    ).toThrow();
  });
});
