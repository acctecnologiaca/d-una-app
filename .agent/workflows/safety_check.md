---
description: Mandatory safety check before any backend or core logic modification
---

# Safety Check Workflow

This workflow MUST be executed before developing any database migration, RPC update, or core business logic change.

## Steps

1. **Invoke the Skill**: Read the [development_safety_guardrails](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agent/skills/development_safety_guardrails/SKILL.md) skill.
2. **Schema Audit**: Execute SQL to verify every single table and column involved in the task.
3. **Regression Search**: Search specifically for "invisible logic" (Search engines, RLS, Access Levels) in previous project artifacts.
4. **Draft Plan**: Create an `implementation_plan.md` that explicitly lists what is being PRESERVED.
5. **Double Approval**: Do not execute destructive steps until the user approves the detailed plan.
