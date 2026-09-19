# ThreadStock Security and Authorization Contract

## 1. Trust boundaries

The Flutter client is untrusted for authorization. It may improve UX, but security enforcement lives in Supabase/Postgres/privileged server functions.

## 2. Tenant isolation

Every query/write must be constrained to the actor's active business membership. RLS policies must not depend on user-supplied tenant IDs alone.

Where location scope applies, enforce it server-side for reads/writes that expose or mutate location-specific data.

## 3. Permission model

Permissions should be action-oriented, for example:

- inventory.view
- inventory.product.create
- inventory.adjustment.create
- inventory.count.execute
- inventory.count.approve
- sales.create
- sales.return
- purchasing.po.create
- purchasing.po.approve
- purchasing.receive
- transfer.create
- transfer.dispatch
- transfer.receive
- ai.action.approve
- automation.create
- insights.profitability
- settings.roles

Do not overload UI role names as database authorization logic. Roles are templates/groupings of permissions.

## 4. Sensitive operations

Examples:

- refund;
- large stock adjustment;
- PO approval;
- transfer approval/dispatch;
- AI prepared financial action;
- role/security/integration change.

These can require stronger confirmation, step-up authentication or a second approver according to business policy.

## 5. Secrets

Never ship:

- Supabase service-role key;
- model provider API keys;
- integration client secrets;
- webhook signing secrets;
- private encryption keys

inside Flutter assets, source, desktop binaries or logs.

## 6. RLS

RLS is mandatory for operational tables exposed through Supabase APIs. Policies should be explicit for select/insert/update/delete and call reusable authorization functions carefully. Security-definer functions must be narrowly scoped and reviewed.

## 7. Server commands

Complex sensitive writes should use RPC/Edge Functions with:

- authenticated caller;
- permission check;
- tenant/location validation;
- state-transition validation;
- idempotency key;
- transaction;
- audit record;
- canonical response.

## 8. Audit

Audit privileged and business-sensitive changes with:

- actor/user or system source;
- business/location;
- operation;
- entity + ID;
- relevant before/after values or digest;
- reason where required;
- request/correlation ID;
- server timestamp.

AI and automation must appear as distinct sources and record the approving human when applicable.

## 9. Files

Storage buckets should be business-scoped with signed/authorized access. Validate file type and size. Do not trust filename extensions alone.

## 10. Payments

Prefer tokenized payment-provider flows. Do not store raw card credentials. ThreadStock sale state must distinguish payment pending, completed, failed and uncertain/provider-verification states.

## 11. Offline data

Cache only what is necessary for supported workflows. Use secure storage for secrets and local database protections appropriate to platform risk. Signing out should clear/revoke sensitive local session state without corrupting queued business operations; policy for unsynced data must be explicit.

## 12. Logs and analytics

Never log access tokens, passwords, provider secrets, full payment data or unnecessary customer personal information.

## 13. Security definition of done

A feature that changes authorization, stock, financial state, AI execution or integrations is not complete until server enforcement and negative tests exist.
