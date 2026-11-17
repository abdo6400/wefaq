import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import {
  createJsonDocumentStore,
  JsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import { isPlainObject } from '../question-catalog/question-catalog.validator';
import {
  buildActivationLink,
  generateEd25519KeyPairMaterial,
  getServerSigningMaterial,
  LICENSE_ID_PATTERN,
  parseEd25519Seed,
  signOfflineLicense,
} from './licenses.crypto';
import {
  IssuedLicenseRecord,
  LicensesRegistrySnapshot,
  OfflineLicensePayload,
} from './licenses.types';

export const LICENSES_STORE = Symbol('LICENSES_STORE');

export const FALLBACK_LICENSES_REGISTRY: LicensesRegistrySnapshot = {
  schemaVersion: 1,
  revision: 1,
  updatedAt: '2026-11-16T00:00:00Z',
  licenses: [],
};

@Injectable()
export class LicensesService {
  private readonly store: JsonDocumentStore<LicensesRegistrySnapshot>;
  private cached: LicensesRegistrySnapshot | null = null;
  private versionTag: string | undefined;
  private mutationTail: Promise<unknown> = Promise.resolve();

  constructor(
    @Optional()
    @Inject(LICENSES_STORE)
    store?: JsonDocumentStore<LicensesRegistrySnapshot>,
  ) {
    this.store =
      store ??
      createJsonDocumentStore<LicensesRegistrySnapshot>({
        filename: 'licenses-registry.v1.json',
        blobPathname: 'wefaq/licenses-registry.v1.json',
        envPathVar: 'LICENSES_FILE_PATH',
        seedFactory: () =>
          loadSeedFileOrFallback(
            'licenses-registry.v1.json',
            () => FALLBACK_LICENSES_REGISTRY,
          ),
      });
  }

  getSigningConfig() {
    let serverKey: ReturnType<typeof getServerSigningMaterial> = null;
    let configError: string | null = null;
    try {
      serverKey = getServerSigningMaterial();
    } catch (error) {
      configError = error instanceof Error ? error.message : String(error);
    }

    return {
      serverKeyConfigured: serverKey !== null,
      publicKey: serverKey?.publicKeyBase64Url ?? null,
      configError,
      defaultLinkHost: process.env.WEFAQ_LINK_HOST?.trim() ?? '',
    };
  }

  generateKeyPair() {
    return generateEd25519KeyPairMaterial();
  }

  async listLicenses(search?: string, status?: string) {
    const registry = await this.getRegistry();
    const normalizedSearch = search?.trim().toLowerCase() ?? '';
    const nowMs = Date.now();

    const filtered = registry.licenses.filter((item) => {
      if (status === 'active' && item.status !== 'active') return false;
      if (status === 'revoked' && item.status !== 'revoked') return false;
      if (status === 'expired') {
        if (!item.expiresAt || Date.parse(item.expiresAt) > nowMs) return false;
      }
      if (normalizedSearch) {
        const hay = `${item.id}\n${item.label}\n${item.devices.join('\n')}`.toLowerCase();
        if (!hay.includes(normalizedSearch)) return false;
      }
      return true;
    });

    const summary = {
      total: registry.licenses.length,
      active: registry.licenses.filter(
        (l) =>
          l.status === 'active' &&
          (!l.expiresAt || Date.parse(l.expiresAt) > nowMs),
      ).length,
      revoked: registry.licenses.filter((l) => l.status === 'revoked').length,
      expired: registry.licenses.filter(
        (l) =>
          l.status === 'active' &&
          Boolean(l.expiresAt) &&
          Date.parse(l.expiresAt!) <= nowMs,
      ).length,
    };

    return {
      revision: registry.revision,
      updatedAt: registry.updatedAt,
      summary,
      items: [...filtered].reverse(),
    };
  }

  async generateLicense(rawBody: unknown) {
    if (!isPlainObject(rawBody)) {
      throw new BadRequestException('Request body must be a JSON object.');
    }

    const serverMaterial = getServerSigningMaterial();
    const overrideSeed =
      typeof rawBody.privateSeed === 'string' &&
      rawBody.privateSeed.trim().length > 0
        ? parseEd25519Seed(rawBody.privateSeed)
        : null;

    const signingMaterial = overrideSeed ?? serverMaterial;
    if (!signingMaterial) {
      throw new BadRequestException(
        'لم يتم إعداد مفتاح التوقيع LICENSE_PRIVATE_SEED على الخادم. قم بتوليد زوج مفاتيح أو إدخال المفتاح الخاص للتوقيع.',
      );
    }

    const usingServerKey = overrideSeed === null;
    const rawDevices = Array.isArray(rawBody.devices) ? rawBody.devices : [];
    const devices = rawDevices
      .map((d) => (typeof d === 'string' ? d.trim() : ''))
      .filter((d) => d.length > 0);

    const now = new Date();
    const issuedAt = now.toISOString();

    let expiresAt: string | undefined;
    if (
      typeof rawBody.expiresAt === 'string' &&
      rawBody.expiresAt.trim().length > 0
    ) {
      const parsed = new Date(rawBody.expiresAt.trim());
      if (Number.isNaN(parsed.getTime())) {
        throw new BadRequestException('Invalid expiresAt date.');
      }
      expiresAt = parsed.toISOString();
    } else if (
      typeof rawBody.durationDays === 'number' &&
      Number.isFinite(rawBody.durationDays) &&
      rawBody.durationDays > 0
    ) {
      if (rawBody.durationDays > 3650) {
        throw new BadRequestException(
          'durationDays must not exceed 3650 days.',
        );
      }
      const exp = new Date(
        now.getTime() + Math.round(rawBody.durationDays * 86400000),
      );
      expiresAt = exp.toISOString();
    }

    let sessionLimit: number | undefined;
    if (rawBody.sessionLimit !== undefined && rawBody.sessionLimit !== null && rawBody.sessionLimit !== '') {
      const parsedLimit = Number(rawBody.sessionLimit);
      if (!Number.isInteger(parsedLimit)) {
        throw new BadRequestException('sessionLimit must be an integer.');
      }
      sessionLimit = parsedLimit;
    }

    const label =
      typeof rawBody.label === 'string' ? rawBody.label.trim().slice(0, 120) : '';
    const linkHost =
      typeof rawBody.linkHost === 'string' && rawBody.linkHost.trim().length > 0
        ? rawBody.linkHost.trim()
        : process.env.WEFAQ_LINK_HOST?.trim() ?? '';
    const replacedFromId =
      typeof rawBody.replacedFromId === 'string' &&
      rawBody.replacedFromId.trim().length > 0
        ? rawBody.replacedFromId.trim()
        : undefined;

    const { record, code } = await this.mutateRegistry((current) => {
      const existingIds = new Set(current.licenses.map((item) => item.id));
      let id: string;
      if (typeof rawBody.id === 'string' && rawBody.id.trim().length > 0) {
        id = rawBody.id.trim();
        if (!LICENSE_ID_PATTERN.test(id)) {
          throw new BadRequestException(
            'License id must be 1-100 characters using letters, numbers, "-" or "_".',
          );
        }
        if (existingIds.has(id)) {
          throw new ConflictException(`License id "${id}" already exists.`);
        }
      } else {
        id = generateUniqueLicenseId(existingIds);
      }

      const payload: OfflineLicensePayload = {
        v: 1,
        id,
        devices,
        issuedAt,
        ...(expiresAt !== undefined ? { expiresAt } : {}),
        ...(sessionLimit !== undefined ? { sessionLimit } : {}),
      };

      const signedCode = signOfflineLicense(payload, signingMaterial);
      const newRecord: IssuedLicenseRecord = {
        id,
        label,
        devices,
        issuedAt,
        ...(expiresAt !== undefined ? { expiresAt } : {}),
        ...(sessionLimit !== undefined ? { sessionLimit } : {}),
        status: 'active',
        createdAt: issuedAt,
        publicKey: signingMaterial.publicKeyBase64Url,
        usingServerKey,
        ...(replacedFromId ? { replacedFromId } : {}),
      };

      const nextList = current.licenses.map((item) => {
        if (replacedFromId && item.id === replacedFromId && item.status === 'active') {
          return {
            ...item,
            status: 'revoked' as const,
            revokedAt: issuedAt,
            revokedReason: `تم الاستبدال بالترخيص ${id}`,
          };
        }
        return item;
      });
      nextList.push(newRecord);

      return {
        licenses: nextList,
        result: { record: newRecord, code: signedCode },
      };
    });

    const activationLink = buildActivationLink(code, linkHost);

    return {
      code,
      activationLink,
      publicKeyUsed: signingMaterial.publicKeyBase64Url,
      usingServerKey,
      record,
    };
  }

  async revokeLicense(id: string, rawBody: unknown) {
    const reason =
      isPlainObject(rawBody) && typeof rawBody.reason === 'string'
        ? rawBody.reason.trim().slice(0, 240)
        : 'تم الإلغاء بواسطة الإدارة';

    return this.mutateRegistry((current) => {
      const idx = current.licenses.findIndex((item) => item.id === id);
      if (idx === -1) {
        throw new NotFoundException(`License "${id}" was not found.`);
      }
      const existing = current.licenses[idx];
      const updated: IssuedLicenseRecord = {
        ...existing,
        status: 'revoked',
        revokedAt: new Date().toISOString(),
        revokedReason: reason || 'تم الإلغاء بواسطة الإدارة',
      };
      const next = [...current.licenses];
      next[idx] = updated;
      return {
        licenses: next,
        result: updated,
      };
    });
  }

  private async getRegistry(): Promise<LicensesRegistrySnapshot> {
    const loaded = await this.store.loadLatest(this.versionTag);
    if (loaded) {
      this.cached = loaded.data;
      this.versionTag = loaded.versionTag;
    }
    return this.cached ?? FALLBACK_LICENSES_REGISTRY;
  }

  private mutateRegistry<T>(
    mutator: (current: LicensesRegistrySnapshot) => {
      readonly licenses: IssuedLicenseRecord[];
      readonly result: T;
    },
  ): Promise<T> {
    const task = this.mutationTail.then(async () => {
      const current = await this.getRegistry();
      const { licenses, result } = mutator(current);
      const next: LicensesRegistrySnapshot = {
        schemaVersion: 1,
        revision: current.revision + 1,
        updatedAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        licenses,
      };
      const saved = await this.store.save(next, this.versionTag);
      this.cached = next;
      this.versionTag = saved.versionTag ?? this.versionTag;
      return result;
    });

    this.mutationTail = task.catch(() => undefined);
    return task;
  }
}

function generateUniqueLicenseId(existingIds: ReadonlySet<string>): string {
  const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  for (let i = 0; i < 20; i += 1) {
    const candidate = `lic_${datePart}_${randomBytes(3).toString('hex')}`;
    if (!existingIds.has(candidate)) {
      return candidate;
    }
  }
  return `lic_${Date.now()}`;
}
