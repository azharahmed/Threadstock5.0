# ThreadStock Architecture

## 1. Architecture goals

ThreadStock must support a boutique with one phone and a multinational fashion business with many stores without creating two products. The architecture therefore prioritizes:

- multi-tenant isolation;
- multi-location inventory correctness;
- offline-tolerant operations;
- auditable stock and money movement;
- progressive feature complexity;
- shared domain behavior across Android, iOS, Windows and macOS;
- AI that can prepare real actions safely;
- testability and replaceable infrastructure adapters.

## 2. Recommended stack

### Client

- Flutter: one codebase, adaptive presentation.
- State/DI: Riverpod-style provider architecture with explicit controller/view-model state. Do not hide business workflows in widget state.
- Routing: typed route definitions with guards and canonical paths from [ROUTE_MANIFEST.md](ROUTE_MANIFEST.md).
- Local persistence: relational SQLite/Drift-style local database for cache, outbox and offline read models.
- Secure storage: platform secure storage for session/device-sensitive tokens only.
- Scanner/camera, printing and share functionality behind platform adapters.

### Backend

- Supabase Auth for identity/session lifecycle.
- Postgres for authoritative operational data.
- RLS for tenant/location/role enforcement.
- Storage for product images, documents and approved attachments.
- Realtime only where it improves operational freshness; do not depend on realtime for correctness.
- Edge Functions/server services for privileged integrations, AI gateway, webhooks and secret-bearing operations.
- Postgres RPC/functions for atomic business operations such as sale completion, receiving, transfer state transitions and stock reconciliation.

## 3. Repository shape

```text
threadstock/
  lib/
    app/
      bootstrap/
      router/
      shell/
      l10n/
    core/
      auth/
      errors/
      logging/
      connectivity/
      sync/
      permissions/
      platform/
    design_system/
      tokens/
      components/
      responsive/
    domain_shared/
      money/
      quantity/
      identifiers/
      pagination/
    features/
      overview/
      inventory/
      sales/
      purchasing/
      transfers/
      ai_studio/
      automations/
      insights/
      settings/
      onboarding/
      global_search/
      approvals/
      notifications/
  supabase/
    migrations/
    functions/
    tests/
    seed/
  test/
  integration_test/
  docs/
  tools/
  .cursor/rules/
  .agents/rules/
  .github/instructions/
```

Start as a single Flutter application with feature boundaries. Split internal packages only when a boundary has proven independent build/test/versioning value. Avoid premature package fragmentation.

## 4. Feature layering

Each feature can use:

```text
presentation -> domain -> repository interface -> data adapter -> Supabase/local store
```

Rules:

- Presentation depends on domain, not Supabase DTOs.
- Domain never imports Flutter widgets.
- Data adapters translate external schemas into domain models.
- Domain services own business rules that cross simple entity methods.
- Controllers coordinate UI state and use cases, but do not become god objects.

## 5. Multi-tenant hierarchy

Canonical scope:

`business -> locations -> operational records`

A user accesses a business through a membership. Membership maps to one or more roles/scopes. A role contains permissions. Location restrictions are additive to permission rules.

Important: `business_id` is part of every operational aggregate or is derivable through an immutable foreign-key chain. Never trust a client-supplied business ID without server validation.

## 6. Inventory architecture

Use two concepts:

1. `inventory_ledger`: append-only events explaining why quantity changed.
2. `inventory_balance`: materialized/current balance optimized for reads.

Every stock-changing transaction must write the ledger and update/recompute balances atomically. The balance is never the only audit evidence.

Recommended balance dimensions:

- business_id
- location_id
- variant_id
- available_qty
- committed_qty
- incoming_qty (may be derived from open supply/transfer records)
- damaged_qty
- version

Avoid a single ambiguous `quantity` column for all business meaning.

## 7. Transaction boundaries

Use server-side transactional operations for:

- complete sale;
- refund/return that changes stock and payment records;
- receive purchase order;
- dispatch transfer;
- receive transfer;
- approve stock-count reconciliation;
- create a purchase order from an AI proposal;
- execute automation-created actions.

Each command accepts an idempotency/client operation key and returns the canonical server result.

## 8. Offline architecture

Offline capability should be selective, not pretend-everything-is-offline.

Safe candidates:

- catalog lookup from cache;
- barcode lookup if cached;
- draft sale or configured offline sale;
- stock count capture;
- receiving capture where policy allows;
- notes/drafts.

Server-authoritative or connection-required candidates may include high-risk approvals, integration changes, role changes and actions requiring fresh financial state.

### Outbox

Queued operations are immutable envelopes. On sync, the server either:

- accepts exactly once;
- returns already-processed canonical result;
- rejects with a business conflict;
- rejects with authorization/session error.

Do not retry destructive operations without idempotency.

## 9. Routing architecture

Use one canonical route vocabulary from [ROUTE_MANIFEST.md](ROUTE_MANIFEST.md). Desktop and mobile can render different pages/shells for the same domain destination. Avoid parallel route trees such as `/desktop/inventory` and `/mobile/inventory` unless a platform-only workflow truly requires it.

Route guards run in this order:

1. app bootstrap/environment valid;
2. authenticated session;
3. active business membership;
4. onboarding/business setup state;
5. required permission;
6. required location scope;
7. feature flag/capability if applicable.

## 10. AI architecture

AI client UI talks to a ThreadStock AI gateway, not directly to model providers with privileged keys.

```text
Flutter -> AI Gateway -> policy/context builder -> model/tool orchestration
                                     -> read tools
                                     -> proposal tools
                                     -> approved execution tools
```

AI reads are scoped to the actor. Write-like tool calls create proposals unless a configured safe automation permits execution. See [AI_SYSTEM.md](AI_SYSTEM.md).

## 11. Integration architecture

External channels (Shopify, accounting, payments, shipping) are adapters. Store:

- integration connection metadata;
- encrypted/secret credentials server-side;
- sync cursor/checkpoints;
- external-to-internal ID mapping;
- last success/error;
- webhook delivery/audit.

Never model an external platform's schema as the internal ThreadStock domain model.

## 12. Design system architecture

Keep a shared Flutter design system with semantic tokens, not feature-specific hex values. Use adaptive components where behavior differs by platform:

- desktop data table vs mobile entity list;
- desktop right inspector vs mobile bottom sheet/page;
- desktop sidebar vs mobile bottom navigation;
- desktop hover/focus vs mobile press/haptic states.

See [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

## 13. Observability

Track business operation outcomes with correlation IDs. Key events include:

- auth/session failures;
- sync conflicts;
- sale completion/refund;
- receiving/transfer transitions;
- stock reconciliation;
- AI proposal lifecycle;
- automation runs;
- integration sync failures.

Separate developer diagnostics from user-visible error copy.

## 14. Environments

Recommended:

- local development;
- staging;
- production.

Each has separate Supabase projects/credentials and storage. Never use production service-role secrets locally. Migrations promote in sequence and are applied by controlled tooling/CI, not ad hoc UI edits.

## 15. Architectural decision rule

When uncertain, optimize in this order:

1. correctness of stock/money/security;
2. user workflow clarity;
3. auditability and recoverability;
4. maintainability/testability;
5. performance;
6. cleverness.
