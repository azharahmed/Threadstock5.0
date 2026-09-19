# ThreadStock Canonical Data Model

This is a logical model, not a finished migration. Names may evolve only through an explicit architecture decision; relationships and invariants should remain stable.

## Identity and tenancy

### businesses

Business/tenant root.

Key concepts: id, legal/display identity, default locale/currency/timezone, status, created_at.

### locations

Stores, warehouses, stockrooms or offices. Belongs to business.

### memberships

Connects auth user to business. Status controls active access.

### roles / permissions / membership_role_assignments

Roles group permissions. Assignment may include location scope.

## Catalog

### products

Fashion style/parent record: name, category, brand, collection, season, department, description, primary media.

### product_variants

Sellable/stockable SKU: product_id, color, size, material/attributes, sku, barcode, price/cost defaults, active state.

### categories / collections / brands / attribute definitions

Reusable catalog organization.

### product_media

Images/media with sort order and metadata.

## Inventory

### inventory_ledger

Append-only movement/event table.

Recommended fields:

- id
- business_id
- location_id
- variant_id
- event_type
- quantity_delta_available
- quantity_delta_committed
- quantity_delta_damaged
- source_type
- source_id
- reason_code
- actor_user_id nullable for system events
- source_actor (`user`, `ai`, `automation`, `integration`, `import`)
- client_operation_id/idempotency key
- occurred_at server time
- metadata versioned JSON for non-index-critical detail

### inventory_balances

Current materialized balance per location/variant. Updated atomically with ledger operation or recomputed from ledger where needed.

### stock_counts / stock_count_lines

Count header, scope, status, counters and submitted values.

### stock_adjustments

Business-facing adjustment record referencing one or more ledger events.

## Sales

### sales

Transaction/order header: business/location/customer/cashier, totals, currency, status, timestamps.

### sale_lines

Variant, quantity, unit price, discount, tax, line total.

### payments

Payment attempts/completions; store provider tokens/references, never raw card secrets.

### refunds / return_lines

Refund/return business records and inventory effects.

### customers

Lightweight commerce customer profile. Avoid collecting unnecessary sensitive profile data.

### held_sales

Draft carts intentionally parked for later resume.

## Purchasing

### suppliers

Contact, terms, currencies, lead-time/defaults and status.

### purchase_orders / purchase_order_lines

PO header and variant quantities/costs.

### purchase_receipts / purchase_receipt_lines

Each receipt event supports partial and damaged quantities.

### supplier_returns

Return-to-supplier header/lines and expected credit reference.

## Transfers

### transfers / transfer_lines

Source/destination, state and requested/sent/received quantities.

### transfer_shipments / transfer_receipts / transfer_discrepancies

Operational evidence for dispatch, receiving and mismatch handling.

## AI

### ai_interactions

User request/query metadata and structured response references. Do not store hidden chain-of-thought.

### ai_insights

Detected business insight with scope, source data references, expiry and read/dismiss state.

### ai_action_proposals

Structured proposed action with lifecycle status, affected entities, expected impact, approval requirement and idempotency key.

### ai_action_reviews

Human edits/approve/reject with reason and actor.

## Automations

### automations

Versioned rule definition, scope, status, approval policy and schedule/trigger definition.

### automation_runs

One execution evaluation with metrics and outcome.

### automation_run_actions

Prepared/executed actions linked to proposals or domain commands.

## Insights and reports

### saved_reports / report_runs / report_schedules

User-defined report specification, generated run and scheduled delivery configuration.

## Platform

### notifications

In-app notification records with target actor, entity link and read state.

### approval_requests

Optional normalized approval queue abstraction referencing domain entities/proposals.

### audit_log

Append-only security/business audit for privileged changes: actor/source, entity, operation, before/after digest or structured values, business/location, timestamp, request/correlation ID.

### integration_connections / integration_mappings / sync_checkpoints

External channel configuration and sync state. Secrets stay in server secret storage, not plain tables/client.

### outbox (client-local, optionally server mirror)

Queued offline mutation envelopes.

## Invariants

1. SKU uniqueness is scoped according to business policy and enforced in database.
2. Barcode uniqueness is enforced where ThreadStock is authoritative; collision must be resolved, never silently overwritten.
3. Stock-changing records always produce ledger evidence.
4. Money is stored in integer minor units or a deliberate exact numeric strategy; never floating-point doubles for authoritative totals.
5. Every operational record is tenant-scoped.
6. Soft-delete/archive policy must preserve audit references.
7. State transitions are validated server-side; client cannot jump arbitrary statuses.
8. AI/automation source actions are distinguishable from direct user actions.
