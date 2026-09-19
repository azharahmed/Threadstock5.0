# ThreadStock Implementation Roadmap

The design is broad; implementation should be vertical and testable. Do not build every screen shell first and wire behavior later.

## Phase 0 - Foundation

- repository/tooling;
- environments and Supabase projects;
- app bootstrap/config validation;
- design tokens/components;
- typed routing;
- localization/formatting;
- authentication and business context;
- permission framework;
- logging/error model;
- local database + sync/outbox skeleton.

Exit: authenticated user can enter an authorized empty workspace on mobile and desktop with no legacy/fake data.

## Phase 1 - Catalog and inventory core

- product/style/variant model;
- inventory ledger/balance;
- inventory list/detail;
- create/edit product;
- stock adjustment;
- barcode scanning lookup;
- labels;
- categories/collections;
- import foundation.

Exit: real stock can be created, viewed and adjusted with audit evidence.

## Phase 2 - Sales

- quick sale;
- held sale;
- checkout/payment abstraction;
- receipts;
- sales history/detail;
- returns/exchanges;
- customers.

Exit: sale changes inventory atomically and can be safely returned.

## Phase 3 - Purchasing and receiving

- suppliers;
- PO create/detail/approval;
- receiving full/partial/damaged;
- supplier return;
- incoming inventory views.

Exit: buy-to-receive loop is production-ready.

## Phase 4 - Transfers and stock counts

- transfer lifecycle;
- dispatch/receive/discrepancy;
- stock count/blind count;
- reconciliation/approval.

Exit: multi-location stock operations are trustworthy.

## Phase 5 - Insights foundation

- event/read models;
- sales/inventory analytics;
- dead stock/ageing;
- location and supplier performance;
- report export.

Exit: analytics are based on real operational data, not placeholder charts.

## Phase 6 - AI read intelligence

- AI gateway;
- natural-language search;
- stockout/dead-stock/supplier/location insights;
- forecast center;
- anomaly detection;
- AI history/provenance.

Exit: AI produces useful read-only intelligence with evaluation telemetry.

## Phase 7 - AI prepared actions and approvals

- action proposal schema;
- replenishment PO proposals;
- transfer proposals;
- review/edit/approve/reject;
- approval center;
- execution revalidation + audit.

Exit: AI can safely prepare real work without bypassing human/permission controls.

## Phase 8 - Automations

- rule model;
- natural-language authoring;
- deterministic simulation;
- scheduler/event triggers;
- run history/failures;
- approval integration.

## Phase 9 - Integrations and enterprise settings

- channels/integrations framework;
- teams/roles refinements;
- API/webhooks;
- advanced tax/doc settings;
- plan/billing as needed.

## Phase 10 - Production hardening

- offline conflict scenarios;
- accessibility audit;
- performance/load testing;
- security review;
- backup/restore/export procedures;
- observability dashboards;
- store release/desktop packaging;
- migration and incident runbooks.

## Delivery rule

Each phase should ship vertical behavior across UI -> domain -> server -> tests. A completed Figma page without real domain behavior is not a completed product feature.
