# Offline-first content and licensing: implementation direction

This document records product decisions and implementation limits. It is not a
claim that a content service is deployed or that release review is complete.

## Distribution and content

The first paid release is intended for direct Android APK distribution; store
distribution requires a separate billing and policy review. Question updates
come from an API, are validated, and are cached locally for offline use. The
bundled catalog supplies the first offline install. A failed download or invalid
catalog must leave the last usable catalog intact, with a visible retry state.
Catalogs need a schema version, monotonically increasing revision, stable IDs,
and explicit retirement rules. Do not trust an update merely because it is
valid JSON: authenticate its origin, check bounds and enums, reject duplicate
IDs, and atomically replace only after full validation. Avoid deleting questions
still referenced by a saved session or favorite without a migration strategy.
Content still requires documented editorial, religious, and family review.
The app implements manual HTTPS catalog updates and local caching; the endpoint
must be configured at build time. See [questions API](questions-api-contract.md)
for validation rules and the proposed server contract.

## Offline activation, 14-day automatic trial, and per-installation quota

**Implementation status:** The app includes an automatic 14-day (2-week)
offline free trial starting from first initialization (`trialDuration: Duration(days: 14)`
in `main.dart`), alongside an offline activation gate, signed payload verification,
secure local storage, and independent per-installation session accounting. During
the 14-day offline window, unactivated configured builds open immediately without
requiring an upfront code. Once 14 days elapse (or on clock rollback), the trial
expires automatically—even completely offline—and closes back to `OfflineActivationGate`,
preserving any saved session until a signed code or activation link is provided.
A session is saved before it is charged; retries reuse its
ID. A signed-code issuer is provided. Production key provisioning, recovery,
release validation and human content review are not complete; do not sell
codes yet. The codec accepts at most 20 installation IDs per code.
The running app creates one activation service instance in the main isolate;
its queue serializes operations only within that instance. Do not introduce
background engines, isolates, or multiple service instances accessing the same
activation record without a cross-context transaction/locking design.
Android secure-storage writes use platform preferences; interruption and device
backup/restore behavior must still be tested on physical devices.

The issuer expects a 32-byte Ed25519 private seed stored in a protected file
outside the repository and a JSON request such as:

```json
{"v":1,"id":"license_example","devices":["inst_12345678-1234-4234-8234-123456789abc"],"issuedAt":"2026-11-15T00:00:00.000Z","expiresAt":"2027-11-15T00:00:00.000Z","sessionLimit":20}
```

Use `offline_license_issuer.dart` for this format. The older
`tool/license_manager.dart` implements a separate mock workflow and its codes
are not compatible with the offline activation gate.

Run `dart run tool/offline_license_issuer.dart issue <seed-file> <request-file>`
on the trusted operator computer. The command prints the code, which must be
handled as a customer credential. Never commit the private seed, requests
containing real device IDs, or issued codes. Before production use, establish
secure key backup, access controls, rotation, and recovery. An expiry, a session limit, or
both must be present. The expiry is exclusive and timestamps must be UTC.
Use `dart run tool/offline_license_issuer.dart public <seed-file>` to obtain the
public verification key. Configure it at build time using
`--dart-define=WEFAQ_LICENSE_PUBLIC_KEY=<public-key>`. A build without a valid
key fails closed and displays a configuration error; do not distribute it.
Each issued license must use a unique `id`; use a new ID for a renewal. Keep
records and backups securely outside the repository. Re-entering the same code
does not reset its count. Local storage loss can require a replacement code.

On a trusted operator machine, first prepare an existing access-restricted
directory outside the repository. Run `dart run tool/offline_license_issuer.dart
keygen <absolute-new-private-seed-file>` from the project root. It refuses to
overwrite an existing file and prints the public key only. The seed file
inherits the directory's permissions: the command does not configure or verify
its ACL. Check those permissions and arrange a secure backup before issuing
real codes. Losing or replacing this key invalidates the trust relationship
with existing app builds. Do not send the seed to customers.

### Shareable Android activation links

The issuer can produce a link with `dart run tool/offline_license_issuer.dart
issue-link <seed-file> <request-file> https://YOUR_HOST`. It places the signed
credential after `#`, so it is not included in the HTTP request to the website.
The app accepts only `https://YOUR_HOST/activate#<signed-code>` for the host
configured at build time, verifies the signature, installation ID, and dates,
and requires confirmation before replacing a different existing license.
The same link can activate each listed installation; their counters remain
separate. The code remains sensitive: recipients and messaging apps can see or
retain the full link, and browser history and device software may retain it.

For Android, set the same host in both the `WEFAQ_LINK_HOST` environment
variable (manifest) and `--dart-define=WEFAQ_LINK_HOST=YOUR_HOST` (Dart), in
addition to the verification key. You must control that HTTPS host and publish
`/.well-known/assetlinks.json` with this app's package name and the SHA-256
fingerprint of the actual signing certificate. A placeholder domain cannot be
verified. Provide an installation/fallback page at `/activate` for users who
do not have the app; after installation they must reopen the original link.
The fragment is not sent to that page's server, but any page JavaScript can
read it: avoid analytics and third-party scripts there. Test verified links on
actual Android releases. iOS Universal Link entitlements and association files
are not implemented yet.

An operator-side tool issues one signed code for an explicit list of installation
IDs and a duration, session quota, or both. The operator chooses the permitted
devices when issuing the code; there is no fixed two-device limit. Each listed
installation can use the same code and verify its signature and its own ID
offline. A quota is a separate allowance on each installation, not a shared
balance: a 20-session code for two devices allows up to 20 sessions on each.
Starting and continuing sessions do not require an activation server. The
public verification key ships in the app; signing keys stay outside the
repository and app. The app must never be the issuer of its own licenses.
Reinstallation or loss of secure storage may change the installation ID and
require a recovery process; behavior differs by platform.
Local verification cannot prevent a modified app, local clock rollback, or
rollback of device storage, and offline codes cannot be revoked remotely until
the app checks a trusted online source. Activating the same code again must not
reset the locally consumed quota. These restrictions need to be made clear
before the feature is sold.

Never silently discard an existing saved session if the license expires, an
update fails, the device restarts, or the server cannot be reached. Specify
expiry boundaries, user-visible errors, duplicate activation, device
replacement, revocation, backups, key rotation and recovery before enabling paid
access. Store the activation credential in platform secure storage; avoid
logging credentials, installation IDs, answers, or other personal data.

## Initial online services

1. Authenticated content manifest and versioned catalog download, with caching.
2. Optional opt-in backup or synchronization, only after an explicit privacy
   design; conversation answers should not be uploaded by default.

## Release gates

Complete expert review of all published questions and activities; test catalog
upgrades and recovery, quota consumption and replay, network failures, device
replacement, expiry and purchases; verify signed release builds on Android and
iOS; obtain legal and privacy review; and review current store rules before
store distribution. Do not market draft materials as reviewed or the DISC
exercise as an official validated assessment.
