import { BadRequestException } from '@nestjs/common';
import {
  createPrivateKey,
  createPublicKey,
  generateKeyPairSync,
  KeyObject,
  sign,
  verify,
} from 'node:crypto';
import { OfflineLicensePayload } from './licenses.types';

const PKCS8_ED25519_PREFIX = Buffer.from(
  '302e020100300506032b657004220420',
  'hex',
);
const SPKI_ED25519_PREFIX_LENGTH = 12;

export const LICENSE_ID_PATTERN = /^[A-Za-z0-9_-]{1,100}$/;
export const INSTALLATION_ID_PATTERN = /^inst_[0-9a-f-]{36}$/;

export interface Ed25519KeyMaterial {
  readonly privateKey: KeyObject;
  readonly publicKey: KeyObject;
  readonly publicKeyBase64Url: string;
  readonly seedBytes: Buffer;
}

export function generateEd25519KeyPairMaterial(): {
  readonly privateSeedBase64Url: string;
  readonly publicKeyBase64Url: string;
} {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const pkcs8 = privateKey.export({ format: 'der', type: 'pkcs8' }) as Buffer;
  const spki = publicKey.export({ format: 'der', type: 'spki' }) as Buffer;
  const seed = pkcs8.subarray(pkcs8.length - 32);
  const rawPub = spki.subarray(SPKI_ED25519_PREFIX_LENGTH);

  return {
    privateSeedBase64Url: seed.toString('base64url'),
    publicKeyBase64Url: rawPub.toString('base64url'),
  };
}

export function parseEd25519Seed(rawSeed: string): Ed25519KeyMaterial {
  const trimmed = rawSeed.trim();
  let seedBytes: Buffer;

  if (/^[0-9a-fA-F]{64}$/.test(trimmed)) {
    seedBytes = Buffer.from(trimmed, 'hex');
  } else {
    const normalized = trimmed.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
    if (!/^[A-Za-z0-9_-]{42,44}$/.test(normalized)) {
      throw new BadRequestException(
        'Invalid Ed25519 private seed format; expected 32-byte base64url or 64-char hex.',
      );
    }
    seedBytes = Buffer.from(normalized, 'base64url');
  }

  if (seedBytes.length !== 32) {
    throw new BadRequestException('Ed25519 private seed must be exactly 32 bytes.');
  }

  const privateKey = createPrivateKey({
    key: Buffer.concat([PKCS8_ED25519_PREFIX, seedBytes]),
    format: 'der',
    type: 'pkcs8',
  });
  const publicKey = createPublicKey(privateKey);
  const spki = publicKey.export({ format: 'der', type: 'spki' }) as Buffer;
  const rawPub = spki.subarray(SPKI_ED25519_PREFIX_LENGTH);

  return {
    privateKey,
    publicKey,
    publicKeyBase64Url: rawPub.toString('base64url'),
    seedBytes,
  };
}

export function getServerSigningMaterial(): Ed25519KeyMaterial | null {
  const envSeed = process.env.LICENSE_PRIVATE_SEED?.trim() ?? '';
  if (envSeed.length === 0) {
    return null;
  }
  return parseEd25519Seed(envSeed);
}

/**
 * Signs an OfflineLicensePayload identically to Dart's OfflineLicenseCodec:
 * `<base64url(utf8(json))>.<base64url(ed25519_sig(utf8(encodedPayload)))>`
 */
export function signOfflineLicense(
  payload: OfflineLicensePayload,
  keyMaterial: Ed25519KeyMaterial,
): string {
  validateOfflineLicensePayload(payload);
  const encodedPayload = Buffer.from(
    JSON.stringify(payload),
    'utf8',
  ).toString('base64url');
  const signature = sign(
    null,
    Buffer.from(encodedPayload, 'utf8'),
    keyMaterial.privateKey,
  );
  return `${encodedPayload}.${signature.toString('base64url')}`;
}

export function verifyOfflineLicense(
  code: string,
  publicKeyBase64Url: string,
): OfflineLicensePayload {
  const parts = code.trim().split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    throw new Error('Invalid code structure');
  }
  const rawPub = Buffer.from(publicKeyBase64Url.trim(), 'base64url');
  if (rawPub.length !== 32) {
    throw new Error('Invalid Ed25519 public key length');
  }
  const spkiPrefix = Buffer.from('302a300506032b6570032100', 'hex');
  const pubKeyObj = createPublicKey({
    key: Buffer.concat([spkiPrefix, rawPub]),
    format: 'der',
    type: 'spki',
  });
  const sig = Buffer.from(parts[1], 'base64url');
  if (sig.length !== 64) {
    throw new Error('Invalid Ed25519 signature length');
  }
  const valid = verify(null, Buffer.from(parts[0], 'utf8'), pubKeyObj, sig);
  if (!valid) {
    throw new Error('Invalid Ed25519 signature');
  }
  const decoded = JSON.parse(
    Buffer.from(parts[0], 'base64url').toString('utf8'),
  ) as OfflineLicensePayload;
  validateOfflineLicensePayload(decoded);
  return decoded;
}

export function validateOfflineLicensePayload(
  payload: OfflineLicensePayload,
): void {
  if (payload.v !== 1) {
    throw new BadRequestException('License payload version must be 1.');
  }
  if (!LICENSE_ID_PATTERN.test(payload.id)) {
    throw new BadRequestException(
      'License "id" must be 1-100 characters of letters, numbers, "-" or "_".',
    );
  }
  if (
    !Array.isArray(payload.devices) ||
    payload.devices.length === 0 ||
    payload.devices.length > 20
  ) {
    throw new BadRequestException(
      'License must target between 1 and 20 installation IDs.',
    );
  }
  const seen = new Set<string>();
  for (const device of payload.devices) {
    if (typeof device !== 'string' || !INSTALLATION_ID_PATTERN.test(device)) {
      throw new BadRequestException(
        `Invalid installation ID "${String(device)}". Expected format inst_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.`,
      );
    }
    if (seen.has(device)) {
      throw new BadRequestException(
        `Duplicate installation ID "${device}".`,
      );
    }
    seen.add(device);
  }

  const issuedMs = Date.parse(payload.issuedAt);
  if (!payload.issuedAt.endsWith('Z') || !Number.isFinite(issuedMs)) {
    throw new BadRequestException('Invalid UTC issuedAt timestamp.');
  }

  if (payload.expiresAt !== undefined) {
    const expiresMs = Date.parse(payload.expiresAt);
    if (!payload.expiresAt.endsWith('Z') || !Number.isFinite(expiresMs)) {
      throw new BadRequestException('Invalid UTC expiresAt timestamp.');
    }
    if (expiresMs <= issuedMs) {
      throw new BadRequestException(
        'Expiration date must be strictly after issue date.',
      );
    }
  }

  if (payload.sessionLimit !== undefined) {
    if (
      !Number.isInteger(payload.sessionLimit) ||
      payload.sessionLimit < 1 ||
      payload.sessionLimit > 1000000
    ) {
      throw new BadRequestException(
        'Session limit must be an integer between 1 and 1,000,000.',
      );
    }
  }

  if (
    payload.expiresAt === undefined &&
    payload.sessionLimit === undefined
  ) {
    throw new BadRequestException(
      'At least one of expiresAt or sessionLimit must be specified.',
    );
  }
}

export function buildActivationLink(
  code: string,
  rawHost: string | undefined,
): string | null {
  const hostInput = rawHost?.trim() ?? '';
  if (hostInput.length === 0) return null;

  let hostname: string;
  try {
    const candidate = hostInput.includes('://')
      ? new URL(hostInput)
      : new URL(`https://${hostInput}`);
    if (candidate.protocol !== 'https:' || !candidate.hostname) {
      throw new Error('Invalid host');
    }
    hostname = candidate.hostname;
  } catch {
    throw new BadRequestException(
      'Activation link host must be a valid HTTPS domain name.',
    );
  }

  return `https://${hostname}/activate#${code}`;
}
