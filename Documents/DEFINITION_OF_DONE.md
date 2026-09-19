# ThreadStock Definition of Done

A feature is done only when applicable items below are satisfied.

## Product

- Canonical route and entry/exit path are defined.
- Primary and secondary actions are real.
- No placeholder buttons or fake data behavior remain.
- Mobile and desktop behavior are intentionally specified where applicable.

## UX

- Loading, empty, error and permission states exist.
- Offline behavior is explicit for operational features.
- Back/context preservation works.
- Light/dark theme are correct.
- Accessibility labels/focus/touch targets are present.
- Localization-safe formatting is used.

## Domain/data

- Business invariant is enforced in domain/server layer.
- Sensitive multi-record write is transactional.
- Idempotency exists for retryable critical commands.
- Inventory-changing operations create ledger evidence.
- Audit record exists where required.

## Security

- RLS/server permission enforcement is implemented.
- Negative permission and cross-tenant tests pass.
- No secrets exist in client source/assets/logs.

## Quality

- Formatting/analyzer pass.
- Relevant unit/widget/integration tests pass.
- Database verification tests pass where changed.
- No unresolved TODO that changes correctness.
- Errors are user-safe and developer diagnostics are observable.

## Documentation

- Route/data/status vocabulary changes are updated in blueprint docs.
- Migration and operational implications are documented.
- New reusable component is added to design system rather than copied.
