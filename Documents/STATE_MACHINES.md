# ThreadStock State Machines

State transitions must be validated server-side. The UI should render from canonical state rather than infer state from counts alone.

## Purchase order

```text
draft
  -> awaiting_approval
  -> ordered
  -> partially_received
  -> received

any allowed pre-terminal state -> cancelled
```

`received` and `cancelled` are terminal for normal editing.

## Transfer

```text
draft
  -> awaiting_approval
  -> picking
  -> in_transit
  -> partially_received (optional)
  -> received

allowed pre-terminal state -> cancelled
```

A discrepancy can coexist with received state as a linked record; do not invent ambiguous status strings per screen.

## Stock count

```text
draft -> in_progress -> review_required -> awaiting_approval -> completed
                         -> in_progress (recount)
```

Alternative terminal: cancelled.

## Sale

```text
draft/held -> payment_pending -> completed
completed -> partially_refunded -> refunded
```

Cancellation/void semantics should be explicit and depend on payment/fiscal policy.

## AI action proposal

```text
detected -> proposed -> prepared -> awaiting_approval -> approved -> executing -> completed
                                   -> rejected
                          -> expired
                                                     -> failed
```

## Automation

Configuration state: `draft -> active <-> paused -> archived`.

Run state: `queued -> running -> completed | no_action | needs_approval | failed`.

## Import job

`uploaded -> mapping -> validating -> needs_review -> importing -> completed | failed`.

## Integration sync

`idle -> syncing -> success | warning | failed` with independent connection status `connected | paused | disconnected | auth_required`.
