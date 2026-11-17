# Questions API contract (proposed v1)

The client implements this proposed contract. A separate NestJS implementation
exists in `backend/` and is configured via `WEFAQ_QUESTIONS_API_URL` in the
root `.env` file (which can also be overridden with
`--dart-define=WEFAQ_QUESTIONS_API_URL=https://example.com/v1/question-catalog`).
Without it, the update control is disabled and bundled/offline content works.
The endpoint serves a complete catalog snapshot, not individual diffs.
It differs from the currently bundled JSON, whose `version` field describes
the schema and which has no `revision`; the client integration must explicitly
map the bundled format and must not treat its schema version as a revision.

`GET /v1/question-catalog` over HTTPS, with `Accept: application/json`. If the
client has the server's ETag, it sends `If-None-Match` on later requests.
No installation ID, activation code, answers, or other personal data is needed.

**200 OK** returns UTF-8 JSON and an `ETag`. Example (shortened to one item):

```json
{
  "schemaVersion": 1,
  "revision": 42,
  "publishedAt": "2026-11-15T12:00:00Z",
  "questions": [
    {
      "id": "comm-intro-1",
      "text": "إيه اللي بيساعدك تتكلم براحة عن يومك؟",
      "clarification": "الهدف معرفة أسلوب الاستماع والتواصل المفضل.",
      "topic": "communication",
      "depth": "introductory",
      "suitableModes": ["together", "phone"],
      "isDevelopmentOnly": false
    }
  ]
}
```

- `schemaVersion` is the integer schema version, currently 1. `revision` is a
  positive, monotonically increasing integer for each published snapshot.
- `publishedAt` is an RFC 3339 UTC timestamp. `questions` must be nonempty.
- `id` is a unique stable identifier. An ID must never be reused for a different
  question; keep IDs referenced by saved sessions and favorites available or
  provide an explicit migration/retirement mechanism before removing them.
- `text` is nonempty. `clarification` is optional. `topic` is one of
  `communication`, `dailyLife`, `familyRelations`, `finances`, `coreValues`;
  `depth` is `introductory` or `deeper`; `suitableModes` is a nonempty array of
  `together` and/or `phone`. `isDevelopmentOnly` is a required boolean; set it
  to false only after documented expert approval of that item.
- The server increments `revision` whenever published content changes and must
  never serve different content with the same revision. ETags are opaque HTTP
  cache validators, not signatures or security credentials.

**304 Not Modified** has no body and leaves the cache untouched. Network errors,
timeouts, malformed JSON, unknown schema/enums, duplicate IDs, unapproved
content for a production catalog, oversized responses, non-increasing revisions
or incomplete snapshots must not replace the last validated catalog. The client
uses its bundled catalog when no validated cache exists and reports update
failures without blocking offline use. Validate an entire download before an
atomic replacement; preserve old data until replacement succeeds. Apply a
bounded response size and timeout in the client.

The current client rejects snapshots that omit any ID in the previous snapshot
(or the bundled catalog on first update), rather than silently breaking saved
references. It rejects all `isDevelopmentOnly: true` items in downloads. A
corrupt cache is retained for recovery and blocks replacement until resolved.
The UI also refuses to update while an unfinished session is saved. After a
successful update the in-process cache is invalidated and future sessions and
favorites use the new catalog. There is no automatic background refresh.

TLS and server authorization protect the publishing path. Use an authenticated
release manifest or signature if content must remain verifiable after it leaves
the server; key distribution and rotation must be designed before relying on
that property. This contract does not implement session synchronization,
licensing, tracking, or an admin interface.
