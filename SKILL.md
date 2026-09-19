---
name: threadstock-engineering
description: Use this skill for ThreadStock feature work, inventory logic, Supabase schema changes, permissions, AI actions, or release validation in this Flutter + Supabase project.
---

# ThreadStock engineering skill

Use this skill when implementing or reviewing work in the ThreadStock workspace. It packages the project’s core workflow, technical guardrails, and completion criteria.

## When to use this skill

Apply this skill for:

- new Flutter screens, routes, or feature flows;
- inventory, sales, purchasing, transfer, or stock logic;
- Supabase/Postgres schema, RLS, RPC, or migration changes;
- permission checks or authorization logic;
- AI proposal, approval, or execution workflows;
- bug fixes that affect stock, money, permissions, or route integrity;
- release checks before marking a task done.

## Read-first workflow

Before changing code, read the relevant project documents in this order:

1. `Documents/ARCHITECTURE.md`
2. `Documents/PRODUCT_BLUEPRINT.md`
3. `Documents/ROUTE_MANIFEST.md`
4. `Documents/BEHAVIOR_SPEC.md`
5. `Documents/DESIGN_SYSTEM.md`
6. `Documents/SECURITY.md`
7. Add `Documents/DATA_MODEL.md` for data or schema work.
8. Add `Documents/AI_SYSTEM.md` for AI-related changes.
9. Add `Documents/TESTING_STRATEGY.md` for validation work.

If a task is outside the obvious scope, identify the smallest relevant subset instead of reading everything indiscriminately.

## Implementation workflow

1. Define the user and business context
   - Identify the actor, role, route, and canonical entry point.
   - Clarify the happy path and exit path.
   - Capture required empty, loading, error, permission, and offline states.

2. Map the business rules
   - For inventory work, treat quantity as ledger-derived, not directly mutated.
   - For money-sensitive flows, prefer a single server-side transaction/RPC when multiple records are affected.
   - If AI can change business state, enforce the `detected -> proposed -> prepared -> awaiting_approval -> approved -> executing -> completed` lifecycle.

3. Choose the correct architecture
   - Use feature-first Flutter structure with `presentation`, `domain`, and `data` separation.
   - Keep business logic out of widgets.
   - Put Supabase details in data adapters and keep domain boundaries typed.
   - Preserve typed routes and route guards.

4. Implement with product and security boundaries in mind
   - Keep inventory semantics explicit: available, committed, incoming, and damaged.
   - Use RLS, RPCs, and server enforcement for authorization boundaries.
   - For UI visibility, use checks as convenience only; do not rely on them as the security boundary.
   - Respect the app’s adaptive layout expectations: phone, tablet, and desktop flows are intentionally different.

5. Validate the change
   - Run relevant tests for the changed behavior, including domain and repository or adapter coverage.
   - Check empty/error/permission states where user-facing logic changed.
   - Validate light and dark themes when UI changes affect presentation.
   - Verify route continuity and no dead-end navigation.
   - For schema changes, document migration impact and rollback implications.

## Decision rules and guardrails

### Product rules
- Preserve progressive complexity: simple business flows stay simple while advanced functions appear only when enabled or permitted.
- Do not implement a screen without a real operational exit path.
- Favor concise, operational product copy over inflated technical language.

### Architecture rules
- Use feature-first organization and keep reusable primitives in design system code.
- Do not pass untyped maps through the UI layer.
- Use immutable typed models and business-safe operations.

### Inventory and accounting rules
- Inventory must be ledger-driven.
- Never conflate stock semantics or bypass the inventory event model.
- Use append-only audit records for sensitive inventory and financial situations.

### Data and security rules
- Treat tenant and location boundaries as hard boundaries.
- Enforce authorization at the UI, domain/service, and server layers.
- Never expose service-role credentials in the Flutter app.
- Audit business-critical writes with actor, scope, before/after context, and source metadata.

### AI rules
- AI is operational intelligence, not a decorative assistant.
- AI-generated actions must reference source data, permission scope, and an auditable proposal ID.
- AI may propose, prepare, and explain, but execution must follow approval and permission rules.

### Testing rules
- Prioritize tests around money, stock, and permission boundaries.
- Minimum for meaningful feature work:
  - domain unit tests;
  - repository/data adapter tests;
  - widget tests for core states;
  - an integration test for the critical user journey;
  - SQL/RLS tests if data access changes.

## Completion checklist

Only mark the task complete when all applicable checks pass:

- The change follows the project architecture and route conventions.
- The required product states and exit paths are implemented.
- Inventory or financial logic is ledger-safe and auditable.
- Authorization is enforced at the server boundary.
- AI, if used, follows the proposal and approval lifecycle.
- Relevant tests pass, including permission-denied and empty/error states.
- The UI was checked for the relevant layout modes and theme variations.
- No placeholder interactions or dead ends remain.
- Schema changes include migration and rollback implications.

## Example prompts for this skill

- “Review this ThreadStock feature against the product and security rules before I implement it.”
- “Design the domain and data structure for a new inventory receiving flow.”
- “Implement the route, state handling, and permission checks for a stock transfer screen.”
- “Audit this AI workflow for approval, auditability, and scope safety.”
- “Add or update tests for a new inventory rule and verify the edge states.”

## Related customizations to create next

- A `product-feature` skill for user story discovery and acceptance criteria.
- A `supabase-guardrails` skill for migration, RLS, and database review checks.
- An `ai-operations` skill focused specifically on proposal, approval, and audit flows.
- A `release-readiness` skill for final validation, regression checks, and deployment review.
