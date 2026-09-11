---
name: implement_draftable_module
description: Guide and requirements to implement local auto-save, draft persistence, and recovery with DraftToast in form and document modules (Quotes, Reports, Orders, Purchases, Invoices, etc.).
---

# Implement Draftable Module (Auto-Save & Recovery)

Follow this skill whenever building or modifying a form, wizard, document creation, or document editing screen to ensure user inputs are preserved locally and restored transparently.

## Reference Guide
Read the companion implementation guide at:
[`draftable_module_guide.md`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/development_safety_guardrails/draftable_module_guide.md)

---

## 1. Core Architecture & Key Isolation

The draftable system provides local persistence in `SharedPreferences` via `DraftStorageService` (`lib/core/services/draft_storage_service.dart`), isolated by user ID and document:

1. **Module Constant**: Register key in `lib/core/constants/draft_constants.dart`.
2. **Isolated Keys**:
   - **Creation Mode (New Doc):** `${DraftConstants.module}` (e.g. `'quotes'`, `'reports'`)
   - **Edit Mode (Existing Doc):** `${DraftConstants.module}_$documentId` (e.g. `'quotes_COT-001'`)
3. **State Serialization**:
   - `toDraftJson()` and `fromDraftJson(Map<String, dynamic> json)` on the state with null-safe fallbacks.
4. **Key Purging (`clearDraft`)**:
   - On backend save success: Purges the exact key (`${DraftConstants.module}` or `${DraftConstants.module}_$documentId`).
   - On explicit discard confirmation (`CustomDialog.destructive`): Purges the draft from storage and resets the state.
   - On back/exit navigation (`PopScope`): **NEVER** purge; the draft is immediately flushed with `saveDraftNow` and kept safe.

---

## 2. Reactivity with `hasChanges` / `isDirty`

Every draftable module state must expose a boolean getter (`hasChanges` or `isDirty`) that determines if user modifications exist:

- **Creation Mode**: `hasChanges => items.isNotEmpty || clientId != null || notes.isNotEmpty` (any entered input).
- **Edit Mode**: `hasChanges => currentState != initialState` (deep equality or field-by-field comparison against initial loaded data).

This getter governs:
1. Whether auto-save actually writes to disk (avoids saving blank or unmodified states).
2. The enabled/disabled state of all save triggers.
3. The options inside the `more_vert` menu sheet.

---

## 3. The 3 Canonical Save Modalities

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ MODALIDAD 1: CREACIÓN DE DOCUMENTO DESDE CERO (documentId == null)          │
│  • Botón de guardado: EXCLUSIVAMENTE en el CustomExtendedFab de la pestaña  │
│    "Resumen". El AppBar NO contiene botón de guardar.                       │
│  • Habilitación reactiva: canSave => state.hasChanges && state.isValid.      │
│  • Al salir sin cambios: Cierre limpio sin generar borrador ni toasts.      │
│  • Al salir con cambios pendientes: Auto-guarda borrador silencioso y       │
│    notifica con AppToast.info('Cambios guardados temporalmente').           │
│  • Al guardar en backend: Limpia borrador (clearDraft), invalida providers  │
│    y navega a la vista ejecutiva del documento.                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ MODALIDAD 2: EDICIÓN DE DOCUMENTO EXISTENTE (documentId != null)             │
│  • Botón Dual Simétrico: El guardado está disponible en DOS lugares:        │
│    1. En el AppBar.actions: IconButton(icon: save_outlined, onPressed: ...)│
│    2. En el CustomExtendedFab de la pestaña "Resumen".                      │
│  • Habilitación Simultánea Reactiva: Ambos botones se habilitan ÚNICAMENTE  │
│    si el usuario modificó algún dato (state.isDirty / state.hasChanges).    │
│    Si revierte los cambios manualmente, ambos se deshabilitan al unísono.   │
│  • Tooltip reactivo: 'Guardar cambios' vs 'Sin modificaciones'.             │
│  • Al guardar: AppToast.success, limpia borrador (${module}_$id), invalida   │
│    providers de detalle y listado, y cierra el modo edición / pantalla.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ MODALIDAD 3: AUTO-GUARDADO TEMPORAL Y RECUPERACIÓN REACTIVA                 │
│  • Disparadores: Cambio de pestaña, app en pausa/segundo plano (lifecycle)  │
│    y navegación hacia atrás (PopScope -> _handlePop con saveDraftNow).      │
│  • Condición estricta: Solo persiste si state.hasChanges == true.           │
│  • Al reabrir: Despliega DraftToast.show ofreciendo "Descartar".            │
│  • Al descartar: Dialog destructivo (CustomDialog.destructive) que purga el │
│    borrador en SharedPreferences y restaura el estado original.             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Vertical Actions Menu (`more_vert`) Standard

In all multi-tab document creators and editors, `AppBar.actions` must provide the vertical actions menu using [`CustomActionSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart). Prohibit arbitrary spacing hacks like `SizedBox(width: 48)`.

```dart
AppBar(
  actions: [
    if (widget.documentId != null) // Solo en modo edición
      IconButton(
        icon: Icon(state.isLoading ? Icons.hourglass_empty : Icons.save_outlined),
        tooltip: canSave ? 'Guardar cambios' : 'Sin modificaciones',
        onPressed: canSave ? _saveDocument : null,
      ),
    IconButton(
      icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
      onPressed: () => _showActionsMenu(context, ref),
    ),
  ],
)
```

The `CustomActionSheet` actions:
1. **"Guardar y continuar luego"** (`Icons.bookmark_added_outlined`):
   - `enabled: state.hasChanges`
   - Invokes `saveDraftNow()`, notifies with `AppToast.info(context, message: 'Cambios guardados temporalmente')`, and exits.
2. **"Descartar cambios locales"** (`Icons.delete_outline`, `colors.error`):
   - `enabled: state.hasChanges`
   - Prompts prevention confirmation with `CustomDialog.destructive(title: '¿Descartar cambios?', ...)`.
   - Upon confirmation: calls `notifier.discardDraft(docId: widget.documentId)` which purges SharedPreferences and resets state to original/clean.

---

## 5. Screen Lifecycle Integration Checklist

- [ ] `AppLifecycleListener`: auto-save on `onPause` and `onInactive`.
- [ ] `_tabController.addListener`: auto-save when `!_tabController.indexIsChanging`.
- [ ] `PopScope`: intercepts back action to call `saveDraftNow()`, preventing data loss.
- [ ] `addPostFrameCallback`: checks for existing draft via `checkAndRestoreDraft(docId: widget.documentId)`.
- [ ] `DraftToast.show`: displayed on restoration with destructive confirmation on discard.
- [ ] Backend Save: purges draft via `clearDraft(docId: widget.documentId)` upon success.
- [ ] Scroll Clearance: all scrollable tabs apply `FabScrollPadding.single` (`112.0px`) bottom padding when a FAB is present.
- [ ] Scaffold body wrapped in `SafeArea` to handle dynamic bottom insets correctly.
