export interface OfflineLicensePayload {
  readonly v: 1;
  readonly id: string;
  readonly devices: readonly string[];
  readonly issuedAt: string;
  readonly expiresAt?: string;
  readonly sessionLimit?: number;
}

export type LicenseRecordStatus = 'active' | 'revoked';

export interface IssuedLicenseRecord {
  readonly id: string;
  readonly label: string;
  readonly devices: readonly string[];
  readonly issuedAt: string;
  readonly expiresAt?: string;
  readonly sessionLimit?: number;
  readonly status: LicenseRecordStatus;
  readonly createdAt: string;
  readonly publicKey: string;
  readonly usingServerKey: boolean;
  readonly replacedFromId?: string;
  readonly revokedAt?: string;
  readonly revokedReason?: string;
}

export interface LicensesRegistrySnapshot {
  readonly schemaVersion: 1;
  readonly revision: number;
  readonly updatedAt: string;
  readonly licenses: readonly IssuedLicenseRecord[];
}
