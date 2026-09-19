# ThreadStock Behavior Specification

## 1. Global behavior

### Context preservation

When a user drills into detail and returns, preserve the originating list's search, filters, sort, saved view, scroll position and selected row where practical.

### Feedback

- Instant operation: update state immediately, no spinner flash.
- Short operation: disable/mark the triggering control and show concise inline progress.
- Long operation: create a background job with status and notification; never force the user to stare at a loading page.
- Success: toast for small actions; dedicated confirmation state for sales, receiving and other major workflows.
- Failure: explain what did not happen and provide a recovery action.

### Destructive actions

Never use only “Are you sure?”. State the object and consequence. Irreversible or high-impact actions require explicit confirmation and appropriate permission.

## 2. Authentication and workspace entry

A session does not automatically mean workspace access. Entry requires:

1. valid session;
2. active business membership;
3. completed/allowed business setup;
4. active role/location scope.

If any check fails, route to a safe blocked/setup state rather than rendering stale business data.

## 3. Inventory

### Product creation

Style is the parent product. Color/size/material combinations create variants. SKU/barcode generation can be assisted but must resolve uniqueness before save.

### Adjustment

A stock adjustment requires location, variant, signed quantity/change semantics, reason, actor and audit record. Update ledger + balance atomically.

### Count

Counts can be blind or visible. Reconciliation posts only after review/approval. A recount does not mutate stock until reconciliation completes.

### Label printing

Label generation is read-only with respect to stock. Print failures must not affect inventory.

## 4. Sales

### Cart

Adding a scanned variant increments its cart quantity unless business rules prevent it. Parent-style selection requires variant choice.

### Checkout

Do not create a completed sale until payment/business completion rules are satisfied. If payment status is uncertain, enter an explicit pending/verification state and prevent duplicate completion.

### Return/exchange

Returns reference the original sale when available. Exchange posts return and replacement stock effects as an auditable business transaction. Manual/unlinked return may require manager approval.

## 5. Purchasing

PO states are canonical and should not be inferred from UI text alone. Suggested state progression:

`draft -> awaiting_approval -> ordered -> partially_received -> received`

Terminal alternatives: `cancelled`.

Receiving supports damaged/missing/over-received policy. Damaged stock must not silently enter sellable available stock.

## 6. Transfers

Suggested progression:

`draft -> awaiting_approval -> picking -> in_transit -> partially_received/received`

Terminal alternative: `cancelled`.

Dispatch removes/commits source stock according to the chosen inventory model. Receiving creates destination ledger events. Discrepancies are explicit records, not hidden balance corrections.

## 7. AI Studio

AI begins with proactive business intelligence, not an empty chat box. Natural language is an input method; results should become structured business objects when possible.

For actionable recommendations show:

- What ThreadStock found/recommends.
- Why: concise source signals.
- Impact: stock/revenue/cost/coverage where meaningful.
- Confidence: only calibrated/meaningful categories.
- Action: review/prepare/approve.

Sensitive execution must honor [AI_SYSTEM.md](AI_SYSTEM.md) and [SECURITY.md](SECURITY.md).

## 8. Automations

The natural-language description compiles into transparent editable rules. Always show trigger, conditions, action, scope and approval requirement before activation.

“Test” is simulation only; it must not execute business writes.

Run result categories:

- completed;
- no_action;
- needs_approval;
- failed.

## 9. Insights

Analytics pages answer: What happened? Why does it matter? What can I do? Use charts only when they clarify a pattern. An insight that suggests an operation should deep-link to a prepared, reviewable workflow.

## 10. Search and command palette

Global search returns entities, destinations and actions. Natural-language queries may invoke AI read tools. High-impact write actions entered through search still route through the same review/approval policy.

## 11. Offline and sync

Offline banner is subtle and non-blocking for supported workflows. A queued action is never labeled synced until the server confirms it. Conflict examples must show business context such as sales/receipts that changed the stock after the user went offline.

## 12. Permissions

Three UI outcomes:

- Hide: actor should not discover/use the capability.
- Disable with explanation: capability is relevant but currently unavailable.
- Request approval/access: workflow explicitly supports escalation.

Server authorization remains authoritative.

## 13. Accessibility and localization

- Keyboard focus remains visible on desktop.
- Reduced motion removes nonessential movement.
- Dynamic text/large translations must not clip primary actions.
- RTL reverses directional layout where appropriate.
- Formatting is locale-aware; internal numeric values are not stored as formatted strings.
