---
description: Mandatory safety check before any backend or core logic modification
---

# Safety Check Workflow

This workflow MUST be executed before developing any database migration, RPC
update, or core business logic change.

## Steps

1. **Invoke the Skill**: Read the
   [development_safety_guardrails](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agent/skills/development_safety_guardrails/SKILL.md)
   skill.
2. **Schema Audit**: Consult the **[database_map.md](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/supabase/database_map.md)**
   to ensure 100% accuracy on table and column names. Execute SQL to verify any
   dynamic or missing information.
3. **Function Verification**: If you need any function from Supabase to verify
   any SQL code, just ask it.
4. **Regression Search**: Search specifically for "invisible logic" (Search
   engines, RLS, Access Levels) in previous project artifacts.
5. **Draft Plan**: Create an `implementation_plan.md` that explicitly lists what
   is being PRESERVED.
6. **Double Approval**: Do not execute destructive steps until the user approves
   the detailed plan.
