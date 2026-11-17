# Wefaq Backend API & Admin Dashboard (NestJS)

Implements the snapshot delivery contract defined in [`docs/questions-api-contract.md`](../docs/questions-api-contract.md), plus a full Arabic RTL Admin Dashboard with sign-in, question/activity management, app & site configuration, and Ed25519 activation code generation.

## Endpoints & UI

- `GET /dashboard`: Arabic RTL web dashboard protected by a sign-in gate (`POST /v1/auth/login`, signed `HttpOnly` cookie session) for:
  - **بنك الأسئلة:** browsing, filtering, adding, bulk importing, editing, approving/unapproving, deleting, and exporting questions.
  - **الأنشطة والمواقف:** creating, editing, approving, and exporting discussion scenarios and priority ordering exercises.
  - **إدارة التطبيق والموقع:** configuring contact channels (no payment), in-app announcement banners, feature toggles, release metadata, and landing branding copy.
  - **أكواد التفعيل والمفاتيح:** generating Ed25519 keypairs, issuing signed offline activation codes and `/activate#<code>` links compatible with the Flutter app, and tracking/revoking issued records.
- `GET /activate`: Client-side-only fallback page for Android `/activate#<code>` activation links.
- `GET /.well-known/assetlinks.json`: Digital Asset Links endpoint when `ANDROID_SHA256_FINGERPRINTS` is set.
- `POST /v1/auth/login`, `GET /v1/auth/session`, `POST /v1/auth/logout`: Signed `HttpOnly` cookie session authentication.
- `GET /v1/question-catalog` (`HEAD` also supported): Validated UTF-8 JSON snapshot + opaque `ETag` (`304 Not Modified` supported).
- `GET /v1/questions`, `POST /v1/questions`, `POST /v1/questions/bulk`, `PATCH /v1/questions/:id`, `DELETE /v1/questions/:id`, `GET /v1/questions/meta`, `GET /v1/questions/export`
- `GET /v1/activity-catalog`, `GET /v1/activities`, `POST /v1/activities`, `PATCH /v1/activities/:id`, `DELETE /v1/activities/:id`, `GET /v1/activities/export`
- `GET /v1/app-config`, `PUT /v1/app-config`, `PATCH /v1/app-config`
- `GET /v1/licenses/config`, `POST /v1/licenses/keygen`, `GET /v1/licenses`, `POST /v1/licenses/generate`, `PATCH /v1/licenses/:id/revoke`
- `GET /v1/health` (and `GET /health`): Readiness metadata.
- `GET /logo.png` & `GET /favicon.png`: Wefaq brand icon.

## Storage & Security Configuration

- **Local Development:** Reads and atomically writes JSON files under `data/`.
- **Vercel Serverless:**
  - Set `BLOB_READ_WRITE_TOKEN` (Vercel Blob store) for persistent edits across serverless invocations (`wefaq/question-catalog.v1.json`, `wefaq/activities-catalog.v1.json`, `wefaq/app-config.v1.json`, `wefaq/licenses-registry.v1.json`).
  - Without `BLOB_READ_WRITE_TOKEN`, Vercel deployments run in ephemeral in-memory preview mode seeded from `data/`.
- **Admin Authentication:**
  - Set `ADMIN_API_TOKEN` and/or `ADMIN_PASSWORD` (with optional `ADMIN_USERNAME`, defaulting to `admin`, and optional `ADMIN_SESSION_SECRET`).
  - Both signed `HttpOnly` session cookies (`wefaq_admin_session`) and `Authorization: Bearer <token>` / `X-Admin-Token` are accepted.
  - On Vercel or with `NODE_ENV=production`, all protected routes and login fail closed (`503`) if no admin secret is configured.
- **Activation Signing:**
  - Set `LICENSE_PRIVATE_SEED` (32-byte Ed25519 seed as base64url or 64-char hex) in server environment variables (never commit to Git).
  - Copy the corresponding `WEFAQ_LICENSE_PUBLIC_KEY` from the dashboard into the Flutter `.env` or `--dart-define`.
  - Optionally set `WEFAQ_LINK_HOST`, `ANDROID_PACKAGE_NAME`, and `ANDROID_SHA256_FINGERPRINTS` for Android App Links.

## Commands

```bash
npm install
npm run validate:catalog
npm run typecheck
npm test
npm run test:e2e
npm run build
npm run start:dev
```
