# Guía de Implementación para Módulos con Auto-Guardado y Recuperación de Borradores (Drafts)

Esta guía documenta el estándar arquitectónico y el protocolo paso a paso para implementar el sistema de auto-guardado debounced y restauración transparente de borradores locales en cualquier módulo nuevo o existente de **D'Una App**.

---

## 1. Arquitectura Central

El sistema de borradores se compone de los siguientes elementos en el core:

| Componente | Ubicación | Responsabilidad |
| :--- | :--- | :--- |
| `DraftStorageService` | `lib/core/services/draft_storage_service.dart` | Persistencia debounced (500ms) y asíncrona en `SharedPreferences` indexada por usuario (`user_draft_${userId}_${key}`). |
| `DraftData` | `lib/core/models/draft_data.dart` | Estructura del borrador: `moduleKey`, `savedAt`, `tabIndex`, `summaryTitle`, `data` (Map). |
| `DraftConstants` | `lib/core/constants/draft_constants.dart` | Claves constantes para cada módulo (`quotes`, `reports`, `supplier_orders`, `purchases`, etc.). |
| `DraftToast` | `lib/shared/widgets/draft_toast.dart` | Componente visual flotante no invasivo basado en `AppToast` con botón de acción **"Descartar"**. |

---

## 2. Aislamiento de Claves de Borrador

1. **Modo Creación (Nuevo Documento):**
   - Utiliza la clave fija del módulo:
     ```dart
     DraftConstants.quotesModule // -> 'quotes'
     ```
2. **Modo Edición (Documento Existente):**
   - Utiliza una clave compuesta con el ID único del documento:
     ```dart
     '${DraftConstants.quotesModule}_$quoteId' // -> 'quotes_COT-001'
     ```
   - *Garantía:* Múltiples documentos pueden tener borradores de edición simultáneos e independientes sin sobreescribirse.

---

## 3. Lista de Comprobación para Nuevos Módulos

### Paso 1: Registrar Clave de Módulo
En `lib/core/constants/draft_constants.dart`, agrega la constante:
```dart
static const String myNewModule = 'my_new_module';
```

### Paso 2: Serialización en el Estado / Notifier
En el estado del módulo (o StateNotifier/Notifier), implementa los métodos de serialización:
```dart
Map<String, dynamic> toDraftJson() {
  return {
    'items': items.map((i) => i.toJson()).toList(),
    'client_id': clientId,
    'description': description,
    // Demás campos relevantes
  };
}

factory MyModuleState.fromDraftJson(Map<String, dynamic> json) {
  return MyModuleState(
    items: (json['items'] as List? ?? []).map((i) => Item.fromJson(i)).toList(),
    clientId: json['client_id'] as String?,
    description: json['description'] as String? ?? '',
    // Demás campos con fallbacks null-safe
  );
}
```

### Paso 3: Métodos del Notifier
En el Notifier del módulo:
```dart
DraftStorageService get _draftStorage => ref.read(draftStorageServiceProvider);

String _getDraftKey({String? docId}) {
  final id = docId ?? state.id;
  if (id != null && id.isNotEmpty) {
    return '${DraftConstants.myNewModule}_$id';
  }
  return DraftConstants.myNewModule;
}

void autoSaveDraft({int tabIndex = 0, String? docId}) {
  final isEditing = state.id != null || (docId != null && docId.isNotEmpty);

  if (isEditing) {
    if (!state.isDirty) return;
  } else {
    final hasData = state.items.isNotEmpty || state.clientId != null;
    if (!hasData) return;
  }

  final key = _getDraftKey(docId: docId);
  final draft = DraftData(
    moduleKey: key,
    savedAt: DateTime.now(),
    tabIndex: tabIndex,
    summaryTitle: state.clientName != null
        ? '${isEditing ? "Modificación" : "Nuevo"} - ${state.clientName}'
        : 'Nuevo Documento',
    data: state.toDraftJson(),
  );
  _draftStorage.saveDraftDebounced(draft);
}

Future<DraftData?> checkAndRestoreDraft({String? docId}) async {
  final key = _getDraftKey(docId: docId);
  final draft = await _draftStorage.getDraft(key);
  if (draft != null && draft.data.isNotEmpty) {
    state = MyModuleState.fromDraftJson(draft.data);
    return draft;
  }
  return null;
}

Future<void> clearDraft({String? docId}) async {
  final key = _getDraftKey(docId: docId);
  await _draftStorage.clearDraft(key);
}
```

### Paso 4: Auto-guardado Reactivo en Mutadores
En todos los métodos mutadores del Notifier (`setClient`, `addItem`, `updateDescription`, etc.), invoca `autoSaveDraft()` al final:
```dart
void setClient(Client client) {
  state = state.copyWith(clientId: client.id, clientName: client.name);
  autoSaveDraft();
}
```

### Paso 5: Ciclo de Vida y Detección en la Pantalla (UI)
En el `StatefulWidget` de la pantalla (ej. `CreateMyDocScreen` o `MyDocDetailsScreen`):

```dart
class _MyScreenState extends ConsumerState<MyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Auto-save al cambiar de pestaña
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref.read(myProvider.notifier).autoSaveDraft(
          tabIndex: _tabController.index,
          docId: widget.docId,
        );
      }
    });

    // Auto-save al pausar o minimizar la app
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref.read(myProvider.notifier).autoSaveDraft(
          tabIndex: _tabController.index,
          docId: widget.docId,
        );
      },
      onInactive: () {
        ref.read(myProvider.notifier).autoSaveDraft(
          tabIndex: _tabController.index,
          docId: widget.docId,
        );
      },
    );

    // Verificación y Restauración al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(myProvider);

      if (widget.docId != null) {
        // MODO EDICIÓN
        final draft = await ref.read(myProvider.notifier).checkAndRestoreDraft(docId: widget.docId);
        if (draft != null && mounted) {
          setState(() => _tabController.index = draft.tabIndex);
          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () => _handleDiscard(isEdit: true),
          );
        } else {
          ref.read(myProvider.notifier).loadFromDb(widget.docId!);
        }
      } else {
        // MODO CREACIÓN
        if (currentState.id != null) {
          ref.read(myProvider.notifier).reset(clearPersistedDraft: false);
        }

        final draft = await ref.read(myProvider.notifier).checkAndRestoreDraft();
        if (draft != null && mounted) {
          setState(() => _tabController.index = draft.tabIndex);
          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () => _handleDiscard(isEdit: false),
          );
        }
      }
    });
  }

  Future<void> _handlePop() async {
    final state = ref.read(myProvider);
    final hasChanges = state.hasChanges;
    final currentId = widget.docId ?? state.id;

    // 1. Guardar inmediatamente en disco sin esperar el debounce
    await ref.read(myProvider.notifier).saveDraftNow(
      tabIndex: _tabController.index,
      docId: currentId,
    );
    // 2. Limpiar memoria local sin borrar el borrador de disco
    ref.read(myProvider.notifier).reset(
      clearPersistedDraft: false,
      docId: currentId,
    );
    if (!mounted) return;

    // 3. Notificar al usuario que su progreso quedó seguro
    if (hasChanges) {
      AppToast.info(
        context,
        message: 'Cambios guardados temporalmente',
        icon: Icons.bookmark_added_outlined,
      );
    }

    context.pop();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
```

### Paso 6: Limpieza y Preservación de Borradores (`clearDraft`)
- **Al Salir o Navegar hacia Atrás:** El borrador se guarda inmediatamente en disco (`saveDraftNow`) y se preserva. **NUNCA** se debe borrar el borrador al presionar Atrás.
- **Al Guardar en BD con éxito:** Invocar `clearDraft()` (para creación o edición según corresponda).
- **Al Descartar Explícitamente:** Solo cuando el usuario presiona el botón "Descartar" en el `DraftToast` o en el menú de acciones (`...` -> "Descartar borrador"), se muestra el diálogo de confirmación y se invoca `clearDraft()` seguido de `reset(clearPersistedDraft: true)`.
