# ThreadStock Testing Strategy

## Goals

Protect stock correctness, money correctness, tenant isolation, permissions, offline recovery and critical user journeys.

## 1. Static gates

- `dart format` / formatting check.
- `flutter analyze` with no ignored new warnings.
- generated-code consistency if code generation is used.
- migration lint/SQL verification.

## 2. Domain unit tests

Test business rules without Flutter/Supabase where possible:

- inventory quantity/event calculations;
- PO/transfer/sale state transitions;
- tax/discount/money arithmetic;
- permission decisions;
- forecast/action proposal transformations;
- automation rule evaluation.

## 3. Data/repository tests

Verify DTO mapping, pagination, retry/idempotency behavior and local/remote merge logic.

## 4. Database tests

For every sensitive schema/RLS/RPC change test:

- allowed tenant action;
- cross-tenant denial;
- location-scope denial;
- missing permission denial;
- invalid state transition denial;
- idempotent repeat call;
- ledger/balance consistency;
- audit creation.

## 5. Widget tests

At minimum cover:

- loading;
- populated;
- empty;
- error;
- permission denied;
- disabled/approval-required action;
- light/dark where visual logic differs.

## 6. Integration journeys

Critical automation targets:

1. onboarding -> workspace;
2. create product + variants;
3. quick sale -> payment success -> stock reduction;
4. return/exchange;
5. create PO -> partial receive -> full receive;
6. create/dispatch/receive transfer with discrepancy;
7. stock count -> variance -> reconciliation;
8. AI proposal -> edit -> approve -> domain action;
9. automation simulation -> activation -> run -> approval;
10. offline sale/count -> reconnect -> sync/conflict.

## 7. Golden/visual testing

Use selectively for design-system primitives and high-value responsive shells, not every screen. Validate phone and desktop breakpoints.

## 8. Performance

Profile large catalog/list use cases. Use virtualization/pagination, image caching and query indexes. Establish budgets for cold start, inventory search response and scanner-to-result latency.

## 9. Regression policy

Any production bug involving stock, money, permissions or sync must receive a regression test before closure unless technically impossible and explicitly documented.
