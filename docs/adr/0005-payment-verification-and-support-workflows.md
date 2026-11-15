# ADR 0005: Distribution Channels, Payment Settlement, and Support Workflows

## Status
Accepted

## Context
Wefaq's commercial roadmap (P4) targets engaged couples primarily in Egypt. The production plan mandates:
1. **Store & Distribution Policy Compliance**: Google Play requires Google Play Billing for in-app digital purchases unless qualifying under specific policies (e.g., consumption-only or external sales with policy review). Direct web-based sales, WhatsApp concierge orders, and manual payment verification (InstaPay, Vodafone Cash, Fawry) require clear legal, consumer-protection, and accounting boundaries.
2. **Order Verification vs Payment Claims**: Screenshots or user assertions of payment are not settlement proofs. Human operators or automated webhooks must independently reconcile payment transactions against merchant bank/wallet statements before issuing activation codes.
3. **Privacy-Preserving Concierge Communication**: WhatsApp order preparation must never transmit user conversation logs, answers, or private notes. Only the random `installation_id`, chosen plan SKU, and contact handle are processed.
4. **Device Replacement & Support Runbooks**: Engaged individuals may lose or replace devices. An auditable, authorized procedure must allow replacing an occupied slot (`Slot 1` or `Slot 2`) without allowing unbounded code sharing.
5. **Consumer Disclosures**: Egyptian consumer protection laws (Law 181/2018) and data protection laws (Law 151/2020) mandate transparent pricing, clear refund terms, support hours, and lawful processing notices.

## Decision

### 1. Concierge WhatsApp Order Flow
- The mobile app and marketing website provide a structured order preparation interface.
- The order payload is presented to the user for explicit confirmation before opening the external communication channel:
  ```text
  السلام عليكم، أود الاشتراك في باقة وفاق:
  - الباقة: باقة وفاق للمخطوبين (جهازين)
  - كود التثبيت: inst_xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx
  - وسيلة الدفع المفضلة: (إنستاباي / محفظة إلكترونية)
  ```
- Opening WhatsApp initiates contact; settlement is completed externally, and a high-entropy activation code (`WFQ-XXXX-XXXX`) is delivered back to the user.

### 2. Operator Administration Workflow
- An administrative tool/console allows verified staff to:
  - Generate cryptographically secure activation codes tied to specific plans and slot limits (default: 2 slots).
  - Search and inspect slot bindings (`Slot 1` and `Slot 2`).
  - Perform slot revocation and authorized replacement upon verified user request with an audit log.
  - Review transaction reconciliation logs.

### 3. In-App Support and Help Center
- Deliver a dedicated `SupportScreen` and `HelpSheet` containing:
  - Frequently Asked Questions (FAQ) regarding privacy, phone mode usage, and subscription terms.
  - One-tap copyable installation ID for customer service assistance.
  - Customer support contact hours and WhatsApp direct link.
  - Transparent privacy policy and legal disclaimers.

## Consequences
- **Positive**: Complies with Egyptian e-commerce disclosures and data privacy laws.
- **Positive**: Zero risk of fraudulent activation from unverified payment screenshots.
- **Positive**: Clean separation between payment settlement and in-app entitlement activation.
- **Operational Requirement**: Customer service team must maintain standard operating procedures and response times during business hours.
