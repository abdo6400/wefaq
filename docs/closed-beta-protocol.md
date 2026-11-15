# Wefaq Closed Beta Protocol and Evaluation Framework

**Date:** 12 November 2026  
**Target Market:** Egypt (Cairo and governorates)  
**Target Audience:** Consenting engaged adult couples (18+)  
**Sample Target:** 20–30 engaged couples (40–60 unique installation endpoints)

---

## 1. Objectives and Scope

The Closed Beta evaluates real-world couple dynamics, conversational pacing, question clarity, privacy assurance, and two-device concierge activation before wide storefront release.

### Core Objectives
1. **Dialogue Flow & Usability:** Evaluate whether questions foster constructive, respectful dialogue without fatigue, pressure, or discomfort.
2. **Privacy Trust:** Verify whether participants understand and trust that their discussions, answers, and notes are 100% private and never transmitted or recorded.
3. **Pacing & Navigation:** Ensure that skip, pause, resume, and favorites controls feel safe, intuitive, and non-coercive.
4. **Concierge Onboarding:** Test WhatsApp concierge communication, manual payment confirmation, 2-device activation codes, and slot replacement procedures under real-world conditions.
5. **Accessibility & Device Diversity:** Verify stability and readability on diverse Android hardware (Android 8.0 through Android 15, screen widths from 320px to 480px, font scaling 1.0x to 1.5x).

---

## 2. Ethical Safeguards and Privacy Pledge

### Uncompromising Privacy Invariant
- **ZERO Answer Collection:** Wefaq does **NOT** collect, record, log, or transmit any verbal answers, text responses, audio snippets, or ratings of answers.
- **Local State Only:** Favorites, anti-repetition history, and session resumption states remain stored exclusively on the user's device in sandboxed app files.
- **Voluntary & Non-Coercive Participation:** Either partner may skip any question or exit a session at any moment. Participation in the beta can be paused or withdrawn at any time without penalty.
- **Anonymous Feedback:** All feedback collected during beta sprints pertains solely to the **tool's usability, clarity, and technical reliability**—never marital secrets or conversation contents.

### Participant Informed Consent
Each participating couple signs a plain-language Egyptian Arabic consent form confirming:
1. They understand Wefaq is a conversational guide, not psychological therapy, legal counsel, or matchmaking.
2. The app does not save or transmit their conversation.
3. Their feedback on app UX, question wording, and technical performance will be used solely for product improvement.

---

## 3. Cohort Recruitment & Selection Matrix

| Demographic Dimension | Target Distribution | Rationale |
|---|---|---|
| **Age Range** | 18–24: 35%<br>25–32: 50%<br>33+: 15% | Reflects standard demographic patterns of marriage preparation in urban and semi-urban Egypt. |
| **Engagement Duration** | Early (0–3 months): 40%<br>Mid (3–9 months): 40%<br>Approaching Wedding (< 3 months): 20% | Tests question depth appropriateness across varying relationship maturity stages. |
| **Device Diversity** | Low-tier Android (320–360px): 30%<br>Mid-tier Android (Redmi, Samsung A-series): 50%<br>High-tier / iOS: 20% | Ensures performance on constrained memory and narrow viewports. |
| **Living Arrangements** | Same city (Together mode focused): 60%<br>Long-distance / Travel (Phone mode focused): 40% | Validates both in-person single-screen dialogue and remote external-call dialogue. |

---

## 4. Structured 4-Week Beta Sprint Roadmap

### Sprint 1 (Week 1): Onboarding & Together Mode
- **Focus:** First-run experience, privacy briefing, Together mode session setup (Topic: Communication & Daily Life).
- **Tasks for Couples:**
  - Complete at least two "Together" sessions (3–5 questions each).
  - Test question navigation: Previous, Next, and Skip.
  - Test session resumption after closing the app.
- **Feedback Collection:** End-of-week survey on readability, pacing, and perceived privacy comfort.

### Sprint 2 (Week 2): Phone Mode & Discussion Activities
- **Focus:** Phone mode alongside real external phone/WhatsApp calls; Discussion Scenarios.
- **Tasks for Couples:**
  - One partner opens Wefaq in Phone mode while on an external phone/voice call; reads questions aloud.
  - Complete at least one Discussion Scenario activity (`ActivityCard`).
  - Test the Favorites feature to mark meaningful questions.
- **Feedback Collection:** Evaluation of Phone mode notices, scenario conversation quality, and clarity of scenario prompts.

### Sprint 3 (Week 3): Concierge Commercial Flow & 2-Device Activation
- **Focus:** Simulated or live concierge WhatsApp purchase, license code delivery, Slot 1 and Slot 2 device binding.
- **Tasks for Couples:**
  - Partner A initiates support/concierge request from `SupportScreen` or landing page.
  - Operator issues a 2-slot beta activation code using `tool/license_manager.dart`.
  - Partner A activates their device (Slot 1 bound).
  - Partner B redeems the same code on their device (Slot 2 bound).
  - Verify that both devices show active status, slot indicators, and remaining shared session quota.
  - (Test cohort subset): Simulate device replacement to verify operator slot reallocation.
- **Feedback Collection:** Smoothness of code entry, error reporting clarity, and reassurance regarding device pairing.

### Sprint 4 (Week 4): Content Breadth & Exit Evaluation
- **Focus:** Expanded topics (Family, Finances, Values), anti-repetition validation, exit interviews.
- **Tasks for Couples:**
  - Run mixed-topic sessions; confirm that questions do not repeat excessively.
  - Submit final evaluation through in-app feedback modal.
- **Feedback Collection:** Comprehensive System Usability Scale (SUS) adapted for Arabic, Net Promoter Score (NPS), and qualitative feedback on question phrasing.

---

## 5. Issue Classification and Severity Rubric

| Severity | Definition | Target Resolution SLA |
|---|---|---|
| **P0 — Blocker** | App crashes, unrecoverable data corruption, privacy leak (any question text logged externally), or inability to activate license. | < 24 hours (hotfix deploy) |
| **P1 — Critical** | UI overflow on narrow screens (e.g. 320px), session state loss on backgrounding, or activation rejection on a legitimate 2nd device. | < 48 hours |
| **P2 — Major** | Confusing Arabic phrasing, awkward RTL alignment, unhandled network timeout during license check. | Next beta build (< 1 week) |
| **P3 — Minor** | Typo in explanation text, minor spacing inconsistency, non-blocking cosmetic animation glitch. | Scheduled release |
| **S0 — Sensitivity Flag** | A question perceived as intrusive, culturally inappropriate, coercive, or touching upon unwarranted intimate details. | Immediate quarantine and referral to religious/family review panel. |

---

## 6. Beta Exit Criteria (Gate to Public Production)

1. **Crash-Free Sessions:** > 99.5% crash-free sessions across all beta builds.
2. **Zero Privacy Violations:** 100% adherence to zero-answer capture invariant verified in audits.
3. **Usability Benchmark:** System Usability Scale (SUS) score > 80/100 across both partners.
4. **Content Comfort:** < 2% of completed questions flagged for sensitivity or uncomfortableness.
5. **Concierge Success Rate:** 100% successful activation of 2-device slots for legitimate couples without double-spend or unauthorized 3rd device penetration.
6. **Accessibility Compliance:** 0 text truncations or layout overflows at 320px viewport with 1.5x font scaling.
