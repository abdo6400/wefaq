# Wefaq Content Review Standards, Editorial Guidelines & Ethical Framework

**Date:** 12 November 2026  
**Document Class:** Editorial & Review Governance  
**Target Market:** Egypt and Arabic-speaking communities  
**Intended Stage:** Pre-Marital Engagement (الخطوبة والاستعداد للزواج)  
**Target Audience:** Consenting adults 18+

---

## 1. Guiding Principles and Philosophy

Wefaq is designed to facilitate calm, respectful, and meaningful conversations between engaged partners. It is built upon the following non-negotiable principles:

1. **Facilitation, Not Prescription:** Wefaq provides safe conversation starters. It does not dictate how couples should organize their lives, make decisions, or divide responsibilities.
2. **Voluntary Participation & Right to Skip:** Every question is entirely optional. Both partners have the absolute right to skip any question without justification or judgment.
3. **Absolute Privacy:** The application does not collect, record, transcribe, or analyze answers. Questions are prompts for spoken human interaction.
4. **Cultural and Contextual Resonance:** The language must be warm, natural Egyptian Arabic that feels authentic, respectful, and dignified.

---

## 2. Red Lines and Prohibited Content

The following categories are strictly prohibited from all Wefaq question banks and activities:

| Category | Prohibition Definition | Rationale |
|---|---|---|
| **Intimate Physical Details** | Any question probing sexual past, intimate physical preferences, or bodily matters. | Inappropriate during engagement; violates Islamic propriety and psychological safety. |
| **Religious Edicts (Fatwas)** | Any question implying an absolute religious obligation, sin, or legalistic ruling without qualification. | Wefaq is not a mufti or theological authority. Legal and religious rulings belong to certified scholars. |
| **Prying into Family Secrets** | Questions asking a partner to disclose confidential family disputes, inheritance feuds, or private parents' affairs. | Undermines family loyalty and introduces premature friction before marriage. |
| **Coercive Tests & Loyalty Pledges** | "Hypothetical loyalty tests" (e.g. "If your mother and I disagree, whose side will you take?"). | Fosters adversarial thinking instead of mature, empathetic problem-solving. |
| **Financial Interrogation** | Demanding exact bank account balances, PINs, or intrusive asset audits. | Premature and invasive; focus instead on general attitudes toward budgeting, saving, and transparency. |

---

## 3. Review Lifecycle and Stage Gates

Every published question must pass through an immutable five-stage review pipeline before reaching end-user devices:

```mermaid
flowchart LR
  Draft[1. Draft Generation] --> Editorial[2. Editorial & Language Check]
  Editorial --> Family[3. Family Counseling Review]
  Family --> Religious[4. Religious Alignment Review]
  Religious --> Published[5. Approved & Published]
  Published --> Quarantine[Quarantine / Retirement]
```

### Stage 1: Draft Generation
- Drafted by licensed family counselors, relationship educators, or approved creative contributors.
- Must include: Unique opaque ID, Question Text, Clarification/Intent Text, Topic, Depth, and Suitable Modes.

### Stage 2: Editorial & Language Check
- Verifies Egyptian Arabic naturalness, Cairo font readability, sentence structure, and tone.
- Ensures absence of ambiguity, passive aggression, or accusatory phrasing.

### Stage 3: Family Counseling & Psychological Safety Review
- Conducted by certified marriage and family counselors.
- Verifies that the question encourages self-reflection, mutual empathy, and active listening.
- Assigns Depth: `introductory` (icebreakers, everyday habits) vs `deeper` (conflict styles, future vision).

### Stage 4: Religious Alignment Review (Islamic Ethics)
- Conducted by qualified specialists in Islamic jurisprudence and family ethics.
- Verifies harmony with the Islamic objectives of marriage (*Mawaddah* & *Rahmah* / مودّة ورحمة), respect for parental honor (*Birr al-Walidayn* / بر الوالدين), and pre-marital engagement boundaries (*Ahkam al-Khitbah* / أحكام الخطبة).

### Stage 5: Publication
- Exported to versioned release catalogs (`assets/content/questions_vX.json`).
- If approved content requires edits, the existing version is preserved and a new draft version is initiated.

---

## 4. Sensitivity Classification (S0–S3) and Quarantine Workflow

When a closed beta participant or user flags a question through the in-app feedback tool:

| Level | Severity | Action Trigger | Immediate Response |
|---|---|---|---|
| **S0** | **Critical Violation** | Question touches prohibited red lines (intimacy prying, religious error). | **Immediate Remote Quarantine:** Question excluded from server-synced catalogs and added to tombstone blocklist within 24 hours. |
| **S1** | **High Sensitivity** | Question triggers significant distress or relationship conflict during testing. | Referral to Review Panel for rewording or retirement in next minor update. |
| **S2** | **Phrasing Ambiguity** | Question is confusing or misinterpreted by > 5% of beta participants. | Editorial revision of question text or clarification prompt. |
| **S3** | **Minor Polish** | Typo, dialect adjustment, or minor nuance enhancement. | Scheduled for next content batch release. |

---

## 5. Topic Definitions and Target Allocations

For the 300–500 pilot target:

| Topic Code | Domain Name (Arabic) | Focus Areas | Target Allocation |
|---|---|---|---|
| `communication` | **التواصل وإدارة الخلافات** | أساليب الاستماع، التعبير عن المشاعر، وقت التفكير، التعامل مع سوء الفهم، التقدير اليومي. | 25% |
| `dailyLife` | **الحياة اليومية والمسؤوليات** | تنظيم اليوم، إدارة الوقت، تقسيم أعباء المنزل، الترويح المشترك، الخصوصية والمساحة الشخصية. | 20% |
| `familyRelations` | **الأهل والحدود الأسرية** | بر الأهل، تنسيق الزيارات، استقلالية البيت، توازن العلاقات، التعامل الهادئ مع الاختلافات العائلية. | 20% |
| `finances` | **المالية والتطلعات المشتركة** | أسلوب الإنفاق، الادخار، ميزانية الطوارئ، الشفافية المالية، التطلعات الاستثمارية والقرارات الكبرى. | 20% |
| `coreValues` | **القيم والمبادئ والتربية** | الأهداف الكبرى في الحياة، معايير الثقة والصدق، التماسك الروحي في الأزمات، مبادئ تربية الأطفال. | 15% |
