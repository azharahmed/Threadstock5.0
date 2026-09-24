# Phase 1A Security Deployment Record

## Deployment Metadata

- **Production project:** `ahxyembxddwdtvvkdjeh`
- **Migration:** `20260923_019_security_phase_1a_authorization.sql`
- **SHA-256:** `3A68EA9E55EC5691DF09AA74A0139391781552355D20721799D58BD5004D6E95`
- **Deployment date:** 2026-09-24
- **Backup:** `supabase/backups/pre_019_schema_20260924_100200.sql`
- **Result:** SUCCESS

---

## Security Verification Metrics

- **RLS disabled public tables:** 0
- **anon executable application RPCs:** 0
- **authenticated application RPCs:** 6 (`complete_sale`, `hold_sale`, `list_held_sales`, `resume_held_sale`, `discard_held_sale`, `save_or_publish_product`)
- **authenticated internal helper RPCs:** 0 (`resolve_sale_lines`, `calculate_sale_discount`, `allocate_sale_line_discounts` have all client execute grants revoked)
- **sales direct INSERT/UPDATE/DELETE:** BLOCKED (`sales`, `sale_items`, `sale_payments` allow `SELECT` only to `authenticated`; all mutations require authoritative RPCs)
- **tax client grants:** 0
- **Existing production data preserved:** YES

---

## Intentional Limitations

> [!NOTE]
> **Tax Calculation Notice:**
> Tax calculation is not production-complete.
> `tax_minor` remains 0 until an authoritative tax engine is implemented.
