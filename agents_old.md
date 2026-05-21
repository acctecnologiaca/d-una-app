# Agent Rules & Project Standards

This file defines the interaction rules and technical standards for AI agents working on the **d_una_app** project. Adhering to these rules is mandatory to ensure consistency and environmental compatibility.

## 1. Environment & Shell Standards (Windows 10)
- **Operating System**: Windows 10.
- **Shell**: PowerShell is the primary shell.
- **Commands**: 
    - DO NOT use native Linux commands that lack direct, high-fidelity aliases in PowerShell (e.g., avoid `grep`, `cat` if possible).
    - PREFER internal agent tools like `view_file` for reading and `grep_search` for searching.
    - Use PowerShell-native commands if shell access is necessary (e.g., `Get-Content`, `Select-String`).
    - Always use absolute paths or paths relative to the project root.

## 2. Technical Stack
- **Framework**: Flutter (Material Design 3).
- **Language**: Dart.
- **State Management**: `flutter_riverpod` with `riverpod_generator`.
- **Backend/Database**: `supabase_flutter`.
- **Routing**: `go_router`.
- **Localization**: `intl` (Standard Flutter localization).
- **Serialization**: `json_serializable`.

## 3. Architecture & Project Structure
- **Pattern**: Clean Architecture (Layered by feature).
- **Core Directory (`/lib/core`)**: Cross-cutting concerns, common utilities, and theme definitions.
- **Features Directory (`/lib/features`)**: Business logic modules. Each feature follows:
    - `data/`: Repositories, Data Sources, Models (DTOs).
    - `domain/`: Entities, Use Cases (if applicable), Repository Interfaces.
    - `presentation/`: BLoC/Providers, Widgets, Screens.
- **Shared Directory (`/lib/shared`)**: Reusable UI components and widgets across features.

## 4. Coding Standards
- **Linter**: Strictly follow `analysis_options.yaml`.
- **Immutability**: Use `final` for variables and `const` for constructors/widgets whenever possible.
- **Providers**: Use the `@riverpod` annotation (Code Generation) for creating providers.
- **Comments**: All code documentation and internal comments must be in **English**.
- **Naming**: 
    - Classes: `PascalCase`.
    - Variables/Functions: `camelCase`.
    - Files: `snake_case`.

## 5. Git & Workflow
- **Commit Messages**: Follow **Conventional Commits** format.
    - `feat:` (new feature)
    - `fix:` (bug fix)
    - `docs:` (documentation changes)
    - `style:` (formatting, missing semi-colons, etc; no code change)
    - `refactor:` (refactoring production code)
    - `test:` (adding missing tests, refactoring tests)
    - `chore:` (updating grunt tasks etc; no production code change)
- **Branching**: Context-aware branching (if managed by agent).

## 6. Communication with User
- **Language**: Spanish (Español) for all verbal interactions.
- **Style**: Concise, direct, and professional.
- **Safety**: Always request explicit confirmation for destructive operations (e.g., deleting files, large refactors, backend schema changes).

## 7. Mandatory Safety Protocols
- **Critical Changes**: BEFORE modifying the database schema, Supabase RPCs, or core business logic, you MUST follow the [safety_check.md](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agent/workflows/safety_check.md) workflow.
- **Regressions**: Always check the `development_safety_guardrails` skill to prevent breaking existing search logic or RLS policies.
