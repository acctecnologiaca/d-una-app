---
name: standardize_search_ui
description: Create a standardized search screen using GenericSearchScreen and FilterBottomSheet, matching the UI/UX of product_search_screen.dart.
---

# Standardize Search UI

This skill guides you through creating a search screen that adheres to the D'Una App UI/UX standards. The pattern relies heavily on `GenericSearchScreen` for layout/logic and `FilterBottomSheet` for filter interactions.

## 1. Prerequisites
- **Data Model**: You must have a model class (e.g., `Product`, `Client`).
- **Provider**: You need an `AsyncValue` data source (e.g., `productsProvider`).
- **Item Widget**: A card widget to display results (e.g., `InventoryItemCard`).

## 2. File Structure
Create the file in `lib/features/{{feature_name}}/presentation/screens/{{entity_name}}_search_screen.dart`.

## 3. Implementation Pattern
The screen should be a `ConsumerStatefulWidget` to manage filter state and access Riverpod.

### Required Imports
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/generic_search_screen.dart'; // Adjust path
import '../../../../shared/widgets/filter_bottom_sheet.dart'; // Adjust path
import '../../../../core/utils/string_extensions.dart'; // For .normalized
```

### Class Structure
1.  **State**: Define local `Set<String>` variables for each filter (e.g., `_selectedCategories`).
2.  **Build**:
    -   Watch your provider: `final dataAsync = ref.watch(myProvider);`
    -   Return `GenericSearchScreen<T>`.

### Configuring GenericSearchScreen
Pass the following parameters:

-   **`hintText`**: e.g., 'Buscar clientes...'.
-   **`historyKey`**: Unique string for SharedPreferences (e.g., `'client_search_history'`).
-   **`data`**: The `AsyncValue` form the provider.
-   **`onResetFilters`**: Callback to clear local filter sets `setState(() { ... })`.
-   **`itemBuilder`**: Function returning your Item Widget (`Padding` with vertical 4.0 is recommended).
-   **`filters`**: List of `FilterChipData`.

### Implementing Filters
For each filter (e.g., Brand, Category):
1.  **Label**: Use a helper like `_getChipLabel` to show "Name" or "Name +X".
2.  **OnTap**:
    -   Access data using `dataAsync.whenData`.
    -   Extract available options from the list (map -> toSet -> toList).
    -   Call `FilterBottomSheet.showMulti` (or `showSingle`).
    -   On apply, update the local Set and call `setState`.

### Logic Filter (`filter` param)
Implement the predicate `(item, query) => bool`:
1.  Normalize query: `final normalizedQuery = query.normalized;`.
2.  Check text match: `item.name.normalized.contains(normalizedQuery)`.
3.  Check filter matches: `_selectedFilters.isEmpty || _selectedFilters.contains(item.field)`.
4.  Return `matchesQuery && matchesFilter1 && ...`.

## 4. Reference Implementation
See `lib/features/portfolio/presentation/screens/product_search_screen.dart` for the canonical example.
