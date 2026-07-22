---
name: development_safety_guardrails
description: Mandatory rules and safety procedures to prevent regressions during backend and core logic development.
---

# Development Safety Guardrails

To avoid regressions in business logic, search engines, and accessibility
filters, the following rules MUST be followed before any structural change.

## 1. Zero-Assumption Schema Verification

**NEVER** assume table or column names, even if they were correct in a previous
step.

- Before generating SQL or modifying repositories, run:
  ```sql
  SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'target_table';
  ```
- Cross-check the actual schema against the intended mapping.

## 2. Mandatory Regression Research

Before modifying an RPC or a core service:

- Search for previous `.sql` files or `implementation_plan.md` involving that
  module.
- Identify "Invisible Logic":
  - **Spanish Search**: Check for `to_tsvector`, `unaccent`, and
    `plainto_tsquery`.
  - **Accessibility** (`is_accessible`): MUST STRICTLY ADHERE to business rules
    mapping Profile vs Supplier:
    1. **Business Verified (`VERIFIED` + `business`)**: Has unrestricted access
       to EVERYTHING (Retail & Wholesale).
    2. **Unverified (`UNVERIFIED` / Pending)**: Has access ONLY to Retail.
       Blocked from Wholesale.
    3. **Individual Verified (`VERIFIED` + `individual`)**: Has access to
       Retail, and ONLY to Wholesale suppliers that explicitly list `individual`
       in their `allowed_verification_types`. _Note: Always use case-insensitive
       SQL comparisons (`LOWER()`, `ILIKE`) for these filters._
  - **Grouping**: Ensure `ARRAY_AGG`, `mode()`, and `GROUP BY` maintain the
    correct aggregation (by brand, model, SKU).
  - **UOM Symbols**: UI Badges use `symbol` (e.g., "m."), while dynamic icons
    use `icon_name` (e.g., "straighten").

## 3. Explicit Implementation Plans

For any core change, the `implementation_plan.md` MUST include:

- **"What is preserved"**: A section listing existing logic that will remain
  intact (e.g., "Spanish search logic will be preserved").
- **Schema Mapping**: A clear table of column name changes.
- **Verification Plan**: Specific test cases for regressions (e.g., "Search for
  terms with accents").

## 4. Atomic Database Migrations

To avoid "Multiple Choices / PGRST203" errors:

- Always use `DROP FUNCTION IF EXISTS public.func_name(arg_types)` for **EVERY**
  known signature of the function.
- Do not rely on `CREATE OR REPLACE` alone if parameters are changing.
- Verify that only one version of the function exists after migration:
  ```sql
  SELECT pg_get_function_arguments(oid) FROM pg_proc WHERE proname = 'func_name';
  ```

## 5. User Review

- Present the `implementation_plan.md` and wait for explicit approval before
  executing any destructive `DROP` or schema-altering commands.
