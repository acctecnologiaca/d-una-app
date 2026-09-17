---
description: Guía de Clean Architecture para crear módulos completos o integrar nuevos endpoints y operaciones
---

# Workflow: Clean Architecture

Este workflow estandariza la creación de módulos y la adición de operaciones de datos siguiendo los principios de Clean Architecture en D'Una App.

---

## 1. Crear Nuevo Módulo / Feature Completa (Scaffold)

Sigue estos pasos cuando vayas a crear una nueva feature desde cero:

### Paso 1: Estructura de Directorios
Crea la estructura dentro de `lib/features/<nombre_modulo>/`:
- `data/`
  - `datasources/` (conexiones a Supabase, HTTP o local)
  - `models/` (modelos con `fromJson` / `toJson`, serialización)
  - `repositories/` (implementaciones concretas que consumen los datasources)
- `domain/`
  - `entities/` (clases Dart puras, inmutables)
  - `repositories/` (interfaces abstractas del repositorio)
  - `usecases/` (opcional: casos de uso específicos si la lógica de negocio es compleja)
- `presentation/`
  - `providers/` (gestión de estado con Riverpod: Notifiers, State, AsyncValue)
  - `screens/` (pantallas principales y vistas)
  - `widgets/` (componentes específicos del módulo)

### Paso 2: Capa de Dominio (Domain)
1. **Entidad (`domain/entities/<entity>.dart`):** Modela la entidad como clase Dart pura sin acoplamiento a fuentes externas.
2. **Interfaz del Repositorio (`domain/repositories/<entity>_repository.dart`):** Define el contrato abstracto con métodos fuertemente tipados.

### Paso 3: Capa de Datos (Data)
1. **Modelo (`data/models/<entity>_model.dart`):** Extiende o mapea la Entidad y añade serialización `fromJson` y `toJson`.
2. **Datasource (`data/datasources/<entity>_remote_datasource.dart`):** Conexión directa a Supabase/API. Maneja llamadas y excepciones técnicas.
3. **Implementación de Repositorio (`data/repositories/<entity>_repository_impl.dart`):** Implementa la interfaz del dominio invocando el datasource.

### Paso 4: Capa de Presentación (Presentation)
1. **Provider (`presentation/providers/<entity>_provider.dart`):** Configura los providers de Riverpod (e.g. `AsyncNotifierProvider` o `StateNotifierProvider`).
2. **Pantallas y Widgets:** Diseña las pantallas (`presentation/screens/`) y widgets auxiliares (`presentation/widgets/`).

### Paso 5: Registro de Rutas
- Registra la ruta en `lib/core/router/app_router.dart`.

---

## 2. Integrar Nuevo Endpoint u Operación en Feature Existente

Sigue estos pasos para añadir una nueva operación (e.g., `fetchEntity`, `updateStatus`, `deleteItem`) a una feature existente:

### Paso 1: Actualizar Capa de Dominio
- Abre `domain/repositories/<entity>_repository.dart` y añade la firma del nuevo método.

### Paso 2: Actualizar Capa de Datos
1. Abre `data/datasources/<entity>_datasource.dart` e implementa la llamada a Supabase/API.
2. Abre `data/repositories/<entity>_repository_impl.dart`, implementa el nuevo método y maneja las excepciones técnicas.

### Paso 3: Actualizar Capa de Presentación (Riverpod)
- Abre el provider en `presentation/providers/<entity>_provider.dart`.
- Agrega el método correspondiente en el `Notifier`, gestionando los estados (`AsyncLoading`, `AsyncData`, `AsyncError`).

### Paso 4: Conectar con la UI
- Invoca el provider desde la pantalla o widget correspondiente.
- Verifica el manejo de carga y los mensajes de error o éxito mediante `AppToast`.
