---
name: scaffold_feature
description: Create the structure for a new feature module following Clean Architecture principles.
---

# Scaffolding a New Feature

This skill guides you through creating a new feature module in `lib/features/` following the project's Clean Architecture standards.

## 1. Context Gathering
First, understand the feature name and its primary purpose.
- **Variable**: `{{feature_name}}` (snake_case, e.g., `product_inventory`, `user_profile`)

## 2. Directory Structure
Create the following directory tree under `lib/features/{{feature_name}}/`:

```text
lib/features/{{feature_name}}/
├── data/
│   ├── models/          # Data Transfer Objects (DTOs) / Supabase Models
│   └── repositories/    # Implementation of Domain Repositories
├── domain/
│   ├── models/          # Pure Domain Entities (if different from data models)
│   └── repositories/    # Abstract Repository Interfaces
└── presentation/
    ├── providers/       # Riverpod Providers (Notifiers, StateProviders)
    ├── screens/         # UI Screens/Pages
    └── widgets/         # Feature-specific reusable widgets
```

## 3. Core Files Creation
Create these essential files to bootstrap the feature.

### Domain Layer
- **Entity**: `domain/models/{{feature_name}}_model.dart`
  - Create a class `{{FeatureName}}` (PascalCase).
  - Use `Equatable` for value comparison.
- **Repository Interface**: `domain/repositories/{{feature_name}}_repository.dart`
  - Define `abstract class {{FeatureName}}Repository`.
  - Add standard methods like `fetch`, `create`, `update`, `delete`.

### Data Layer
- **Repository Implementation**: `data/repositories/supabase_{{feature_name}}_repository.dart`
  - Implement `{{FeatureName}}Repository`.
  - Inject `SupabaseClient`.

### Presentation Layer
- **Provider**: `presentation/providers/{{feature_name}}_provider.dart`
  - Create a Riverpod provider (e.g., `AsyncNotifierProvider` or `StateNotifierProvider`).
- **Main Screen**: `presentation/screens/{{feature_name}}_screen.dart`
  - Create a `ConsumerWidget` or `ConsumerStatefulWidget`.
  - Use `Scaffold` with a standard `AppBar`.

## 4. Router Registration
- Remind the user (or automate if possible) to register the new screen in `lib/core/router/app_router.dart`.
