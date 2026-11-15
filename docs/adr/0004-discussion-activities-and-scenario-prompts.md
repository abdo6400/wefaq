# ADR 0004: Lightweight Discussion Activities and Scenario Prompts

## Status
Accepted

## Context
Wefaq's mission is to facilitate meaningful, respectful dialogue between engaged couples. While direct questions (`Question`) form the core conversation foundation, couples also benefit from structured situational vignettes ("سيناريوهات للنقاش") and mutual priority reflections ("ترتيب أولويات مشتركة").

Section 4, 5, and P2 of `docs/production-plan.md` mandate strict boundaries for conversational activities:
1. **Zero Data Capture**: No typing, recording, ranking persistence, or answer logging. The app presents scenarios as conversational springboards for real-world spoken discussion.
2. **No Compatibility Scoring or Algorithmic Diagnosis**: The app must never rate, score, or declare "compatibility" between partners based on activity responses.
3. **Voluntary and Skippable**: Every activity must be skippable at any time without penalty or pressure.
4. **Cultural and Relational Sensitivity**: Content must adhere to respectful Egyptian/Arab family norms and require review before commercial release.
5. **Decoupled and Extensible**: Activities should follow the existing clean architecture pattern (domain models, repository interface, data source, and reusable presentation widgets).

## Decision

### 1. Activity Domain Model (`Activity`)
Each activity has:
- `id`: Stable alphanumeric identifier (e.g., `act_scenario_comm_01`).
- `type`: `ActivityType.scenario` (situational vignette with discussion questions) or `ActivityType.priorityOrdering` (items to compare and discuss).
- `topic`: Associated life domain (`Topic.communication`, `Topic.dailyLife`, etc.).
- `title`: Short descriptive heading in Arabic.
- `situation`: The context scenario or introduction.
- `prompts`: `List<String>` of guided reflection questions for partners to talk through together.
- `options`: `List<String>` of priority items (when `type == ActivityType.priorityOrdering`).
- `isDevelopmentOnly`: Boolean flag ensuring unreviewed prototype activities are never passed off as certified.

### 2. Repository Pattern (`ActivityRepository`)
- Follows the interface `ActivityRepository` with `getActivities({Topic? topic, ActivityType? type})` and `getActivityById(String id)`.
- Implemented as `InMemoryActivityRepository` with verified prototype activities, with future support for versioned JSON loading (`assets/content/activities_v1.json`).

### 3. Presentation Layer
- `ActivityCard`: High-contrast, card widget adhering to the Wefaq design system (`AppColors`, `AppSpacing`, Cairo font, RTL semantics).
- Distinct visual badge ("نشاط تفاعلي" / "سيناريو للنقاش" / "ترتيب أولويات") to clearly differentiate activities from standard questions.
- Accessible touch targets (minimum 48x48 px), responsive to small screens (320px) and 1.5x text scaling.

## Consequences
- Couples can explore both direct questions and realistic everyday scenarios.
- Complete adherence to user privacy: no spoken or typed data is ever stored on the device or transmitted to a backend.
- Extensible schema ready for content authoring and future content synchronization.
