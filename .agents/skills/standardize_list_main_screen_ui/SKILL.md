---
name: standardize_list_screen_ui
description: Create a standardized List screen (e.g. Quotes List, Client List) featuring a CustomSearchBar, SortSelector, and FloatingActionButton (Optional).
---

# Standardize List Screen UI

This skill outlines the process for creating or refactoring a List screen to
adhere to the application's standard UI/UX patterns.

## 1. Structure Overview

A standard List Screen consists of:

1. **AppBar / Header**: Title and optional user avatar or actions.
2. **Search Bar**: `CustomSearchBar` with standardized padding.
3. **Sort Selector**: `SortSelector` widget for filtering/sorting logic.
4. **List View**: `ListView.separated` displaying the items.
5. **Floating Action Button**: For creating new items (optional).

## 2. Implementation Steps

### Step 0: Theme Access

Ensure you access the `AppTheme` colors at the start of your `build` method to
maintain consistency.

```dart
final colors = Theme.of(context).colorScheme;
```

### Step 1: Scaffold & Header

Use a `Scaffold` with `backgroundColor: colors.surface`. If using a custom
header (like in `QuotesListScreen` or `ClientListScreen`), ensure it includes
the Menu icon, Title, and Profile avatar. If using a standard AppBar (like
`OwnInventoryScreen`), use `AppBar` with standard styling
(`backgroundColor: colors.surface`, `elevation: 0`).

### Step 2: Search Bar

Implement the search bar using `CustomSearchBar`. **Standard Padding**:
`symmetric(horizontal: 16.0, vertical: 8.0)`. `readOnly: true`.

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: CustomSearchBar(
    controller: _searchController,
    hintText: 'Buscar...',
    readOnly: false, // or true if navigating to separate search screen
    showFilterIcon: true,
    onFilterTap: () {},
  ),
),
const SizedBox(height: 16),
```

### Step 3: Sort Selector

Use the standardized `SortSelector` widget. **Standard Padding**:
`symmetric(horizontal: 16.0, vertical: 8.0)`.

```dart
// Import
import '../../../../shared/widgets/sort_selector.dart';

// State
SortOption _currentSort = SortOption.recent;

// Widget
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Row(
    children: [
      SortSelector(
        currentSort: _currentSort,
        onSortChanged: (val) => setState(() => _currentSort = val),
      ),
    ],
  ),
),
```

### Step 4: Logic Implementation

Implement the sorting logic in your `build` method or a dedicated provider.

```dart
// Sort Logic Example
filteredItems.sort((a, b) {
  switch (_currentSort) {
    case SortOption.recent:
      return b.date.compareTo(a.date);
    case SortOption.nameAZ:
      return a.name.compareTo(b.name);
    case SortOption.nameZA:
      return b.name.compareTo(a.name);
  }
});
```

### Step 5: List View

Use `ListView.separated` inside an `Expanded` widget. **Separator**:
`Divider(height: 1, indent: 16, endIndent: 16, color: Colors.transparent)`.

```dart
Expanded(
  child: ListView.separated(
    itemCount: items.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.transparent),
    itemBuilder: (context, index) {
      return _buildItemTile(context, items[index]);
    },
  ),
),
```

### Step 6: Floating Action Button

If the screen requires creation actions, use `FloatingActionButton.extended`.

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {},
  label: const Text('Agregar'),
  icon: const Icon(Icons.add),
),
```

## 3. Example File Structure

Refer to `lib/features/quotes/presentation/screens/quotes_list_screen.dart` or
`lib/features/clients/presentation/client_list_screen.dart` for complete
reference implementations.
