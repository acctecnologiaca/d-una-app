---
name: project_structure_guide
description: A comprehensive guide to the project's directory structure and file organization to help locate files quickly.
---

# Project Structure Guide

This guide outlines the organization of the Flutter project `d_una_app` to
assist in navigating the codebase and locating specific files.

## High-Level Structure

The project follows a **Feature-first** architecture with **Clean Architecture**
principles applied within each feature.

- **`lib/`**: Root of the application code.
  - **`core/`**: Core functionality, configuration, and app-wide utilities.
  - **`features/`**: Feature modules containing domain, data, and presentation
    layers.
  - **`shared/`**: Reusable components, widgets, and utilities used across
    multiple features.
  - **`main.dart`**: Application entry point.

## Directory Breakdown

### 1. `lib/features/`

Each subdirectory here represents a distinct business domain or feature set.

- **`portfolio/`**: Main product catalog and supplier directory.
  - `domain/`: Models (`aggregated_product.dart`), Repositories (interfaces).
  - `data/`: Repository implementations (`suppliers_repository.dart`), Data
    sources.
  - `presentation/`:
    - `providers/`: Riverpod providers (`suppliers_provider.dart`).
    - `screens/`: UI Screens (`product_search_screen.dart`,
      `product_suppliers_screen.dart`).
    - `widgets/`: Feature-specific widgets (`aggregated_product_card.dart`).
- **`clients/`**: Client management.
  - `presentation/screens/`: `client_search_screen.dart`,
    `client_details_screen.dart`.
- **`orders/`**: Order processing.
- **`profile/`**: User profile and authentication.
  - `presentation/providers/`: `profile_provider.dart`.

### 2. `lib/shared/`

Contains code shared across features.

- **`widgets/`**: Reusable UI components.
  - `generic_search_screen.dart`: Base screen for search functionality.
  - `horizontal_filter_bar.dart`: Reusable filter bar (chips).
  - `filter_bottom_sheet.dart`: Generic bottom sheet for filtering options.
  - `price_filter_sheet.dart`: Bottom sheet for price range filtering.
  - `custom_action_sheet.dart`: Generic action sheet.
  - `bottom_sheets/action_bottom_sheet.dart`: (Legacy/Specific) action sheet
    implementation.
  - `custom_button.dart`, `custom_text_field.dart`, etc.

### 3. `lib/core/`

- **`theme/`**: App theming and styling.
  - `app_theme.dart`: Defines `lightTheme`, `darkTheme`, and `colorScheme`.
- **`config/`**: App configuration (router, constants).

## Key File Locations

| Component Type        | Expected Location Pattern                        | Example                          |
| :-------------------- | :----------------------------------------------- | :------------------------------- |
| **Screens**           | `lib/features/<feature>/presentation/screens/`   | `product_suppliers_screen.dart`  |
| **Widgets (Feature)** | `lib/features/<feature>/presentation/widgets/`   | `aggregated_product_card.dart`   |
| **Widgets (Shared)**  | `lib/shared/widgets/`                            | `horizontal_filter_bar.dart`     |
| **Models**            | `lib/features/<feature>/domain/models/`          | `aggregated_product.dart`        |
| **Providers**         | `lib/features/<feature>/presentation/providers/` | `suppliers_provider.dart`        |
| **Repositories**      | `lib/features/<feature>/data/repositories/`      | `suppliers_repository_impl.dart` |

## Navigation Tips

1. **Search by Feature**: If working on "Suppliers", start in
   `lib/features/portfolio`.
2. **Search by Layer**:
   - UI/View logic? -> `presentation/`
   - Business Logic/State? -> `presentation/providers/`
   - Data fetching? -> `data/` or `domain/`
3. **Shared Components**: If a widget looks generic (buttons, inputs,
   comprehensive search screens), check `lib/shared/widgets/`.
4. **Entry Point**: `lib/main.dart` initializes the app and providers.

## Common Files Reference

- `lib/core/theme/app_theme.dart`: Colors and typography.
- `lib/features/portfolio/presentation/suppliers_directory/screens/product_suppliers_screen.dart`:
  Supplier branch listing.
- `lib/shared/widgets/horizontal_filter_bar.dart`: Filter chips UI.
