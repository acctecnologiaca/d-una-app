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

### 2. Pestaña de Resumen y Guardado
La última pestaña (Resumen) consolida los datos ingresados en las pestañas anteriores y contiene el botón de confirmación final. Al completarse con éxito la inserción en base de datos:
1. Se invoca obligatoriamente `notifier.clearDraft()`.
2. Se muestra retroalimentación flotante con `AppToast.showSuccess(context, 'Documento creado exitosamente')`.
3. Se navega a la pantalla de visualización ejecutiva del documento.

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
