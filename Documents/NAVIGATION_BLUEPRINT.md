# ThreadStock Navigation Blueprint

This is the human-readable parent -> child map. The canonical route strings live in `ROUTE_MANIFEST.md`.

## Global entry

```text
App
├─ Onboarding
│  ├─ Welcome
│  ├─ Business Setup
│  ├─ Location Setup
│  ├─ Commerce Setup
│  ├─ Inventory Starting Point
│  ├─ Team Setup
│  └─ Setup Complete
├─ Overview
├─ Notifications
├─ Approvals
├─ Recent Activity
├─ Sync Activity
├─ My Profile
└─ Help & Support
```

## Inventory

```text
Inventory Studio
├─ Create Product
├─ Product Detail
│  ├─ Edit Product
│  ├─ Variant Matrix
│  ├─ Stock by Location
│  └─ Product Activity
├─ Stock Counts
│  ├─ Start Stock Count
│  └─ Active Stock Count
│     └─ Reconciliation
├─ Adjustments
│  └─ New Stock Adjustment
├─ Barcode & Labels
├─ Catalog Setup
│  ├─ Categories
│  └─ Collections
└─ Inventory Import
   └─ Import Mapping / Validation / Review
```

## Sales

```text
Sales Overview
├─ New / Quick Sale
├─ Held Sales
├─ Sale Detail
│  ├─ Receipt
│  └─ Return / Exchange
└─ Customers
   ├─ Create Customer
   └─ Customer Detail
```

## Purchasing

```text
Purchase Orders
├─ Create PO
├─ PO Detail
│  ├─ Edit PO
│  ├─ Receive PO
│  └─ Return to Supplier
├─ Receiving Queue
└─ Suppliers
   ├─ Create Supplier
   └─ Supplier Detail
```

## Transfers

```text
Transfers
├─ Create Transfer
└─ Transfer Detail
   ├─ Dispatch Transfer
   └─ Receive Transfer
```

## AI Studio

```text
Intelligence Home
├─ AI Actions
│  └─ AI Action Detail
├─ AI History
├─ Forecast Center
│  └─ Product / Variant Forecast Detail
└─ Anomalies
   └─ Anomaly Investigation
```

## Automations

```text
Automations
├─ Create Automation
├─ Automation Detail
│  └─ Edit Automation
└─ Run History
   └─ Run Detail
```

## Insights

```text
Insights Home
├─ Sales Analytics
├─ Inventory Analytics
│  ├─ Dead Stock
│  └─ Stock Ageing
├─ Profitability
├─ Location Comparison
├─ Supplier Performance
├─ Forecast Accuracy
└─ Report Studio
   ├─ Build Report
   └─ Report Detail
```

## Settings

```text
Settings Home
├─ Business Profile
├─ Locations
│  ├─ Create Location
│  └─ Location Detail
├─ Team
│  ├─ Invite User
│  └─ User Detail
├─ Roles & Permissions
│  └─ Role Permission Editor
├─ Taxes & Currency
├─ Document Settings
├─ Security
├─ Sales Channels
│  └─ Channel Detail
├─ Integrations
│  └─ Integration Detail
├─ Notification Settings
├─ Barcode & Printing
├─ Inventory Rules
├─ Purchasing Settings
├─ Transfer Settings
├─ Import / Export
├─ API & Webhooks
├─ Audit Log
├─ Preferences
├─ ThreadStock AI Settings
├─ Plan & Usage
├─ Billing
└─ Business Data
```

## Mobile primary navigation

```text
Home
├─ Notifications
├─ Approvals
└─ Quick actions: Scan / Sell / Receive / Count Stock

Inventory
├─ Product Detail
├─ Adjust Stock
├─ Transfer
└─ Stock Count

Scan
├─ Lookup
├─ Sell
├─ Receive
├─ Stock Count
└─ Transfer

Sales
├─ Quick Sale
├─ Checkout
├─ Sale History
└─ Return / Exchange

AI
├─ Intelligence
├─ Conversation / Query
├─ Action Review
├─ History
├─ Forecasts
└─ Anomalies

More
├─ Purchasing
├─ Transfers
├─ Suppliers
├─ Customers
├─ Insights
├─ Automations
├─ Settings
└─ Help
```

## Navigation integrity rules

- Every child page has a defined parent/entry in `ROUTE_MANIFEST.md`.
- Notifications/search deep-link to the exact entity instead of a generic module root.
- Mobile Back restores the originating filtered list where possible.
- Desktop list/detail flows preserve list state when the right inspector opens.
- Sensitive subpages can be blocked by permission without breaking the parent route.
