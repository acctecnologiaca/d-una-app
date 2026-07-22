---
name: standardize_details_ui
description: Create a standardized Details screen (e.g. Product Details, Client Details) featuring a standard AppBar with Delete action, InfoBlock widgets for data display, and a FAB for editing.
---

# Standardize Details UI

This skill guides you through creating a "Details" screen that adheres to D'Una App UI patterns. These screens typically display read-only information about an entity (Product, Client) with options to Edit or Delete.

## 1. Prerequisites
- **Entity**: The model object to display (passed via constructor or Looked up via ID).
- **Riverpod**: Usage of `ConsumerStatefulWidget` or `ConsumerWidget` to interact with providers (especially for deletion).

## 2. Screen Structure
The screen must return a `Scaffold` with specific configurations for the AppBar, Body, and FloatingActionButton.

```dart
class MyEntityDetailsScreen extends ConsumerWidget {
  final MyEntity entity;
  const MyEntityDetailsScreen({Key? key, required this.entity}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildAppBar(context, ref, colors),
      body: _buildBody(context, colors),
      floatingActionButton: _buildEditFab(context, colors),
    );
  }
}
```

## 3. Standard Components

### A. AppBar & Delete Action
The AppBar should have:
-   **Title**: "Detalles del [Entidad]" (e.g., "Detalles del cliente").
-   **Leading**: Standard Back button.
-   **Actions**: A `delete_outline` icon button that triggers a **Confirmation Dialog**.

**Delete Logic Pattern**:
1.  Show `AlertDialog` confirming action ("¿Estás seguro...?").
2.  If confirmed (`true`), call the provider's `delete` method.
3.  On success, `context.pop()`.

```dart
IconButton(
  icon: const Icon(Icons.delete_outline),
  onPressed: () async {
    final confirm = await showDialog<bool>(...); // Standard Delete Dialog
    if (confirm == true) {
      await ref.read(myEntityProvider.notifier).deleteEntity(entity.id);
      if (context.mounted) context.pop();
    }
  },
)
```

### B. Floating Action Button (FAB)
Used for navigation to the **Edit** screen.
-   **Icon**: `Icons.edit`.
-   **Color**: `colors.primaryContainer` (background), `colors.onPrimaryContainer` (icon).
-   **Position**: Bottom right (default).

```dart
FloatingActionButton(
  onPressed: () => context.push('/path/to/edit', extra: entity),
  backgroundColor: colors.primaryContainer,
  child: Icon(Icons.edit, color: colors.onPrimaryContainer),
)
```

### C. Body Content & InfoBlocks
The body is typically a `SingleChildScrollView` containing a `Column`.

1.  **Header/Image**:
    -   If the entity has an image, display it in a Circular container (128x128) using `CachedNetworkImage`.
    -   Display primary identifier (Name) in `headline` style.
    -   Display secondary identifier (Brand/Category) in `bodyMedium`.

2.  **Data Fields (InfoBlocks)**:
    -   Use the `InfoBlock` widget (`shared/widgets/info_block.dart`) for all data fields.
    -   **InfoBlock.text**: For simple key-value pairs.
    -   **InfoBlock**: For complex content (custom rows, lists).
    -   **Icons**: Use `material_symbols_icons` or standard `Icons` consistent with the field type (e.g., `Symbols.category` for Category, `Icons.email` for Email).

```dart
InfoBlock.text(
  icon: Symbols.category,
  label: 'Categoría',
  value: entity.category,
),
```

### D. Reactive Updates (Optional but Recommended)
If the screen might be visible while the underlying data changes (e.g., returning from Edit screen):
-   Watch the list provider in `build`.
-   Look up the current entity by ID.
-   Fallback to `widget.entity` if not found (handling the "gap" before the list updates or if deleted).

## 4. Colors & Theming
-   **Background**: `colors.surface`.
-   **Text**: `colors.onSurface` for values, `colors.onSurfaceVariant` for labels/icons.
-   **Dividers/Borders**: `colors.outlineVariant`.
