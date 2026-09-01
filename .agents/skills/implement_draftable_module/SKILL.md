---
name: implement_draftable_module
description: Guide and requirements to implement local auto-save, draft persistence, and recovery with DraftToast in form and document modules (Quotes, Reports, Orders, Purchases, Invoices, etc.).
---

# Implement Draftable Module (Auto-Save & Recovery)

Follow this skill whenever building or modifying a form, wizard, document creation, or document editing screen to ensure user inputs are preserved locally and restored transparently.

## Reference Guide
Read the complete implementation guide at:
[`draftable_module_guide.md`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/development_safety_guardrails/draftable_module_guide.md)

## Core Architecture Requirements
1. **Module Constant**: Register key in `lib/core/constants/draft_constants.dart`.
2. **State Serialization**: Add `toDraftJson()` and `fromDraftJson(Map<String, dynamic> json)` to state classes with null-safe fallbacks.
3. **Reactive Debounced Auto-Save**: Invoke `autoSaveDraft()` in all state mutator methods.
4. **Isolated Document Keys**:
   - New doc: `${DraftConstants.module}`
   - Existing doc edit: `${DraftConstants.module}_$documentId`
5. **UI Screen Integration**:
   - `AppLifecycleListener` for `onPause` & `onInactive`.
   - `_tabController.addListener` for tab switching auto-save.
   - `addPostFrameCallback` check using `checkAndRestoreDraft()`.
   - Present `DraftToast.show(context, message: ..., onDiscard: ...)` with `CustomDialog.destructive`.
   - `clearDraft()` on backend save success or explicit discard.
