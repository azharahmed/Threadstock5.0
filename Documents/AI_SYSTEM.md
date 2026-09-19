# ThreadStock AI System

## Product role

ThreadStock AI is an operational intelligence layer. Its purpose is to reduce manual work while preserving human control, permissions and auditability.

## Capability tiers

### 1. Observe

Read permitted business data and identify patterns: stockout risk, dead stock, supplier delay, unusual adjustments, location imbalance.

### 2. Recommend

Explain a suggested business response and expected impact.

### 3. Prepare

Create a structured proposal/draft such as a PO, transfer or report without yet executing the sensitive business action.

### 4. Execute

Allowed only if the action is within the configured automation/approval policy and the current actor/system identity has the server-side permission. High-impact actions should normally require approval.

## Proposal lifecycle

`detected -> proposed -> prepared -> awaiting_approval -> approved -> executing -> completed`

Other outcomes: `rejected`, `failed`, `cancelled`, `expired`.

A proposal contains:

- business/location scope;
- proposal type;
- affected entity IDs;
- structured quantities/amounts;
- source signals/data snapshot references;
- explanation summary;
- expected impact;
- confidence category if meaningful;
- required permission/approval rule;
- creator source (AI/automation/user-assisted);
- idempotency key;
- expiry/staleness rules.

## Server boundary

The Flutter app never contains provider API secrets. AI requests flow through a server-side gateway that:

1. authenticates the ThreadStock user/session;
2. resolves membership + permission + location scope;
3. builds minimal context;
4. invokes allowed read/proposal tools;
5. validates structured model output;
6. persists the interaction/proposal;
7. returns safe UI data.

## Tool policy

Tools are explicitly allow-listed. Read tools cannot mutate. Proposal tools create draft/proposal records. Execution tools verify approval + freshness + idempotency immediately before executing.

Never give the model direct unrestricted SQL or service-role access.

## Freshness

Before approving/executing an inventory recommendation, revalidate important live facts such as current stock, incoming supply, supplier state and permissions. If the proposal is stale, require refresh/review instead of applying outdated quantities.

## User experience

AI should show structured results, not a long paragraph when a business object is appropriate.

Example:

- 18 SKUs at risk
- 640 units recommended
- Rs 482,000 estimated cost
- 37 days projected coverage
- Why: demand +22%, lead time 14 days, coverage 11 days
- Review / Edit / Approve

## AI history

Store safe business provenance, not hidden reasoning traces. Useful history includes user prompt, structured summary, tools/data sources referenced, proposal/action IDs, final human decision and execution outcome.

## Automations

Natural language can author a rule, but the saved automation is a transparent deterministic/versioned structure. “Test” performs simulation only. AI may help explain failures but does not hide the actual trigger/condition/action definition.

## Evaluation

Evaluate AI features on business usefulness, not prose quality alone:

- stockout-risk precision/recall where labels exist;
- forecast error;
- approved vs rejected proposal rate;
- manual edits before approval;
- false anomaly rate;
- supplier/transfer recommendation outcomes;
- time saved;
- financial/stock impact with careful attribution.

Never claim causation that cannot be supported by the available data.
