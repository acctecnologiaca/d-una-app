---
name: Implement Multi-selection and Batch Actions
description: Guide to implement multi-selection mode, list item toggle states, and execution of batch operations (e.g. batch archive, batch status change) using Riverpod and CustomActionSheet in a list screen.
---

# Skill: Implementación de Selección Múltiple y Acciones por Lote (Batch Actions)

Esta guía define el estándar técnico, arquitectura y paso a paso procedimental para replicar la funcionalidad de selección múltiple y ejecución de acciones masivas sobre cualquier entidad de la aplicación (por ejemplo: clientes, colaboradores, productos, compras, etc.).

---

## 🏗️ Arquitectura del Sistema de Selección

Cualquier implementación de selección múltiple consta de 4 componentes desacoplados:

```text
[ 1. Estado (Riverpod) ] <---> [ 2. Pantalla de Listado (Header dinámico) ]
           |                                     |
           v                                     v
[ 4. Notifier de Lista (Supabase) ] <---> [ 3. Item/Card de la Lista ]
           ^
           |
[ 5. Acciones de Selección (Acciones por lote / Hojas) ]
```

---

## 🛠️ Guía Paso a Paso para Desarrolladores / LLMs

### Paso 1: Definir el Estado de Selección (`selection_state.dart` o en el provider del módulo)
Define la estructura inmutable que almacenará los IDs seleccionados y si el modo de selección está activo.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntitySelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const EntitySelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  EntitySelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return EntitySelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool get isSingle => count == 1;
  bool get isMultiple => count > 1;
  bool isSelected(String id) => selectedIds.contains(id);
}

class EntitySelectionNotifier extends StateNotifier<EntitySelectionState> {
  EntitySelectionNotifier() : super(const EntitySelectionState());

  void toggle(String id) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(
      selectedIds: updated,
      isSelectionMode: updated.isNotEmpty,
    );
  }

  void selectAll(List<String> ids) {
    state = state.copyWith(selectedIds: ids.toSet(), isSelectionMode: true);
  }

  void clearSelection() {
    state = const EntitySelectionState();
  }
}

// Declaración del provider global del módulo
final entitySelectionProvider =
    StateNotifierProvider<EntitySelectionNotifier, EntitySelectionState>(
      (ref) => EntitySelectionNotifier(),
    );
```

---

### Paso 2: Integrar el Estado en la Pantalla de Listado (`entity_list_screen.dart`)
La pantalla del listado debe reaccionar al estado de selección y modificar su cabecera y el comportamiento del FloatingActionButton de creación.

1.  **Escuchar el Provider**:
    ```dart
    final selection = ref.watch(entitySelectionProvider);
    ```
2.  **Cabecera Adaptativa**:
    ```dart
    selection.isSelectionMode
        ? _buildSelectionHeader(context, ref, selection)
        : _buildNormalHeader(context, ref);
    ```
3.  **Desactivar / Ocultar el FAB**:
    ```dart
    floatingActionButton: selection.isSelectionMode
        ? null // Ocultar para evitar ruidos al seleccionar
        : CustomExtendedFab(
            onPressed: () => context.push('/entity/create'),
            icon: Icons.add,
            label: 'Nuevo',
          ),
    ```
4.  **Header de Selección (`_buildSelectionHeader`)**:
    Implementa los botones superiores de acciones comunes (archivar, eliminar, etc.) y la opción de limpiar la selección.
    ```dart
    Widget _buildSelectionHeader(
      BuildContext context,
      WidgetRef ref,
      EntitySelectionState selection,
    ) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(entitySelectionProvider.notifier).clearSelection(),
            ),
            Text(
              '${selection.count} Ítem${selection.count > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archivar seleccionados',
              onPressed: () => EntitySelectionActions.handleBatchArchive(context, ref, selection),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => EntitySelectionActions.showActionsSheet(context, ref, selection),
            ),
          ],
        ),
      );
    }
    ```

---

### Paso 3: Adaptar la Tarjeta del Elemento (`entity_card.dart` o `entity_tile.dart`)
El componente visual representativo de cada elemento en la lista debe adaptar su apariencia y gestos.

1.  **Parámetros Necesarios**:
    ```dart
    final bool isSelectionMode;
    final bool isSelected;
    final VoidCallback onTap;
    final VoidCallback onLongPress;
    ```
2.  **Comportamiento de Gestos**:
    Envolver el diseño de la tarjeta en un `InkWell` o `GestureDetector`:
    ```dart
    InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        // Cambiar borde o fondo si está seleccionado
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : theme.colorScheme.surface,
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            // Contenido normal del item (e.g. icon, text)...
            const Expanded(child: SizedBox()), // Placeholder for item content
            // Mostrar un Checkbox a la DERECHA si está en modo selección
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
              ),
          ],
        ),
      ),
    )
    ```
3.  **Lógica del constructor del item en la Lista (`ListView.builder`)**:
    ```dart
    itemBuilder: (context, index, item) {
      return EntityCard(
        entity: item,
        isSelectionMode: selection.isSelectionMode,
        isSelected: selection.isSelected(item.id),
        onLongPress: () => ref.read(entitySelectionProvider.notifier).toggle(item.id),
        onTap: selection.isSelectionMode
            ? () => ref.read(entitySelectionProvider.notifier).toggle(item.id)
            : () => context.push('/entity/view/${item.id}'),
      );
    }
    ```

---

### Paso 4: Crear la Clase de Acciones (`entity_selection_actions.dart`)
Centraliza las hojas de acción y confirmaciones en una clase utilitaria para mantener el controlador limpio.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';

class EntitySelectionActions {
  EntitySelectionActions._();

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    EntitySelectionState selection,
  ) {
    if (selection.isSingle) {
      // Obtener la entidad seleccionada de la lista en caché
      final entity = ref.read(entitiesListProvider).value!.firstWhere(
        (e) => e.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, entity);
    } else {
      _showMultiActionsSheet(context, ref, selection);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    EntitySelectionState selection,
    dynamic entity,
  ) {
    CustomActionSheet.show(
      context: context,
      title: 'Opciones',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Editar',
          onTap: () {
            Navigator.pop(context);
            ref.read(entitySelectionProvider.notifier).clearSelection();
            context.push('/entity/edit/${entity.id}');
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: 'Eliminar',
          onTap: () {
            Navigator.pop(context);
            _confirmDelete(context, ref, [entity.id]);
          },
        ),
      ],
    );
  }

  static void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    EntitySelectionState selection,
  ) {
    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        BottomSheetActionItem(
          icon: Icons.archive_outlined,
          label: 'Archivar lote',
          onTap: () {
            Navigator.pop(context);
            handleBatchArchive(context, ref, selection);
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: 'Eliminar lote',
          onTap: () {
            Navigator.pop(context);
            _confirmDelete(context, ref, selection.selectedIds.toList());
          },
        ),
      ],
    );
  }

  static Future<void> handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    EntitySelectionState selection,
  ) async {
    // Invoca la actualización masiva en el notifier del módulo
    await ref
        .read(entitiesListProvider.notifier)
        .batchArchive(selection.selectedIds.toList());
    
    // Limpia la selección
    ref.read(entitySelectionProvider.notifier).clearSelection();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elementos archivados exitosamente')),
      );
    }
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Eliminar elementos?',
        contentText: 'Esta acción no se puede deshacer y borrará los registros permanentemente.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(entitiesListProvider.notifier).batchDelete(ids);
      ref.read(entitySelectionProvider.notifier).clearSelection();
    }
  }
}
```

---

## 🚨 Reglas Críticas a Seguir (Para la LLM)

1.  **Limpiar la selección en navegación**: Siempre llama a `clearSelection()` inmediatamente antes de navegar a la pantalla de edición, creación o detalle de una entidad para evitar que la interfaz quede bloqueada en modo de selección al regresar.
2.  **Transaccionalidad en lote**: Cuando implementes las funciones `batchUpdate` o `batchDelete` en los repositorios de Supabase, utiliza transacciones individuales o queries combinadas (por ejemplo: `.in('id', ids)`) para maximizar el rendimiento de red y asegurar consistencia de datos.
3.  **Animaciones Fluidas**: Asegúrate de que los cambios de estado en `isSelectionMode` transicionen suavemente y que los checkboxes a nivel de elemento no causen saltos de layout bruscos en las tarjetas.
