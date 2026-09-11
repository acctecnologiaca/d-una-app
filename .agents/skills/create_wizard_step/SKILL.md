---
name: create_wizard_step
description: Estándar integral para Wizards, Creadores de Documentos y Flujos por Pasos (Arquetipo 3). Abarca tanto Creadores Multi-Pestaña con auto-guardado local (DraftableModule y DraftToast) como Wizards Lineales por Pasos con WizardProgressBar y WizardButtonBar.
---

# Standardize Wizards, Document Creators & Stepper Flows (Arquetipo 3)

Esta guía define el estándar para flujos de creación guiada en D'Una App, divididos en dos patrones arquitectónicos según el tipo de flujo:
1. **Patrón A: Creadores de Documentos Comerciales (Pestañas + Auto-guardado Draftable)**: Para Cotizaciones, Reportes, Órdenes.
2. **Patrón B: Wizards Lineales por Pasos (Stepper + ProgressBar)**: Para Alta de Productos, Registro de Clientes, Onboarding.

---

## 🏗️ Patrón A: Creadores de Documentos Multi-Pestaña con Auto-guardado

Referencias canónicas:
- [`create_quote_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/create_quote/screens/create_quote_screen.dart)
- [`create_report_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/reports/presentation/create_report/screens/create_report_screen.dart)

### 1. Estructura General y Ciclo de Vida
El creador es un `ConsumerStatefulWidget` con `SingleTickerProviderStateMixin`. Maneja auto-guardado reactivo en los siguientes puntos clave:
1. Al cambiar de pestaña (`_tabController.addListener`).
2. Al pausar la app o salir a segundo plano (`AppLifecycleListener.onPause` / `onInactive`).
3. Al inicializar la pantalla: comprobación de borrador previo con notificación [`DraftToast`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/draft_toast.dart).

```dart
class CreateMyDocumentScreen extends ConsumerStatefulWidget {
  final String? documentId; // null = Nuevo documento, valor = Modo Edición
  const CreateMyDocumentScreen({super.key, this.documentId});

  @override
  ConsumerState<CreateMyDocumentScreen> createState() => _CreateMyDocumentScreenState();
}

class _CreateMyDocumentScreenState extends ConsumerState<CreateMyDocumentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Auto-guardado al cambiar de pestaña
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref.read(createMyDocumentProvider.notifier).autoSaveDraft(
              tabIndex: _tabController.index,
              docId: widget.documentId,
            );
      }
    });

    // Auto-guardado en segundo plano
    _lifecycleListener = AppLifecycleListener(
      onPause: () => ref.read(createMyDocumentProvider.notifier).autoSaveDraft(
            tabIndex: _tabController.index,
            docId: widget.documentId,
          ),
      onInactive: () => ref.read(createMyDocumentProvider.notifier).autoSaveDraft(
            tabIndex: _tabController.index,
            docId: widget.documentId,
          ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final notifier = ref.read(createMyDocumentProvider.notifier);
    final draft = await notifier.checkExistingDraft(docId: widget.documentId);

    if (draft != null && mounted) {
      notifier.restoreDraft(draft);
      if (draft.tabIndex >= 0 && draft.tabIndex < 5) {
        _tabController.index = draft.tabIndex;
      }
      DraftToast.show(
        context,
        message: 'Borrador recuperado automáticamente',
        onDiscard: () async {
          await notifier.discardDraft(docId: widget.documentId);
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }
```

### 2. Las 3 Modalidades Canónicas de Guardado

El guardado de documentos ejecutivos y formularios comerciales sigue tres modalidades canónicas según el contexto:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ MODALIDAD 1: CREACIÓN DE DOCUMENTO DESDE CERO (documentId == null)          │
│  • Botón de guardado: EXCLUSIVAMENTE en el CustomExtendedFab de la pestaña  │
│    "Resumen". El AppBar NO contiene botón de guardar.                       │
│  • Habilitación reactiva: Requiere cambios reales del usuario (isDirty /     │
│    hasChanges) y campos obligatorios válidos (isDetailsValid, notEmpty).    │
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
│  • Al guardar: AppToast.success, limpia borrador, invalida providers de     │
│    detalle y listado, y cierra el modo edición / pantalla.                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ MODALIDAD 3: AUTO-GUARDADO TEMPORAL Y RECUPERACIÓN REACTIVA                 │
│  • Disparadores: Cambio de pestaña, app en pausa/segundo plano (lifecycle)  │
│    y navegación hacia atrás (PopScope -> _handlePop).                       │
│  • Condición estricta: Solo persiste si hay cambios reales del usuario.     │
│  • Al reabrir: Despliega DraftToast.show ofreciendo "Descartar".            │
│  • Al descartar: Dialog destructivo (CustomDialog.destructive) que purga el │
│    borrador en SharedPreferences y restaura el estado original.             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3. Estandarización del Menú Vertical de Acciones (`more_vert`)
Todo creador o editor de documentos comerciales debe incluir en `AppBar.actions` el menú vertical estandarizado mediante [`CustomActionSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart). Queda estrictamente prohibido usar botones ad-hoc o cajas espaciadoras artificiales (`const SizedBox(width: 48)`).

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
      onPressed: () => _showActionsMenu(ref),
    ),
  ],
)
```

El método `_showActionsMenu(ref)` despliega dos opciones con **habilitación reactiva simétrica** (`enabled: hasChanges`):
1. **"Guardar y continuar luego"** (`bookmark_added_outlined`):
   - Habilitado solo si hay modificaciones no guardadas (`hasChanges`).
   - Persiste el borrador en `SharedPreferences`, muestra `AppToast.info(context, message: 'Cambios guardados temporalmente')` y sale de la vista.
2. **"Descartar cambios locales"** (`delete_outline`, `colors.error`):
   - Habilitado solo si hay modificaciones no guardadas (`hasChanges`).
   - Muestra confirmación preventiva destructiva con [`CustomDialog.destructive`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dialog.dart). Al confirmar, elimina el borrador local, restablece los datos originales y notifica al usuario.

### 4. Floating Action Buttons (FABs), Clearance y SafeArea
En los creadores de documentos comerciales, los botones de acción principal (`Agregar` en pestañas intermedias y `Guardar` en Resumen) se presentan mediante `CustomExtendedFab`:
1. **Scroll Clearance en Pestañas:** Todas las pestañas que contengan contenido scrollable (`SingleChildScrollView`, `ListView.builder`, `ReorderableListView`) y convivan con un FAB activo **DEBEN** aplicar `FabScrollPadding.single` (`112.0px`) en su padding inferior:
   ```dart
   SingleChildScrollView(
     padding: const EdgeInsets.fromLTRB(16, 16, 16, FabScrollPadding.single),
     child: ...
   )
   ```
2. **Coordinación con `SafeArea`:** Al tratarse de flujos independientes a pantalla completa (sin `BottomNavigationBar`), el `Scaffold` empuja automáticamente el FAB según `MediaQuery.padding.bottom`. Para evitar desajustes visuales, el cuerpo del Scaffold **DEBE** envolverse siempre en `SafeArea`:
   ```dart
   Scaffold(
     body: SafeArea(
       child: TabBarView(
         controller: _tabController,
         children: [...],
       ),
     ),
     floatingActionButton: _buildFab(),
   )
   ```
3. **Prohibición de Padding Artificial:** Queda **estrictamente prohibido** envolver los `CustomExtendedFab` en `Padding(bottom: 40.0)`. Los FABs deben asignarse directamente al `Scaffold`.

---

## 🏗️ Patrón B: Wizards Lineales por Pasos

Referencias canónicas:
- [`add_product_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/portfolio/presentation/inventory/screens/add_product/add_product_screen.dart)
- [`add_client/*`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/screens/add_client)

### 1. Estructura y Navegación
Los flujos lineales guían al usuario paso a paso (ej. Paso 1 de 4).
- **Indicador de Progreso:** [`WizardProgressBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_progress_bar.dart) colocado en `appBar.bottom` o como primer hijo del body.
- **Barra de Botones:** [`WizardButtonBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_bottom_bar.dart) colocada al pie de pantalla con `padding: EdgeInsets.only(bottom: 40)`.

```dart
class MyLinearWizardScreen extends StatefulWidget {
  const MyLinearWizardScreen({super.key});

  @override
  State<MyLinearWizardScreen> createState() => _MyLinearWizardScreenState();
}

class _MyLinearWizardScreenState extends State<MyLinearWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  final _formKey = GlobalKey<FormState>();

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finalizeProcess();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Nuevo Elemento',
        bottom: WizardProgressBar(
          currentStep: _currentStep + 1,
          totalSteps: _totalSteps,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Form(
                key: _formKey,
                child: _buildCurrentStepView(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: WizardButtonBar(
              onCancel: () => context.pop(),
              onBack: _currentStep > 0 ? _onBack : null,
              onNext: _onNext,
              labelNext: _currentStep == _totalSteps - 1 ? 'Finalizar' : 'Siguiente',
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Checklist de Verificación para Wizards

- [ ] Si es creador de documentos: ¿se implementó auto-guardado en cambio de tabs y ciclo de vida de la app?
- [ ] ¿Se utiliza `DraftToast` con diálogo destructivo para descartar borradores?
- [ ] ¿Se limpia el borrador (`clearDraft`) tras guardar exitosamente en base de datos?
- [ ] Si es wizard lineal: ¿se utiliza `WizardProgressBar` y `WizardButtonBar` con padding inferior de 40px?
- [ ] ¿Cada paso valida su formulario antes de avanzar al siguiente?
