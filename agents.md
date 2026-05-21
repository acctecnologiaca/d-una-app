# Agent Rules & Project Standards - D-UNA App

This file defines the interaction rules, technical standards, strict functional constraints, and true directory architectures for AI agents working on the **d_una_app** project. Adhering to these rules is mandatory to ensure codebase consistency and avoid architectural regressions.

---

## 1. Environment & Shell Standards (Windows 10)
- **Operating System**: Windows 10.
- **Shell**: PowerShell is the primary and mandatory shell.
- **Commands**: 
    - DO NOT use native Linux commands lacking exact PowerShell aliases (avoid `grep`, `cat`, `find`).
    - PREFER internal agent tools like `view_file` for reading and `grep_search` for searching codebase contents.
    - Use PowerShell-native expressions if direct shell execution is requested (e.g., `Get-Content`, `Select-String`).
    - Always use absolute paths or paths explicitly relative to the project root.

---

## 2. Technical Stack & Active Dependencies
The project relies strictly on the following stack. Do not introduce alternative state managers, routers, or persistence layers:
- **Framework**: Flutter (Material Design 3).
- **Language**: Dart.
- **Backend/Database**: `supabase_flutter` (^2.8.2) used directly via its native SDK for authentication, real-time data, and storage.
- **State Management**: `flutter_riverpod` (^2.5.1) combined with `riverpod_annotation` (^2.3.5). Explicit use of `@riverpod` code generation is mandatory.
- **Routing**: `go_router` (^14.8.0) controlled via `app_router.dart` and `router_notifier.dart`.
- **Local Settings Cache**: `shared_preferences` (^2.5.4) for basic local data caching.
- **Document Generation**: `pdf` and `printing` packages for exporting native transaction documents.
- **Serialization**: `json_annotation` with `json_serializable` for data transfer object (DTO) handling.
- **UI Localization**: Target application language is strictly **Spanish (es)**.

---

## 3. Real Project Structure & Directory Tree (`/lib`)
The codebase strictly adheres to Clean Architecture, separated transversally and by feature modules. You must match this structure exactly when expanding or creating files:

```text
/lib
├── core/                  # Cross-cutting concerns and configurations
│   ├── constants/         # Global app constants
│   ├── pdf/               # PDF rendering and handling logic
│   ├── router/            # GoRouter configurations (app_router, router_notifier)
│   ├── services/          # Core cross-feature infrastructure (e.g., whatsapp_repository)
│   ├── theme/             # Material Design 3 theme system definitions
│   └── utils/             # Global system utilities and common validations
├── features/              # Modular business features
│   ├── auth/              # 7-step onboarding and OTP authentication
│   ├── clients/           # Customer database management
│   ├── collaborators/     # Staff and field assistant indices
│   ├── home/              # Main dashboard view
│   ├── portfolio/         # Consolidated inventories and supplier catalogs
│   ├── profile/           # User settings, shipping config, wholesaler documents
│   ├── purchases/         # Expense tracking and product serial/warranty logging
│   ├── quotes/            # Hot-quoting transaction engine
│   ├── reports/           # Technical financial and field operation reports
│   └── settings/          # CRUD parameters (brands, categories, fees, templates)
├── shared/                # Highly reusable global UI layers
│   ├── screens/           # Generic display windows (e.g., pdf_preview_screen)
│   └── widgets/           # Global design widgets (custom_text_field, generic_list_screen)
└── main.dart              # Application entry point
```

Each module under `/lib/features/` must explicitly segregate its concerns into:
* `data/`: Data Sources, DTO Models, and Repository Implementations.
* `domain/`: Pure Entities, Use Cases, and Abstract Repository Interfaces.
* `presentation/`: Screens, custom specific widgets, and Riverpod Providers.

---

## 4. Coding & Validation Standards
- **Linter Compliance**: Strictly follow rules dictated inside `analysis_options.yaml` (inheriting `package:flutter_lints/flutter.yaml`).
- **Immutability**: Declare fields as `final` and enforce `const` constructors on UI elements wherever possible.
- **Comments & Documentation**: All internal developer code comments, docstrings, and technical logs must be written in **English**.
- **Naming Conventions**:
    - Classes, mixins, and extensions: `PascalCase`.
    - Variables, functions, and Riverpod instances: `camelCase`.
    - Folders and files: `snake_case`.
- **Validation Reuse**: Before writing custom validation logic, check and reuse:
    - Global rules in `lib/core/utils/validators.dart` (`Validators`).
    - Feature domain rules like `ProductValidators` in `lib/features/portfolio/domain/utils/product_validators.dart`.

---

## 5. UI Standardization & Widget Reuse
The project maximizes UI reusability to project operational formality. When generating list structures, creation screens, or detail views, you MUST implement layouts utilizing the shared ecosystem inside `/lib/shared/`:
- **Listings**: Extend or inject configurations into `GenericListScreen` found in `/lib/shared/widgets/`.
- **Forms**: Reuse `CustomTextField` and standard input configurations to maintain visual synergy.
- **Bottom Sheets**: Use standard `add_edit_*_sheet.dart` design methodologies as seen inside the `settings` feature for swift entity CRUDs.

---

## 6. Critical Business Logic Constraints (Immutable Rules)
1. **Quote Transition Triggers**: When a Quote (`quotes`) status shifts to "Aprobada", the system must automatically isolate items based on their supplier source, auto-generate corresponding Purchase Orders (`purchase_orders`) directly sent to respective wholesalers, and initiate an automated Delivery Note draft (`delivery_notes`).
2. **Technical Report Inventory Lock**: Service technical reports (`reports`) are legally and logistically constrained. They can ONLY consume items cataloged under the technician's Own Inventory (`inventario propio`) or manually typed temporary items. They MUST NOT consume Wholesaler stocks directly.
3. **Serial Number Warranty Enforcement**: The `purchases` module requires itemized, mandatory tracking of individual hardware serial numbers to systematically maintain chronological factory warranty expirations.
4. **Delivery Note Digital Signatures**: Delivery notes (`delivery_notes`) must support real-time digital screen touch signature captures and utilize device camera integrations for hardware barcode/serial parsing.
5. **Multi-Vendor Cart Logic**: The `portfolio` module must support shopping carts blending parts from multiple different wholesalers, seamlessly dispersing separate purchasing notifications to each vendor upon order confirmation.

---

## 7. Data Handling & Offline-First Roadmap
- **Current Architecture**: State is driven primarily via Riverpod’s asynchronous `AsyncValue` patterns communicating directly through the Supabase SDK backend.
- **UI State**: Always represent loading, empty, and exception states gracefully using Riverpod stream/future structures inside lists.
- **Offline Resiliency Goal**: When designing modifications to data structures, ensure repositories are ready to integrate local persistence engines (like Isar, Hive, or SQLite) seamlessly under data layers without disturbing the presentation layer's dependency on `AsyncValue` signals.

---

## 8. Mandatory Agent Workflows & Safety Guards
Before executing any file updates, code generations, or bug fixing scripts, you must read and follow the step-by-step sequential protocols declared within the `.agent/workflows/` path:
1. **`safety_check.md`**: Mandatory validation checklists to prevent core regressions or Row-Level Security (RLS) script crashes on Supabase.
2. **`bug_resolution_protocol.md`**: Fixed execution path to safely diagnose, isolate, and debug compilation or logic errors.
3. **`create_feature_scaffold.md`**: Guidelines to provision a pristine Clean Architecture feature.
4. **`create_wizard_step.md`**: Standards to add structural multi-step processes (e.g., onboarding validation).
5. **`integrate_api_endpoint.md`**: Strict connection patterns utilizing the core SDK setup.
6. **`standardize_screen_ui.md`**: Step-by-step checklist matching form, list, search, or details layout workflows against UI standardizers (`standardize_search_ui`, `standardize_details_ui`, etc.).
