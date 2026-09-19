# ThreadStock Product Blueprint

This document is the canonical information architecture and page ownership map. Routes are defined in [ROUTE_MANIFEST.md](ROUTE_MANIFEST.md).

## Top-level navigation

**Desktop:** Overview -> Inventory -> Sales -> Purchasing -> Transfers -> AI Studio -> Automations -> Insights -> Settings

**Mobile primary:** Home -> Inventory -> Scan -> Sales -> AI

Mobile secondary modules are exposed through More, Home shortcuts and contextual flows. They do not become an oversized bottom navigation.

## Navigation rules

- A subpage belongs to one primary domain even when it can be deep-linked from another domain.
- Opening an entity from search/notification should deep-link to the entity, not the module home.
- Back navigation should restore filters, scroll position and selection when practical.
- Desktop quick review uses a right inspector; full page opens for editing or deeper work.
- Mobile quick review uses bottom sheets where appropriate; substantial work gets a dedicated page.
- Every route must have loading, empty (where relevant), error, permission and safe-back behavior.

## Onboarding

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Welcome | `/onboarding/welcome` | Entry | `Public` | Start business setup or demo workspace |
| Business setup | `/onboarding/business` | /onboarding/welcome | `Public` | Business identity, country, language, currency |
| Location setup | `/onboarding/location` | /onboarding/business | `Public` | Create first store/warehouse |
| Commerce setup | `/onboarding/commerce` | /onboarding/location | `Public` | Sales channels, payment methods, tax mode |
| Inventory starting point | `/onboarding/inventory` | /onboarding/commerce | `Public` | Start fresh, import, or connect store |
| Team setup | `/onboarding/team` | /onboarding/inventory | `Public` | Invite initial users with role + location |
| Setup complete | `/onboarding/complete` | /onboarding/team | `Public` | Review setup and enter workspace |

## Overview

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Overview dashboard | `/overview` | App root | `Authenticated` | Business pulse, attention queue, AI insight, quick actions |

## Global

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Notification center | `/notifications` | Header bell | `Authenticated` | Operational, AI and system notifications |
| Approval center | `/approvals` | Header / Overview / AI | `Permission: approvals.view` | PO, transfer, adjustment, refund and AI approvals |
| Recent activity | `/activity` | Header / entity activity | `Authenticated` | Cross-module chronological operational activity |
| Sync activity | `/sync` | Profile / offline banner | `Authenticated` | Offline queue, retries, conflicts |
| My profile | `/profile` | Profile menu | `Authenticated` | Personal profile, security, preferences |

## Inventory

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Inventory Studio | `/inventory` | Sidebar | `inventory.view` | Products/styles, search, filters, bulk actions |
| Create product | `/inventory/products/new` | /inventory | `inventory.product.create` | Create style, attributes, commerce and stock defaults |
| Product detail | `/inventory/products/:productId` | /inventory | `inventory.view` | Overview, variants, stock, purchasing, sales, activity |
| Edit product | `/inventory/products/:productId/edit` | Product detail | `inventory.product.edit` | Edit style and commerce data |
| Variant matrix | `/inventory/products/:productId/variants` | Product detail | `inventory.product.edit` | Color x size/SKU matrix |
| Product stock | `/inventory/products/:productId/stock` | Product detail | `inventory.view` | Location stock, incoming, committed, coverage |
| Product activity | `/inventory/products/:productId/activity` | Product detail | `inventory.view` | Ledger timeline for one product/variant |
| Stock counts | `/inventory/counts` | Inventory tabs | `inventory.count.view` | Count list and status |
| Start stock count | `/inventory/counts/new` | /inventory/counts | `inventory.count.create` | Location/scope/counting mode |
| Active stock count | `/inventory/counts/:countId` | /inventory/counts | `inventory.count.execute` | Scan/manual count progress |
| Count reconciliation | `/inventory/counts/:countId/reconcile` | Count detail | `inventory.count.approve` | Review variances and post adjustments |
| Adjustment history | `/inventory/adjustments` | Inventory tabs | `inventory.adjustment.view` | Manual adjustments and audit |
| Stock adjustment | `/inventory/adjustments/new` | Product / Inventory | `inventory.adjustment.create` | Adjust quantity with reason and audit |
| Barcode & labels | `/inventory/labels` | Inventory tabs | `inventory.labels.print` | Generate/print labels |
| Categories | `/inventory/catalog/categories` | Catalog setup | `inventory.catalog.manage` | Category hierarchy |
| Collections | `/inventory/catalog/collections` | Catalog setup | `inventory.catalog.manage` | Seasons and collections |
| Inventory import | `/inventory/import` | Inventory actions | `inventory.import` | Upload/map/validate/import CSV/XLSX |
| Import review | `/inventory/import/:jobId` | /inventory/import | `inventory.import` | Mapping, validation and final review |

## Sales

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Sales overview | `/sales` | Sidebar | `sales.view` | Today, recent transactions and sales operations |
| Quick sale | `/sales/new` | /sales | `sales.create` | POS cart, customer, discount, payment |
| Held sales | `/sales/held` | Sales tabs | `sales.create` | Resume/cancel paused sales |
| Sale detail | `/sales/:saleId` | /sales | `sales.view` | Items, payment, customer, receipt, activity |
| Receipt | `/sales/:saleId/receipt` | Sale detail | `sales.view` | Print/share/download receipt |
| Return / exchange | `/sales/:saleId/return` | Sale detail | `sales.return` | Return/refund/exchange flow |
| Customers | `/sales/customers` | Sales tabs | `customer.view` | Customer directory |
| Create customer | `/sales/customers/new` | Customers / New sale | `customer.create` | Lightweight customer profile |
| Customer detail | `/sales/customers/:customerId` | Customers | `customer.view` | Purchases, returns, preferences, activity |

## Purchasing

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Purchase orders | `/purchasing` | Sidebar | `purchasing.view` | PO list, incoming stock, spend |
| Create purchase order | `/purchasing/orders/new` | /purchasing | `purchasing.po.create` | Supplier, products, quantities, costs |
| Purchase order detail | `/purchasing/orders/:poId` | /purchasing | `purchasing.view` | Items, receiving, costs, documents, activity |
| Edit purchase order | `/purchasing/orders/:poId/edit` | PO detail | `purchasing.po.edit` | Edit draft/allowed PO fields |
| Receive purchase order | `/purchasing/orders/:poId/receive` | PO detail / Receiving | `purchasing.receive` | Full/partial/damaged receiving |
| Suppliers | `/purchasing/suppliers` | Purchasing tabs | `supplier.view` | Supplier directory and performance |
| Create supplier | `/purchasing/suppliers/new` | Suppliers | `supplier.create` | Supplier profile and terms |
| Supplier detail | `/purchasing/suppliers/:supplierId` | Suppliers | `supplier.view` | Products, POs, lead time, activity |
| Receiving queue | `/purchasing/receiving` | Purchasing tabs | `purchasing.receive` | Expected/in-transit/partial/recent receipts |
| Return to supplier | `/purchasing/returns/new` | PO detail | `purchasing.return` | Return received stock and expected credit |

## Transfers

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Transfers | `/transfers` | Sidebar | `transfer.view` | Incoming/outgoing/history |
| Create transfer | `/transfers/new` | /transfers | `transfer.create` | Source, destination, products and quantities |
| Transfer detail | `/transfers/:transferId` | /transfers | `transfer.view` | Items, shipment, activity, status |
| Dispatch transfer | `/transfers/:transferId/dispatch` | Transfer detail | `transfer.dispatch` | Pick/confirm and dispatch stock |
| Receive transfer | `/transfers/:transferId/receive` | Transfer detail / Incoming | `transfer.receive` | Receive and record discrepancies |

## AI Studio

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Intelligence home | `/ai` | Sidebar / mobile AI | `ai.use` | Proactive insights + natural language input |
| AI action queue | `/ai/actions` | AI tabs / approvals | `ai.action.view` | Prepared proposals awaiting review |
| AI action detail | `/ai/actions/:actionId` | AI actions | `ai.action.view` | What/why/impact/confidence/edit/approve |
| AI history | `/ai/history` | AI tabs | `ai.history.view` | Conversation, recommendations, reports and actions |
| Forecast center | `/ai/forecasts` | AI tabs | `ai.forecast.view` | Demand forecast overview |
| Forecast detail | `/ai/forecasts/:variantId` | Forecast center | `ai.forecast.view` | Variant/location trajectory and action |
| Anomaly center | `/ai/anomalies` | AI tabs | `ai.anomaly.view` | Unusual activity needing review |
| Anomaly investigation | `/ai/anomalies/:anomalyId` | Anomaly center | `ai.anomaly.view` | Context and safe next actions |

## Automations

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Automations | `/automations` | Sidebar | `automation.view` | Active/paused/history |
| Create automation | `/automations/new` | /automations | `automation.create` | Natural language + transparent rule builder |
| Automation detail | `/automations/:automationId` | /automations | `automation.view` | Rules, health, scope, run stats |
| Edit automation | `/automations/:automationId/edit` | Automation detail | `automation.edit` | Edit trigger/conditions/actions/approval |
| Run history | `/automations/runs` | Automations tabs | `automation.view` | Run outcomes and approvals |
| Run detail | `/automations/runs/:runId` | Run history | `automation.view` | Business-readable result/failure detail |

## Insights

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Insights home | `/insights` | Sidebar | `insights.view` | Executive summary and drilldowns |
| Sales analytics | `/insights/sales` | Insights tabs | `insights.sales` | Revenue, units, AOV, returns, margin |
| Inventory analytics | `/insights/inventory` | Insights tabs | `insights.inventory` | Value, coverage, sell-through, risk |
| Dead stock | `/insights/dead-stock` | Inventory analytics | `insights.inventory` | No/low movement inventory and suggested actions |
| Stock ageing | `/insights/stock-ageing` | Inventory analytics | `insights.inventory` | Age buckets and working capital |
| Profitability | `/insights/profitability` | Insights tabs | `insights.profitability` | Revenue, COGS, gross profit and margin |
| Location comparison | `/insights/locations` | Insights tabs | `insights.locations` | Store/warehouse comparison |
| Supplier performance | `/insights/suppliers` | Insights tabs | `insights.suppliers` | Lead time, fill rate, spend, cost trend |
| Forecast accuracy | `/insights/forecast-accuracy` | Insights tabs | `insights.forecast` | Forecast vs actual |
| Report Studio | `/insights/reports` | Insights tabs | `report.view` | Saved/custom/AI-generated reports |
| Build report | `/insights/reports/new` | Report Studio | `report.create` | Metric/group/filter/visualization builder |
| Report detail | `/insights/reports/:reportId` | Report Studio | `report.view` | View/edit/export/schedule report |

## Settings

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Settings home | `/settings` | Sidebar | `settings.view` | Grouped business, access, operations, system and account settings |
| Business profile | `/settings/business` | Settings | `settings.business` | Identity, localization, contact |
| Locations | `/settings/locations` | Settings | `settings.locations` | Location directory |
| Create location | `/settings/locations/new` | Locations | `settings.locations` | Store/warehouse/stockroom creation |
| Location detail | `/settings/locations/:locationId` | Locations | `settings.locations` | Inventory, team, defaults and activity |
| Team | `/settings/team` | Settings | `settings.team` | Users, roles, locations and status |
| Invite user | `/settings/team/invite` | Team | `settings.team` | Email, role, location invitation |
| User detail | `/settings/team/:userId` | Team | `settings.team` | Assignments, role and activity |
| Roles & permissions | `/settings/roles` | Settings | `settings.roles` | System/custom roles |
| Role permission editor | `/settings/roles/:roleId` | Roles | `settings.roles` | Granular permissions and scopes |
| Taxes & currency | `/settings/taxes-currency` | Settings | `settings.tax` | Currencies, tax profiles, rounding |
| Document settings | `/settings/documents` | Settings | `settings.documents` | Invoice/receipt/PO/transfer numbering and templates |
| Security | `/settings/security` | Settings | `settings.security` | MFA, sessions, approvals, audit protections |
| Sales channels | `/settings/sales-channels` | Settings | `settings.integrations` | Store/marketplace channel connections |
| Channel detail | `/settings/sales-channels/:channelId` | Sales channels | `settings.integrations` | Sync direction, source of truth, activity |
| Integrations | `/settings/integrations` | Settings | `settings.integrations` | Commerce/accounting/payments/shipping/data |
| Integration detail | `/settings/integrations/:integrationId` | Integrations | `settings.integrations` | Authorization, sync configuration, activity |
| Notification settings | `/settings/notifications` | Settings | `settings.notifications` | Channel and cadence preferences |
| Barcode & printing | `/settings/barcode-printing` | Settings | `settings.printing` | Barcode defaults, SKU generation, printers |
| Inventory rules | `/settings/inventory` | Settings | `settings.inventory` | Negative stock, thresholds, counts, approvals |
| Purchasing settings | `/settings/purchasing` | Settings | `settings.purchasing` | Defaults, approvals, receiving, AI purchasing |
| Transfer settings | `/settings/transfers` | Settings | `settings.transfers` | Approvals, states, discrepancies, AI transfers |
| Import / export | `/settings/import-export` | Settings | `settings.import_export` | Data jobs and history |
| API & webhooks | `/settings/api-webhooks` | Settings | `settings.api` | API keys, events, delivery history |
| Audit log | `/settings/audit` | Settings | `audit.view` | Who/what/when/where/before/after/source |
| Preferences | `/settings/preferences` | Settings | `settings.preferences` | Appearance, density, language, accessibility |
| ThreadStock AI settings | `/settings/ai` | Settings | `settings.ai` | Recommendations, forecasting, prepared actions, auto-execution |
| Plan & usage | `/settings/subscription` | Settings | `billing.view` | Plan limits and usage |
| Billing | `/settings/billing` | Settings | `billing.manage` | Payment method, billing address, invoices |
| Business data | `/settings/data` | Settings | `settings.data` | Export, retention, archive, closure |

## Help

| Page | Route | Enter from | Permission | Purpose |
|---|---|---|---|---|
| Help & support | `/help` | Profile / Settings | `Authenticated` | Guides, support, feedback |
| System status | `/help/status` | Help | `Authenticated` | Service and sync status |

## Core end-to-end journeys

### New business

`Welcome -> Business -> Location -> Commerce -> Inventory start -> Team -> Complete -> Overview`

After setup, route the user into the selected inventory starting flow rather than forcing inventory setup before Team.

### Sell an item

`Home/Sales -> New Sale -> Scan/Search -> Variant -> Cart -> Customer optional -> Checkout -> Payment -> Sale complete -> Receipt`

A completed sale creates financial records, sale lines, payment state, inventory ledger events and audit events atomically/idempotently.

### Replenish low stock

`Overview/AI/Forecast -> Recommendation -> Review -> Edit -> Approve -> Draft/Create PO -> Supplier confirmation -> Receiving -> Inventory updated`

### Purchase receiving

`Purchasing -> PO -> Receive -> Scan/enter quantities -> damaged/missing handling -> Complete partial/full receipt -> Inventory ledger -> PO state update`

### Store transfer

`Product/AI/Transfers -> Create -> Approval (if needed) -> Picking -> Dispatch -> In Transit -> Receive -> discrepancy handling -> Completed`

### Stock count

`Inventory -> Stock Counts -> Start -> Scan/manual count -> Variances -> Recount/Accept -> Approval -> Ledger reconciliation -> Completed`

### AI business action

`Detect -> Explain -> Prepare -> Await approval -> Human edit/approve -> Execute -> Audit -> Surface outcome`

### Automation

`Describe rule -> Build transparent conditions -> Test simulation -> Enable -> Run -> No action / Prepared action / Needs approval / Failure -> History`

### Offline

`Connection lost -> Supported operation stored locally -> Outbox -> Connection restored -> Idempotent sync -> Success OR business conflict -> User resolves conflict`

## Page behavior contract

Every page specification should answer:

1. Who can access it?
2. What is the primary job-to-be-done?
3. What is the primary action?
4. What is visible before scrolling?
5. What happens on success?
6. What can fail?
7. What happens offline?
8. What is audited?
9. What is different on mobile vs desktop?
10. Where does Back return the user?
