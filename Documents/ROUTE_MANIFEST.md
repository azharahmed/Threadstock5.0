# Canonical Route Manifest

These paths are the application route vocabulary. Do not create aliases casually. If a route changes, update this file, deep links, tests and analytics together.

| Route | Module | Page | Parent / Entry | Permission |
|---|---|---|---|---|
| `/onboarding/welcome` | Onboarding | Welcome | Entry | `Public` |
| `/onboarding/business` | Onboarding | Business setup | /onboarding/welcome | `Public` |
| `/onboarding/location` | Onboarding | Location setup | /onboarding/business | `Public` |
| `/onboarding/commerce` | Onboarding | Commerce setup | /onboarding/location | `Public` |
| `/onboarding/inventory` | Onboarding | Inventory starting point | /onboarding/commerce | `Public` |
| `/onboarding/team` | Onboarding | Team setup | /onboarding/inventory | `Public` |
| `/onboarding/complete` | Onboarding | Setup complete | /onboarding/team | `Public` |
| `/overview` | Overview | Overview dashboard | App root | `Authenticated` |
| `/notifications` | Global | Notification center | Header bell | `Authenticated` |
| `/approvals` | Global | Approval center | Header / Overview / AI | `Permission: approvals.view` |
| `/activity` | Global | Recent activity | Header / entity activity | `Authenticated` |
| `/sync` | Global | Sync activity | Profile / offline banner | `Authenticated` |
| `/profile` | Global | My profile | Profile menu | `Authenticated` |
| `/inventory` | Inventory | Inventory Studio | Sidebar | `inventory.view` |
| `/inventory/products/new` | Inventory | Create product | /inventory | `inventory.product.create` |
| `/inventory/products/:productId` | Inventory | Product detail | /inventory | `inventory.view` |
| `/inventory/products/:productId/edit` | Inventory | Edit product | Product detail | `inventory.product.edit` |
| `/inventory/products/:productId/variants` | Inventory | Variant matrix | Product detail | `inventory.product.edit` |
| `/inventory/products/:productId/stock` | Inventory | Product stock | Product detail | `inventory.view` |
| `/inventory/products/:productId/activity` | Inventory | Product activity | Product detail | `inventory.view` |
| `/inventory/counts` | Inventory | Stock counts | Inventory tabs | `inventory.count.view` |
| `/inventory/counts/new` | Inventory | Start stock count | /inventory/counts | `inventory.count.create` |
| `/inventory/counts/:countId` | Inventory | Active stock count | /inventory/counts | `inventory.count.execute` |
| `/inventory/counts/:countId/reconcile` | Inventory | Count reconciliation | Count detail | `inventory.count.approve` |
| `/inventory/adjustments` | Inventory | Adjustment history | Inventory tabs | `inventory.adjustment.view` |
| `/inventory/adjustments/new` | Inventory | Stock adjustment | Product / Inventory | `inventory.adjustment.create` |
| `/inventory/labels` | Inventory | Barcode & labels | Inventory tabs | `inventory.labels.print` |
| `/inventory/catalog/categories` | Inventory | Categories | Catalog setup | `inventory.catalog.manage` |
| `/inventory/catalog/collections` | Inventory | Collections | Catalog setup | `inventory.catalog.manage` |
| `/inventory/import` | Inventory | Inventory import | Inventory actions | `inventory.import` |
| `/inventory/import/:jobId` | Inventory | Import review | /inventory/import | `inventory.import` |
| `/sales` | Sales | Sales overview | Sidebar | `sales.view` |
| `/sales/new` | Sales | Quick sale | /sales | `sales.create` |
| `/sales/held` | Sales | Held sales | Sales tabs | `sales.create` |
| `/sales/:saleId` | Sales | Sale detail | /sales | `sales.view` |
| `/sales/:saleId/receipt` | Sales | Receipt | Sale detail | `sales.view` |
| `/sales/:saleId/return` | Sales | Return / exchange | Sale detail | `sales.return` |
| `/sales/customers` | Sales | Customers | Sales tabs | `customer.view` |
| `/sales/customers/new` | Sales | Create customer | Customers / New sale | `customer.create` |
| `/sales/customers/:customerId` | Sales | Customer detail | Customers | `customer.view` |
| `/purchasing` | Purchasing | Purchase orders | Sidebar | `purchasing.view` |
| `/purchasing/orders/new` | Purchasing | Create purchase order | /purchasing | `purchasing.po.create` |
| `/purchasing/orders/:poId` | Purchasing | Purchase order detail | /purchasing | `purchasing.view` |
| `/purchasing/orders/:poId/edit` | Purchasing | Edit purchase order | PO detail | `purchasing.po.edit` |
| `/purchasing/orders/:poId/receive` | Purchasing | Receive purchase order | PO detail / Receiving | `purchasing.receive` |
| `/purchasing/suppliers` | Purchasing | Suppliers | Purchasing tabs | `supplier.view` |
| `/purchasing/suppliers/new` | Purchasing | Create supplier | Suppliers | `supplier.create` |
| `/purchasing/suppliers/:supplierId` | Purchasing | Supplier detail | Suppliers | `supplier.view` |
| `/purchasing/receiving` | Purchasing | Receiving queue | Purchasing tabs | `purchasing.receive` |
| `/purchasing/returns/new` | Purchasing | Return to supplier | PO detail | `purchasing.return` |
| `/transfers` | Transfers | Transfers | Sidebar | `transfer.view` |
| `/transfers/new` | Transfers | Create transfer | /transfers | `transfer.create` |
| `/transfers/:transferId` | Transfers | Transfer detail | /transfers | `transfer.view` |
| `/transfers/:transferId/dispatch` | Transfers | Dispatch transfer | Transfer detail | `transfer.dispatch` |
| `/transfers/:transferId/receive` | Transfers | Receive transfer | Transfer detail / Incoming | `transfer.receive` |
| `/ai` | AI Studio | Intelligence home | Sidebar / mobile AI | `ai.use` |
| `/ai/actions` | AI Studio | AI action queue | AI tabs / approvals | `ai.action.view` |
| `/ai/actions/:actionId` | AI Studio | AI action detail | AI actions | `ai.action.view` |
| `/ai/history` | AI Studio | AI history | AI tabs | `ai.history.view` |
| `/ai/forecasts` | AI Studio | Forecast center | AI tabs | `ai.forecast.view` |
| `/ai/forecasts/:variantId` | AI Studio | Forecast detail | Forecast center | `ai.forecast.view` |
| `/ai/anomalies` | AI Studio | Anomaly center | AI tabs | `ai.anomaly.view` |
| `/ai/anomalies/:anomalyId` | AI Studio | Anomaly investigation | Anomaly center | `ai.anomaly.view` |
| `/automations` | Automations | Automations | Sidebar | `automation.view` |
| `/automations/new` | Automations | Create automation | /automations | `automation.create` |
| `/automations/:automationId` | Automations | Automation detail | /automations | `automation.view` |
| `/automations/:automationId/edit` | Automations | Edit automation | Automation detail | `automation.edit` |
| `/automations/runs` | Automations | Run history | Automations tabs | `automation.view` |
| `/automations/runs/:runId` | Automations | Run detail | Run history | `automation.view` |
| `/insights` | Insights | Insights home | Sidebar | `insights.view` |
| `/insights/sales` | Insights | Sales analytics | Insights tabs | `insights.sales` |
| `/insights/inventory` | Insights | Inventory analytics | Insights tabs | `insights.inventory` |
| `/insights/dead-stock` | Insights | Dead stock | Inventory analytics | `insights.inventory` |
| `/insights/stock-ageing` | Insights | Stock ageing | Inventory analytics | `insights.inventory` |
| `/insights/profitability` | Insights | Profitability | Insights tabs | `insights.profitability` |
| `/insights/locations` | Insights | Location comparison | Insights tabs | `insights.locations` |
| `/insights/suppliers` | Insights | Supplier performance | Insights tabs | `insights.suppliers` |
| `/insights/forecast-accuracy` | Insights | Forecast accuracy | Insights tabs | `insights.forecast` |
| `/insights/reports` | Insights | Report Studio | Insights tabs | `report.view` |
| `/insights/reports/new` | Insights | Build report | Report Studio | `report.create` |
| `/insights/reports/:reportId` | Insights | Report detail | Report Studio | `report.view` |
| `/settings` | Settings | Settings home | Sidebar | `settings.view` |
| `/settings/business` | Settings | Business profile | Settings | `settings.business` |
| `/settings/locations` | Settings | Locations | Settings | `settings.locations` |
| `/settings/locations/new` | Settings | Create location | Locations | `settings.locations` |
| `/settings/locations/:locationId` | Settings | Location detail | Locations | `settings.locations` |
| `/settings/team` | Settings | Team | Settings | `settings.team` |
| `/settings/team/invite` | Settings | Invite user | Team | `settings.team` |
| `/settings/team/:userId` | Settings | User detail | Team | `settings.team` |
| `/settings/roles` | Settings | Roles & permissions | Settings | `settings.roles` |
| `/settings/roles/:roleId` | Settings | Role permission editor | Roles | `settings.roles` |
| `/settings/taxes-currency` | Settings | Taxes & currency | Settings | `settings.tax` |
| `/settings/documents` | Settings | Document settings | Settings | `settings.documents` |
| `/settings/security` | Settings | Security | Settings | `settings.security` |
| `/settings/sales-channels` | Settings | Sales channels | Settings | `settings.integrations` |
| `/settings/sales-channels/:channelId` | Settings | Channel detail | Sales channels | `settings.integrations` |
| `/settings/integrations` | Settings | Integrations | Settings | `settings.integrations` |
| `/settings/integrations/:integrationId` | Settings | Integration detail | Integrations | `settings.integrations` |
| `/settings/notifications` | Settings | Notification settings | Settings | `settings.notifications` |
| `/settings/barcode-printing` | Settings | Barcode & printing | Settings | `settings.printing` |
| `/settings/inventory` | Settings | Inventory rules | Settings | `settings.inventory` |
| `/settings/purchasing` | Settings | Purchasing settings | Settings | `settings.purchasing` |
| `/settings/transfers` | Settings | Transfer settings | Settings | `settings.transfers` |
| `/settings/import-export` | Settings | Import / export | Settings | `settings.import_export` |
| `/settings/api-webhooks` | Settings | API & webhooks | Settings | `settings.api` |
| `/settings/audit` | Settings | Audit log | Settings | `audit.view` |
| `/settings/preferences` | Settings | Preferences | Settings | `settings.preferences` |
| `/settings/ai` | Settings | ThreadStock AI settings | Settings | `settings.ai` |
| `/settings/subscription` | Settings | Plan & usage | Settings | `billing.view` |
| `/settings/billing` | Settings | Billing | Settings | `billing.manage` |
| `/settings/data` | Settings | Business data | Settings | `settings.data` |
| `/help` | Help | Help & support | Profile / Settings | `Authenticated` |
| `/help/status` | Help | System status | Help | `Authenticated` |

## Route naming rules

- Plural nouns represent collections: `/inventory/counts`.
- `new` is for creation: `/transfers/new`.
- Entity IDs are named by entity: `:productId`, `:poId`.
- Actions that deserve a durable/deep-linkable workflow are child paths: `/transfers/:transferId/receive`.
- Tabs that are merely presentation can remain query/state instead of extra routes; routes above are minimum canonical destinations.
- Never encode business IDs in public paths unless multi-business deep linking requires it; active business scope is session/app context and revalidated server-side.
