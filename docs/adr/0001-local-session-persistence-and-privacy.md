# ADR 0001: Local Session Persistence, Interruption Handling, and Privacy Safeguards

## Status
Accepted (Phase P1 / P2 Baseline)

## Context
Wefaq assists engaged couples in having structured, respectful discussions. In the initial prototype, `SessionProgress` resided solely in-memory; terminating the app or receiving an incoming phone call during phone mode immediately discarded progress.

The production plan requires a safe resumption mechanism for interrupted sessions while strictly adhering to privacy guarantees:
1. **Zero Answer Capture**: Under no circumstances should user answers, conversation transcripts, notes, or audio be recorded or stored.
2. **Resilience to Interruption**: Process termination, incoming phone calls, low battery shutdowns, or accidental app closures should not result in lost session context.
3. **Transparent Lifecycle**: Users must retain explicit control over whether to resume or discard an interrupted session. Completed or explicitly exited sessions must not linger.
4. **Content Withdrawal Safety**: If an active session references a question ID that is later retired or withdrawn, resumption must degrade gracefully without crashing.
5. **Storage Security & Fault Tolerance**: Storage corruption or malformed payloads must never prevent app launch or cause unrecoverable crashes.

## Decision
We implement a decoupled, privacy-first local persistence layer:

### 1. Data Contract (`SavedSessionState`)
Only minimal, non-sensitive session coordinates are persisted:
- `version`: Integer schema version (starting at `1`) for future migration safety.
- `sessionId`: Unique UUID / string identifier.
- `questionIds`: Ordered list of stable question IDs (`comm-intro-1`, etc.).
- `mode`: Conversation mode (`together` | `phone`).
- `currentIndex`: Zero-based index of the active card.
- `skippedIndices`: Set of card indices that the user marked as skipped.
- `updatedAt`: ISO-8601 UTC timestamp.

**Explicitly Excluded:**
- No text answers.
- No audio recordings or voice transcripts.
- No user identity, names, or device fingerprints.

### 2. Storage Abstraction (`SessionStorage`)
- An abstract interface `SessionStorage` defining `readActiveSession()`, `writeActiveSession()`, and `clearActiveSession()`.
- Implemented via `FileSessionStorage` with atomic writes (write-to-temporary-file then rename) to prevent partial write corruption.
- Accompanied by `InMemorySessionStorage` for deterministic unit testing.

### 3. Fault Tolerance & Interruption Rules
- **Corrupted / Invalid JSON**: Logged safely, discarded without crashing the app, returning `null`.
- **Withdrawn / Missing Questions**: When hydrating `SavedSessionState`, question IDs are cross-referenced with `QuestionRepository`. If questions have been removed or withdrawn, the missing items are safely pruned and index is re-clamped.
- **Completion / Explicit Exit**: When a session reaches completion or the user confirms "إنهاء الجلسة" in the exit dialog, `clearActiveSession()` is invoked immediately.
- **Interruption Prompt**: If a valid incomplete session exists on app launch, `HomeScreen` surfaces a clear card allowing the user to either:
  1. **Resume Session**: Navigates straight to the active question with intact history and mode.
  2. **Discard Session**: Clears storage immediately with user confirmation.

## Consequences
- **Positive**: Couples can safely take calls, switch apps, or handle interruptions without losing their discussion progress.
- **Positive**: Strict privacy posture maintained: no personal content or answers are ever stored.
- **Negative**: Questions must have immutable, stable IDs to support resumption across app updates.
