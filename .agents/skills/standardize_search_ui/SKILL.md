---
name: standardize_search_ui
description: Estándar para pantallas de búsqueda interactiva y filtrado a pantalla completa (Arquetipo 6). Basado en GenericSearchScreen, historial en SharedPreferences, FilterBottomSheet y normalización de texto.
---

# Standardize Search UI Skill (Arquetipo 6)

Esta guía define el estándar para pantallas de búsqueda y filtrado interactivo a pantalla completa en D'Una App.
Referencias canónicas en el proyecto:
- [`product_search_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/portfolio/presentation/inventory/screens/product_search_screen.dart)
- [`quotes_search_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/quotes_list/screens/quotes_search_screen.dart)

---

## 1. Arquitectura de Búsqueda

Cualquier pantalla de búsqueda debe apoyarse en [`GenericSearchScreen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_search_screen.dart) en lugar de crear una barra de búsqueda manual. Este componente proporciona de forma nativa:
- Persistencia automática de términos de búsqueda recientes en `SharedPreferences`.
- Barra de búsqueda autoenfocada con botón de borrado inmediato.
- Fila superior de chips de filtro activos con contador (`"Categoría +2"`).
- Indicadores de carga, error y lista de resultados vacía.

---

## 2. Implementación Paso a Paso

```dart
class MyEntitySearchScreen extends ConsumerStatefulWidget {
  const MyEntitySearchScreen({super.key});

  @override
  ConsumerState<MyEntitySearchScreen> createState() => _MyEntitySearchScreenState();
}

class _MyEntitySearchScreenState extends ConsumerState<MyEntitySearchScreen> {
  // Conjuntos locales para almacenar los filtros activos seleccionados
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedStatuses = {};

  void _resetFilters() {
    setState(() {
      _selectedCategories.clear;
      _selectedStatuses.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(myEntityListProvider);

    return GenericSearchScreen<MyEntityModel>(
      hintText: 'Buscar registros...',
      historyKey: 'my_entity_search_history', // Clave única en SharedPreferences
      data: dataAsync,
      onResetFilters: _resetFilters,
      // Filtros desplegables en chips
      filters: [
        FilterChipData(
          label: _selectedCategories.isEmpty
              ? 'Categoría'
              : 'Categoría (${_selectedCategories.length})',
          isSelected: _selectedCategories.isNotEmpty,
          onTap: () {
            final allCategories = dataAsync.valueOrNull
                    ?.map((e) => e.category)
                    .toSet()
                    .toList() ??
                [];
            FilterBottomSheet.showMulti(
              context: context,
              title: 'Filtrar por Categoría',
              options: allCategories,
              selectedOptions: _selectedCategories,
              onApply: (selected) {
                setState(() {
                  _selectedCategories
                    ..clear()
                    ..addAll(selected);
                });
              },
            );
          },
        ),
      ],
      // Lógica de predicado de coincidencia
      filter: (item, query) {
        // 1. Normalización sin acentos ni mayúsculas
        final normalizedQuery = query.trim().toLowerCase();
        final matchesQuery = normalizedQuery.isEmpty ||
            item.name.toLowerCase().contains(normalizedQuery) ||
            item.code.toLowerCase().contains(normalizedQuery);

        // 2. Coincidencia con filtros de chip
        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(item.category);

        return matchesQuery && matchesCategory;
      },
      // Renderizador de cada resultado
      itemBuilder: (context, item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: MyEntityCard(
            entity: item,
            onTap: () => context.push('/my-entity/view/${item.id}'),
          ),
        );
      },
    );
  }
}
```

---

## 3. Checklist de Verificación para Búsqueda

- [ ] ¿Se utiliza `GenericSearchScreen` con una clave `historyKey` única?
- [ ] ¿Los filtros usan `FilterBottomSheet.showMulti` o `FilterBottomSheet.showSingle`?
- [ ] ¿La búsqueda normaliza el texto (`toLowerCase()` o `.normalized`) para ignorar mayúsculas y acentos?
- [ ] ¿Se proporciona la función `onResetFilters` para limpiar todos los chips?
