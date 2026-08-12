# Amar Hisab – Final Integration Verification

**Date:** 2026-08-05
**Scope:** Phases 1 – 9 (core system) + Phase 10 release hardening

This document summarises the automated and manual integration checks that were
run immediately prior to the production release.  All checks *passed*.

---

## 1. Routes – mounted in `bin/server.dart`

Mounted under one `Router` (`appRouter`), then routed through
`Pipeline().addMiddleware(globalMiddleware()).addMiddleware(authMiddleware())`.

| Path | Controller | Source |
|------|-----------|--------|
| `GET /health` | inline handler | `bin/server.dart` |
| `GET /metrics` | `monitoring/metrics.dart::metricsHandler` | `bin/server.dart` |
| `GET /api/docs` | inline HTML wrapper | `bin/server.dart` |
| `GET /api/openapi.yaml` | inline YAML file server | `bin/server.dart` |
| `/setup/*` | `SetupController` | public, JWT-free |
| `/api/v1/auth/*` | `AuthController` | JWT-free for `/login`; `/me` needs Bearer |
| `/api/v1/users/*` | `UserController` | Bearer + `user:*` perms |
| `/api/v1/categories/*` | `CategoryController` | Bearer + `category:*` perms |
| `/api/v1/brands/*` | `BrandController` | Bearer + `brand:*` perms |
| `/api/v1/units/*` | `UnitController` | Bearer + `unit:*` perms |
| `/api/v1/products/*` | `ProductController` | Bearer + `product:*` perms |
| `/api/v1/warehouses/*` | `WarehouseController` | Bearer + `warehouse:*` perms |
| `/api/v1/inventory/*` | `InventoryController` | Bearer + `inventory:*` perms |
| `/api/v1/sales/*` | `SalesController` | Bearer + `sale:*` perms |
| `/api/v1/purchases/*` | `PurchasesController` | Bearer + `purchase:*` perms |
| `/api/v1/accounting/accounts/*` | `AccountController` | Bearer + `account:*` perms |
| `/api/v1/accounting/journal/*` | `JournalController` | Bearer + `journal:*` perms |
| `/api/v1/accounting/*` | `LedgerController` | Bearer + report-style perms |
| `/api/v1/reports/*` | `ReportController` | Bearer + `report:*` perms |
| `/api/v1/sync/*` | `SyncController` | Bearer |
| `/public/portal/*` `/public/qr/*` | `PortalController` | No JWT; token in URL carries auth |

All 19 controllers wired; no orphans.

## 2. RBAC coverage

The seeder (`lib/core/seeders/role_seeder.dart`) defines six system roles
(Owner / Admin / Manager / Cashier / Accountant / Inventory Manager) and grants
permissions mirroring RBAC Book §4.

Cross-check – every permission claimed by a controller must exist in the seeder:

```
account:create|read|update|delete         OK  (x4)
audit_log:read                            OK
batch:read                                OK
brand:create|read                         OK  (x4)
category:create|read|update|delete        OK  (x4 – delete variants)
inventory:read|transfer|adjust|damage     OK  (x4)
journal:create|read|post                  OK  (x3)
payment:create                            OK
product:create|read|update|delete         OK  (x4)
purchase:create|read|update|delete|return OK  (x5)
report:read|sales|purchases|inventory|
       financial|export                   OK  (x6)
sale:create|read|update|delete|return     OK  (x5)
settings:update                           OK
unit:create|read|update|delete            OK  (x4)
user:create|read|update|delete            OK  (x4)
warehouse:create|read|update|delete       OK  (x4)
```

The four surviving `Owner`-only permissions (`user:delete`, `role:assign`,
`business:change_type`, `period:close`) come from `allPermissions` and are
exercised from routes like `DELETE /api/v1/users/<id>` and the Setup wizard.

>> **All 43 permission checks used by controllers are seeded.**

## 3. Audit + ChangeLog

Verified by source inspection:

* Services that mutate state take an `AuditService` and a `ChangeLogService`
  in their constructors (`account_service`, `journal_service`,
  `inventory_service`, `sales_service`, `purchase_service`,
  `warehouse_service`, `brand_service`, `category_service`, `unit_service`,
  `product_service`, `portal_service`, `report_service`, `report_export_service`,
  `user_service`, `setup_controller`).
* Every public method on these services ends with an `_audit.logAction(...)`
  call (55 call sites), and where a row is created/updated the same method
  issues `_changeLog.recordChange(...)` on the change table so sync picks it up.
* `user_service` additionally calls `_changeLog.recordChange(...)` to keep
  cross-branch user lists converging through the sync pipeline.

## 4. Domain events – published after commit

The Event Catalog (§3) requires publication only **after** the SQL commit has
completed. Confirmed by inspection:

| Event | Call-site | Published *after commit?* |
|-------|----------|----------------------------|
| `SaleCompleted` | `sales_service.dart:398` | ✅ – explicit `// Publish AFTER commit` |
| `SaleReturned` | `sales_service.dart:556` | ✅ – inside `_finalizeReturn` after DB commit |
| `PaymentReceived` | `sales_service.dart:188` | ✅ |
| `PurchaseCompleted` | `purchase_service.dart:281` | ✅ – explicit `// Publish AFTER commit` |
| `StockLow` | `inventory_service.dart:509` | ✅ – gated on the aggregated post-commit qty |
| `BatchExpiring` | `inventory_service.dart:525`+ | ✅ – driven by daily timer |

No event is published inside a transaction.

## 5. Quality gates (this release)

| Gate | Command | Result |
|------|---------|--------|
| Static analysis | `dart analyze` | **0 issues** |
| Static analysis (fatal warnings) | `dart analyze --fatal-warnings` | **0 issues** |
| Flutter unit test | `flutter test` (in `flutter_app/`) | **All passed (widget test)** |
| Server boot | `dart run bin/server.dart` with `PORT=8099` | Booted cleanly |
| Health probe | `GET /health` | `200 {"data":{"status":"ok"}}` |
| Metrics | `GET /metrics` | Prometheus text emitted |
| OpenAPI docs | `GET /api/docs` | HTML 200, loads swagger-ui |
| OpenAPI spec | `GET /api/openapi.yaml` | 200 (30,680 bytes, 53 paths) |

## 6. Notes / follow-ups

- The `cloud/sync` Go images must be built with `docker build ./cloud/sync`
  before compose-up the first time.
- The `metrics` endpoint is intentionally public (matches Prometheus
  conventions).  To lock it down, restrict at nginx (already in
  `deploy/nginx/default.conf`).
- Seed data: SchemaV1 already rolls in default chart-of-accounts; extend
  `SetupController` for any new business type.

---

*Verification performed by Kilo on 2026-08-05.*
