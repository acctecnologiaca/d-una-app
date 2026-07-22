---
description: Integrate a new API endpoint or data operation (Clean Architecture)
---

Follow these steps to add a new data operation (e.g., "fetchProduct", "updateUser") to an existing feature.

1.  **Update Domain Layer**
    -   **Repository Interface**: Open `domain/repositories/X_repository.dart`.
    -   Add the method signature (e.g., `Future<Either<Failure, Type>> methodName(Params params);`).
    -   *Optional*: If the logic is complex, create a UseCase in `domain/usecases/`.

2.  **Update Data Layer**
    -   **Datasource**: Open `data/datasources/X_datasource.dart`.
        -   Add the method definition.
        -   Implement the API call (e.g., `supabase.from('table').select()...`).
        -   Throw exceptions on error.
    -   **Repository Implementation**: Open `data/repositories/X_repository_impl.dart`.
        -   Implement the new method from the interface.
        -   Wrap the datasource call in a `try-catch` block.
        -   Return `Right(data)` on success or `Left(Failure)` on error.

3.  **Update Presentation Layer (State Management)**
    -   **Provider**: Open `presentation/providers/X_provider.dart`.
        -   Add a method to the `Notifier` or `State` class to call the repository.
        -   Update the state (loading -> success/error).
        -   Example:
            ```dart
            Future<void> methodName() async {
              state = const AsyncLoading();
              final result = await ref.read(repositoryProvider).methodName();
              result.fold(
                (failure) => state = AsyncError(failure, StackTrace.current),
                (data) => state = AsyncData(data),
              );
            }
            ```

4.  **Verify**
    -   Call the new provider method from a UI widget (e.g., in `initState` or a button callback).
    -   Verify that the data is fetched/updated correctly and errors are handled.
