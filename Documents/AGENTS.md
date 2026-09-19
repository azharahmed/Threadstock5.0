# ThreadStock Agent Instructions

You are working on **ThreadStock**, an AI-powered fashion inventory and commerce OS built with Flutter and Supabase for Android, iOS, Windows and macOS.

## Read order before coding

For any non-trivial task, read the relevant sections of:

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [PRODUCT_BLUEPRINT.md](PRODUCT_BLUEPRINT.md)
- [ROUTE_MANIFEST.md](ROUTE_MANIFEST.md)
- [BEHAVIOR_SPEC.md](BEHAVIOR_SPEC.md)
- [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)
- [SECURITY.md](SECURITY.md)

For data changes, also read [DATA_MODEL.md](DATA_MODEL.md). For AI changes, also read [AI_SYSTEM.md](AI_SYSTEM.md). For tests, read [TESTING_STRATEGY.md](TESTING_STRATEGY.md).

## Product behavior

ThreadStock serves a single boutique through multi-location enterprise fashion operations. Preserve progressive complexity: small businesses should see a simple product, while advanced modules appear only when enabled or permitted.

The top-level desktop product domains are:

`Overview -> Inventory -> Sales -> Purchasing -> Transfers -> AI Studio -> Automations -> Insights -> Settings`

Mobile primary navigation is:

`Home -> Inventory -> Scan -> Sales -> AI`

Secondary mobile modules live under More/contextual entry points; do not reproduce the desktop sidebar on phones.

## Architecture rules

- Use feature-first Flutter architecture with presentation/domain/data separation inside each feature.
- Keep business rules outside widgets.
- Use repositories/interfaces at domain boundaries; Supabase details stay in data adapters.
- Use immutable typed models. Do not pass untyped maps through the UI layer.
- Use typed routes and route guards.
- All writes that affect stock, money, permissions or AI actions must be idempotent and auditable.
- Inventory is ledger-driven. Never mutate a stock balance without a corresponding inventory ledger event.
- Prefer a single transaction/RPC for multi-record business operations.

## UX rules

- Use the approved ThreadStock design system. Do not invent a new theme per feature.
- Light theme: warm ivory, graphite typography, restrained champagne accent.
- Dark theme: warm near-black, graphite surfaces, warm off-white text, muted champagne accent.
- Avoid generic dashboard card grids. Use hierarchy and spacing first.
- Fashion imagery, color, size, collection and season are first-class concepts.
- Mobile tasks must be optimized for scanning, selling, receiving, counting and transferring.
- Desktop tasks must support keyboard use, bulk actions, tables and contextual inspectors.

## AI rules

- AI is system intelligence, not a decorative chatbot.
- AI may detect, explain, recommend and prepare. Execution follows permission/approval rules.
- Show What, Why, Impact, Confidence (when meaningful) and Action.
- Never fabricate confidence precision.
- Model secrets and privileged tools live server-side only.
- AI-generated actions must reference source data, permission scope and an auditable proposal ID.

## Security rules

- Treat business/tenant boundaries as hard security boundaries.
- Enforce authorization server-side with Supabase RLS/RPC/Edge Functions; UI checks are only convenience.
- Never expose service-role credentials in the Flutter app.
- Validate business_id/location_id ownership on every privileged write.
- Sensitive actions require re-authentication or approval when configured.
- Audit who/what/when/where/before/after/source for important changes.

## Quality rules

Before declaring a task complete:

1. Format and analyze the Flutter code.
2. Run relevant unit/widget/integration tests.
3. Test permission-denied and empty/error states.
4. Verify light/dark theme where UI changed.
5. Verify phone + desktop layout where shared components changed.
6. Verify no route dead ends.
7. Verify no placeholder interaction remains.
8. Document migrations and rollback implications for schema changes.

Do not merge architecture refactors into unrelated feature tasks unless required to keep correctness.
