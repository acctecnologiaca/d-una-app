---
name: standardize_list_screen_ui
description: Estándar oficial y completo para pantallas de listado principal (Cotizaciones, Reportes, Clientes, Inventario). Incluye cabecera dual (normal vs selección múltiple), CustomSearchBar con navegación, SortSelector, PaginatedListView, anuncios reactivos, estados vacíos y FAB extendido.
---

# Standardize Main List Screen UI Skill (Arquetipo 1)

Esta guía define el estándar arquitectónico y visual mandatorio para construir o refactorizar pantallas de listado principal en D'Una App.
Referencias canónicas en el proyecto:
- [`quotes_list_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/quotes_list/screens/quotes_list_screen.dart)
- [`client_list_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/client_list_screen.dart)

---

## 1. Anatomía Obligatoria de la Pantalla

Una pantalla de listado principal consta de los siguientes bloques ordenados verticalmente dentro de un `Scaffold` con `backgroundColor: colors.surface`:

```text
Scaffold (backgroundColor: colors.surface)
  └── SafeArea
        └── Column
              ├── 1. Cabecera Adaptativa (Normal con UserProfileAvatar / Modo Selección)
              ├── 2. Barra de Búsqueda (CustomSearchBar en modo navegación)
              ├── 3. Barra de Ordenamiento (SortSelector en Row)
              ├── 4. Lista Paginada (PaginatedListView dentro de Expanded)
              │     ├── Items (Cards de la entidad)
              │     ├── Banners publicitarios (si aplica)
              │     ├── EmptyListState (si no hay resultados)
              │     └── FriendlyErrorWidget (si hay fallo de red)
              └── FloatingActionButton: CustomExtendedFab (oculto en selección)
```

---

## 2. Implementación Paso a Paso

### Paso 1: Configurar el Estado Asíncrono, Selección y Ciclo de Vida
La pantalla debe ser un `ConsumerStatefulWidget` e implementar `WidgetsBindingObserver` para refrescar los datos automáticamente cuando la app pase a primer plano (`resumed`):

```dart
class MyEntityListScreen extends ConsumerStatefulWidget {
  const MyEntityListScreen({super.key});

  @override
  ConsumerState<MyEntityListScreen> createState() => _MyEntityListScreenState();
}

class _MyEntityListScreenState extends ConsumerState<MyEntityListScreen>
    with WidgetsBindingObserver {
  SortOption _currentSort = SortOption.recent;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(paginatedMyEntityProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }
```

---

### Paso 2: Cabecera Adaptativa (Normal vs Selección Múltiple)
La cabecera debe alternar automáticamente según el estado reactivo `selection.isSelectionMode`:

```dart
Widget _buildNormalHeader(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<UserProfile?> userProfileAsync,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        Text(
          'Mis Cotizaciones',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        const UserProfileAvatar(),
      ],
    ),
  );
}

Widget _buildSelectionHeader(
  BuildContext context,
  WidgetRef ref,
  EntitySelectionState selection,
  List<EntityModel> allItems,
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

### Paso 3: Barra de Búsqueda en Modo Navegación
En las pantallas de lista principal, la barra de búsqueda debe tener `readOnly: true` para que al pulsarla navegue a la pantalla dedicada de búsqueda a pantalla completa:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: CustomSearchBar(
    hintText: 'Buscar...',
    readOnly: true,
    showFilterIcon: true,
    onFilterTap: () => context.push('/my-entity/search'),
    onTap: () => context.push('/my-entity/search'),
  ),
),
const SizedBox(height: 16),
```

---

### Paso 4: Selector de Ordenamiento (`SortSelector`)
Usa el widget [`SortSelector`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/sort_selector.dart) dentro de una fila (`Row`) alineada a la izquierda con padding estándar:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Row(
    children: [
      SortSelector(
        currentSort: _currentSort,
        onSortChanged: (val) {
          setState(() => _currentSort = val);
          ref.read(paginatedMyEntityProvider.notifier).updateSort(val);
        },
      ),
    ],
  ),
),
```

---

### Paso 5: Lista Paginada Infinita con `PaginatedListView`
No uses `ListView.builder` crudo en listas que consulten backend. Utiliza [`PaginatedListView`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/paginated_list_view.dart) dentro de un `Expanded`:

```dart
Expanded(
  child: PaginatedListView<EntityModel>(
    state: paginatedStateAsync,
    onLoadMore: () => ref.read(paginatedMyEntityProvider.notifier).loadMore(),
    onRefresh: () async => ref.read(paginatedMyEntityProvider.notifier).refresh(),
    itemBuilder: (context, index, item) {
      // Inserción opcional de banner publicitario usando AdListPositionHelper
      if (isAdsEnabled && AdListPositionHelper.shouldShowAd(index)) {
        return Column(
          children: [
            EntityCard(
              entity: item,
              isSelectionMode: selection.isSelectionMode,
              isSelected: selection.isSelected(item.id),
              onTap: () { ... },
              onLongPress: () => ref.read(entitySelectionProvider.notifier).toggle(item.id),
            ),
            const SizedBox(height: 16),
            AdBannerWidget(...),
          ],
        );
      }

      return EntityCard(
        entity: item,
        isSelectionMode: selection.isSelectionMode,
        isSelected: selection.isSelected(item.id),
        onTap: selection.isSelectionMode
            ? () => ref.read(entitySelectionProvider.notifier).toggle(item.id)
            : () => context.push('/my-entity/view/${item.id}'),
        onLongPress: () => ref.read(entitySelectionProvider.notifier).toggle(item.id),
      );
    },
    emptyState: const EmptyListState(
      message: 'No hay elementos registrados',
      icon: Symbols.folder_open,
    ),
    errorStateBuilder: (context, error) => FriendlyErrorWidget(
      error: error,
      onRetry: () => ref.read(paginatedMyEntityProvider.notifier).refresh(),
    ),
  ),
)
```

---

### Paso 6: Floating Action Button Extendido (`CustomExtendedFab`)
El FAB debe ser del tipo [`CustomExtendedFab`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_extended_fab.dart) y **debe ocultarse dinámicamente (`null`) cuando el modo de selección esté activo**:

```dart
floatingActionButton: selection.isSelectionMode
    ? null
    : CustomExtendedFab(
        onPressed: () => context.push('/my-entity/create'),
        icon: Icons.add,
        label: 'Nuevo',
      ),
```

> [!IMPORTANT]
> **Prohibición de Padding Artificial:** El FAB reposa directamente sobre el `Scaffold` siguiendo Material Design 3 nativo. Queda **estrictamente prohibido** envolverlo en `Padding(bottom: 40.0)`. La separación con el contenido desplazable se maneja automáticamente en la lista mediante `FabScrollPadding.list` (`88.0px`).

---

## 3. Checklist de Verificación para Listas Principales

- [ ] ¿El fondo del `Scaffold` es `colors.surface`?
- [ ] ¿La cabecera cambia a modo selección con el número de elementos y botón de cerrar?
- [ ] ¿La barra de búsqueda tiene `readOnly: true` y redirige a la ruta `/search`?
- [ ] ¿El ordenamiento usa el modal `SortSelector`?
- [ ] ¿La lista utiliza `PaginatedListView` con `emptyState`, `errorStateBuilder` y clearance inferior `FabScrollPadding.list` (`88.0px`)?
- [ ] ¿El FAB extendido reposa directamente sobre el `Scaffold` sin envoltorios `Padding(bottom: 40.0)`?
- [ ] ¿El FAB extendido desaparece en modo selección múltiple?
- [ ] ¿Si la pantalla es standalone (sin `BottomNavigationBar`), el cuerpo está envuelto en `SafeArea(child: Column(...))`?
- [ ] ¿Se implementa `WidgetsBindingObserver` para auto-refrescar en `resumed`?
