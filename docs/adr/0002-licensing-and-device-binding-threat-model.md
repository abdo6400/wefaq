# ADR 0002: Licensing, Device Binding, and Quota Threat Model

## Status
Proposed (Pre-commercial Architecture Baseline)

## Context
Wefaq plans to offer subscription plans (duration-based, quota-based, or hybrid) allowing two engaged individuals to share access across authorized devices. The production plan identifies several architectural constraints and attack vectors:
1. **Store Policy Constraints**: Google Play and Apple App Store enforce strict billing policies for digital content consumed in-app. Any external payment flow (e.g., manual WhatsApp activation) requires thorough policy, legal, and operational clearance or must operate under explicit store exceptions.
2. **Device Identity Limits**: Hardware identifiers (IMEI, MAC address, permanent Android ID) are deprecated, restricted by OS sandboxes, or forbidden by privacy regulations (such as Egyptian Law 151/2020 and GDPR).
3. **Double-Spend & Concurrency**: Two devices sharing a single remaining quota session might attempt to initiate a session simultaneously, leading to race conditions.
4. **Offline Tampering**: Local device clocks can be altered, and static local unlock flags can be modified on rooted or jailbroken devices.

## Decision

### 1. Cryptographic Device Identity (`InstallationKeyPair`)
- Each client installation generates an asymmetric key pair (e.g., Ed25519) within the platform's hardware-backed keystore (Android KeyStore / iOS Secure Enclave).
- The public key is registered with the server as the `installation_public_key`, accompanied by a random UUID `installation_id`.
- The client signs challenges to prove possession without exposing device hardware fingerprints.

### 2. Authorization Slots & Activation Codes
- A license is issued with a strict slot cap (e.g., maximum 2 authorized installations for an engaged couple).
- Activation codes are high-entropy, single-use per authorized slot, stored server-side as keyed cryptographic hashes (e.g., HMAC-SHA256). Plaintext codes are never logged.
- Redeeming a code requires the device to provide:
  `code + installation_id + signed(server_challenge)`
- The server checks slot availability in a database transaction with serializable isolation, preventing concurrent claim races.

### 3. Session Quota Consumption & Idempotency
- When a user initiates a session, the client issues a `POST /sessions/start` with a client-generated UUID `idempotency_key`.
- The server atomically:
  1. Checks license validity (time boundary and remaining quota).
  2. Increments consumed sessions / appends to quota ledger.
  3. Records `(license_id, idempotency_key, session_token)`.
- If a network error occurs, retrying with the same `idempotency_key` returns the existing session token without double-charging the quota.
- If two devices attempt to start sessions simultaneously with 1 quota remaining, exactly one transaction commits; the other receives `HTTP 409 QuotaExhausted`.

### 4. Bounded Offline Leases
- Quota session initiation requires an online check.
- Once initiated, an active session may proceed offline using a short, cryptographically signed lease token containing `(license_id, session_id, expires_at_utc)`.
- Client time is validated against signed server timestamps to limit clock rollback abuse.
- Server-side takedown / content withdrawal manifests through version tombstones during subsequent syncs.

### 5. Device Replacement & Recovery
- Device loss, reinstallation, or hardware upgrade creates a new `installation_id`.
- Replacing a slot requires authenticated operator action or recovery verification, recording an immutable audit log entry.
- Slot replacement revokes previous leases upon subsequent check-in.

## Consequences
- **Positive**: Compliant with modern mobile OS privacy sandboxes; zero dependence on illegal hardware fingerprints.
- **Positive**: Strict transaction boundaries prevent double-spending of session quotas.
- **Negative**: Requires operational backend infrastructure (PostgreSQL transaction isolation and cryptographic verification) prior to commercial billing rollout.
