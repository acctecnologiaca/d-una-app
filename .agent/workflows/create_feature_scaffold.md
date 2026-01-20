---
description: Create the structure for a new feature module (Clean Architecture)
---

Follow these steps to create a new feature module.

1.  **Create Directory Structure**
    -   Create the root folder for the feature in `lib/features/` (e.g., `lib/features/orders`).
    -   Create the following subdirectories:
        -   `data/datasources`
        -   `data/models`
        -   `data/repositories`
        -   `domain/entities`
        -   `domain/repositories`
        -   `domain/usecases` (optional, if complex logic)
        -   `presentation/providers`
        -   `presentation/screens`
        -   `presentation/widgets`

2.  **Define Domain Layer**
    -   **Entity**: Create `domain/entities/order.dart`. Define the plain Dart class.
    -   **Repository Interface**: Create `domain/repositories/orders_repository.dart`. Define the abstract class with methods (e.g., `getOrders`, `createOrder`).

3.  **Define Data Layer**
    -   **Model**: Create `data/models/order_model.dart`. Extend the Entity and add `fromJson`/`toJson`.
    -   **Datasource**: Create `data/datasources/orders_datasource.dart`. Define the interface and/or implementation for API calls (Supabase/Http).
    -   **Repository Implementation**: Create `data/repositories/orders_repository_impl.dart`. Implement the interface calling the datasource.

4.  **Define Presentation Layer**
    -   **Provider**: Create `presentation/providers/orders_provider.dart`. Use Riverpod.
        -   Define `ordersProvider` (StateNotifier or AsyncNotifier).
        -   Define `ordersRepositoryProvider` to expose the repository.
    -   **Screens**: Create initial screens in `presentation/screens/` (e.g., `orders_screen.dart`).
    -   **Widgets**: Create feature-specific widgets in `presentation/widgets/`.

5.  **Register Routes**
    -   Open `lib/core/router/app_router.dart`.
    -   Add the new routes for the feature (e.g., `/orders`).

6.  **Verify**
    -   Ensure imports are correct (avoid circular dependencies).
    -   Check that the new feature is accessible via the router.
