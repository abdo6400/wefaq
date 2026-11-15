# ADR 0003: Local Favorites and Session Question Anti-Repetition

## Status
Accepted (Phase P2 Baseline)

## Context
Engaged couples frequently encounter questions during a session that prompt deep discussion and wish to revisit or reflect on later. Furthermore, users running multiple sessions within the same topic should not receive the exact same questions repeatedly while unasked questions remain available in the pool.

The production plan mandates:
1. **Zero Text Capture**: Favorites must strictly persist question IDs and bookmark timestamps, never user responses or notes.
2. **Local Isolation**: Favorites remain local to the device unless a separately reviewed cloud synchronization mechanism is approved.
3. **Content Withdrawal Handling**: If a question in the favorites list is withdrawn or deleted, it must gracefully disappear from the favorites view without breaking the app.
4. **Anti-Repetition Cycling**: When selecting questions for a session, questions not seen in recent sessions must take precedence. When all questions in a category have been asked, the cycle resets gracefully rather than causing an error.

## Decision

### 1. Local Favorites (`FavoriteItem` and `FavoritesStorage`)
- Minimal storage schema: `questionId` (string) and `savedAt` (UTC timestamp).
- Persisted via `FileFavoritesStorage` with atomic file writes, alongside `InMemoryFavoritesStorage` for testing.
- When viewing favorites, question IDs are hydrated against `QuestionRepository`. Any withdrawn/unknown question IDs are omitted.
- Users can toggle the bookmark state directly on the question card during a session or unbookmark from the favorites screen.

### 2. Anti-Repetition Tracking (`QuestionHistoryTracker`)
- Maintains a sliding window of recent question IDs per topic/depth.
- `QuestionRepository.queryQuestions` accepts `excludeQuestionIds: Set<String>`.
- If the remaining unseen questions are fewer than the requested session count, the repository draws the remaining unseen questions and supplements with the oldest questions from history, ensuring the session always starts with the requested question count.

## Consequences
- **Positive**: Couples can bookmark meaningful conversation topics for later reflection without privacy risk.
- **Positive**: Sessions feel progressive and varied instead of random repeats.
- **Negative**: Favorites are tied to the local device storage and will be cleared if the user uninstalls the app (clearly communicated in UI).
