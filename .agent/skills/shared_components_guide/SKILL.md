---
name: shared_components_guide
description: A comprehensive guide to the shared components, widgets, and utilities in /lib/shared/ to ensure code reuse and UI consistency.
---

# Shared Components Guide

Use this skill to identify and leverage existing components in the `/lib/shared/` directory. **ALWAYS** check this guide before creating new UI elements or logic that might already be implemented.

## Directory Structure
- `lib/shared/widgets/`: Reusable UI components (buttons, fields, bars, etc.)
- `lib/shared/utils/`: Common utility functions (formatters, etc.)
- `lib/shared/data/`: Shared data models or constants (currencies, etc.)

---

## Shared Widgets (`/lib/shared/widgets/`)

### Layout & Screens
- **[generic_list_screen.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_list_screen.dart)**: A standardized template for list screens. Includes search, sorting, async state handling (loading/error), and a FAB.
- **[generic_search_screen.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_search_screen.dart)**: Standard search UI with history management, search bar, and results list.
- **[standard_app_bar.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_app_bar.dart)**: The default AppBar for the app. Supports search mode, subtitles, and custom actions.
- **[main_navigation_drawer.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/main_navigation_drawer.dart)**: The main side menu for the application.

### List Items & Cards
- **[standard_list_item.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_list_item.dart)**: The most versatile list item. Supports leading, overline (small top text), title, subtitle, and trailing widgets.
- **[aggregated_product_card.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/aggregated_product_card.dart)**: Specialized card for products, showing stock, price, supplier count, and UOM badges.
- **[info_block.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_block.dart)**: Displays a label/value pair with an icon. Use `InfoBlock.text()` for simple text values. Ideal for details screens.

### Forms & Inputs
- **[custom_text_field.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_text_field.dart)**: Standardized text input with clear button, validation, and theme integration.
- **[custom_dropdown.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dropdown.dart)**: A powerful dropdown that supports:
    - Standard selection.
    - **Searchable** mode (Autocomplete).
    - "Add" option for creating new items inline.
- **[custom_search_bar.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_search_bar.dart)**: Rounded search bar used in app bars or search screens.
- **[custom_stepper.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_stepper.dart)**: Horizontal step indicator for wizards/processes.

### Buttons & Feedback
- **[custom_button.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_button.dart)**: Primary and secondary action buttons with loading states and optional icons.
- **[custom_extended_fab.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_extended_fab.dart)**: The standard Floating Action Button (extended version) for main screen actions.
- **[form_bottom_bar.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/form_bottom_bar.dart)**: Sticky bottom bar for forms with Cancel/Save actions.

### Overlays & Bottom Sheets
- **[custom_action_sheet.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart)**: Standardized BottomSheet for actions or selections. Use `CustomActionSheet.show()`.
- **[bottom_sheet_action_item.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/bottom_sheet_action_item.dart)**: A single row/action within a `CustomActionSheet`.
- **[filter_bottom_sheet.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/filter_bottom_sheet.dart)**: Pre-built sheet for filtering lists (supports single and multi-select).
- **[sort_selector.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/sort_selector.dart)**: Widget to trigger a sorting selection bottom sheet.
- **[price_filter_sheet.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/price_filter_sheet.dart)**: Specific sheet for filtering by price range.

### Specialized Components
- **[dynamic_material_symbol.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/dynamic_material_symbol.dart)**: Renders Material Symbols by name (SVG string), with caching support. Essential for UOM icons.
- **[barcode_scanner_screen.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/barcode_scanner_screen.dart)**: Full-screen scanner for barcodes/QR codes.
- **[wizard_progress_bar.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_progress_bar.dart)**: Progress bar for multi-step processes.
- **[wizard_bottom_bar.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_bottom_bar.dart)**: Bottom bar with Back/Next buttons for wizards.

---

## Utilities (`/lib/shared/utils/`)

- **[currency_formatter.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/utils/currency_formatter.dart)**: Utility to format doubles into currency strings (e.g., "$ 1.234,56").

## Data (`/lib/shared/data/`)

- **[currencies.dart](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/data/currencies.dart)**: Data structures for currency configurations.

---

## Best Practices
1. **Reuse over Rebuild**: If a feature needs a list, check `GenericListScreen` first.
2. **Standard List Items**: Use `StandardListItem` for almost all lists to maintain visual rhythm.
3. **Consistency**: Use `CustomButton` and `CustomTextField` instead of raw Flutter material widgets to ensure the theme is respected.
4. **Icons**: Use `DynamicMaterialSymbol` when icon names come from the database (like UOM symbols).
