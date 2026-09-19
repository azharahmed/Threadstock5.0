# ThreadStock Engineering Skills

This file defines the specialist capabilities an AI coding agent should apply when implementing ThreadStock. A task can require multiple skills; choose the smallest set that safely completes the work.

## 1. Product workflow skill

Use for any user-facing feature. Before coding, identify:

- actor and role;
- starting page and canonical route;
- happy path;
- empty/loading/error/permission/offline states;
- audit consequence;
- mobile versus desktop presentation;
- completion signal and next action.

Never implement a screen without its operational exit path.

## 2. Flutter feature skill

Use feature-first structure:

```text
lib/features/<feature>/
  data/
    datasources/
    dto/
    repositories/
  domain/
    entities/
    repositories/
    services/
    usecases/
  presentation/
    controllers/
    pages/
    widgets/
```

Keep reusable design primitives in `lib/design_system/`, not copied into features.

## 3. Responsive/adaptive UI skill

ThreadStock uses intentional layouts, not scaled layouts.

- Phone: task-first lists, bottom sheets, bottom navigation, scanner-centric flows.
- Tablet: adaptive navigation and split views when useful.
- Desktop: sidebar, tables, keyboard shortcuts, bulk action bar, right inspector.
- Preserve user context when moving between list/detail/actions.

## 4. Supabase/Postgres skill

Use Postgres as the system of record. Prefer:

- relational constraints;
- foreign keys;
- transaction-safe RPCs for multi-table operations;
- RLS for tenant and role boundaries;
- append-only audit/ledger records for inventory and sensitive changes;
- database timestamps as authoritative server time.

Never let the client assemble a financially or inventory-sensitive multi-step transaction using unrelated writes when the database can perform it atomically.

## 5. Inventory accounting skill

Inventory quantity is derived from a ledger of business events. Typical event types:

- opening_balance
- purchase_receipt
- sale
- sale_return
- transfer_dispatch
- transfer_receive
- stock_adjustment
- stock_count_reconciliation
- supplier_return

Maintain available, committed, incoming and damaged semantics explicitly. Never conflate them.

## 6. Offline/sync skill

Use a local relational store for cached read models and an outbox for permitted offline writes.

Each queued mutation needs:

- client_operation_id UUID;
- business_id and location scope;
- entity type and operation;
- payload version;
- created_at_local;
- retry count/status;
- server result/version when synced.

Never silently resolve stock conflicts. Surface business-readable conflict context.

## 7. AI workflow skill

AI output that can cause a business change follows:

`detected -> proposed -> prepared -> awaiting_approval -> approved -> executing -> completed`

Alternate terminal states:

`rejected | failed | cancelled | expired`

AI can use tools only within the actor's permission and business/location scope. Store proposal inputs, model/tool version metadata, structured output and final human/action outcome.

## 8. Authorization skill

Permission checks exist at three layers:

1. UI visibility/enablement.
2. Domain/service guard for fast feedback.
3. Server/RLS/RPC enforcement as the security boundary.

Never rely on layer 1 or 2 alone.

## 9. Testing skill

Prioritize tests around money, stock and permission boundaries.

Minimum for a feature:

- domain unit tests;
- repository/data adapter tests;
- widget tests for main states;
- integration test for the critical journey;
- RLS/SQL tests if data access changes.

## 10. Migration skill

Every database migration must be:

- deterministic;
- environment-neutral;
- safe for existing rows;
- reviewed for RLS impact;
- accompanied by verification SQL;
- reversible where practical or explicitly documented when not.

## 11. Observability skill

Instrument meaningful operations, not every tap. Capture:

- operation name;
- actor/business/location scope (non-secret identifiers);
- duration;
- success/failure category;
- sync state;
- AI proposal/action IDs where relevant.

Never log secrets, full payment credentials or private access tokens.

## 12. Product copy skill

Use concise operational language: `Receive Stock`, `Create Transfer`, `Approve`, `Low Stock`.

Avoid technical or inflated copy such as `Execute Inventory Replenishment Procedure` or consumer-AI language like `Working our magic`.
