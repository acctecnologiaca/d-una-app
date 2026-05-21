# Auditoría de Arquitectura: D-UNA App

Este documento presenta un mapeo del estado real actual del proyecto "D-UNA App", detallando su estructura, configuraciones, capas arquitectónicas, reglas de negocio y flujos internos para sincronizar a los agentes de IA.

## 1. Árbol de Directorios Real (`/lib`)

El proyecto está estructurado bajo los principios de Clean Architecture, separando responsabilidades transversalmente y por módulo.

```text
/lib
├── core/                  # Utilidades y configuraciones transversales
│   ├── constants/         # Constantes globales de la app
│   ├── pdf/               # Generación y manejo de PDFs
│   ├── router/            # Configuración de go_router (app_router.dart, router_notifier.dart)
│   ├── services/          # Servicios core (ej. whatsapp_repository.dart)
│   ├── theme/             # Definiciones de Material Design 3
│   └── utils/             # Funciones utilitarias (ej. validators.dart)
├── features/              # Módulos de negocio implementados
│   ├── auth/              # Autenticación de usuarios
│   ├── clients/           # Gestión de clientes
│   ├── collaborators/     # Gestión de colaboradores
│   ├── home/              # Dashboard principal
│   ├── portfolio/         # Portafolio / Inventario
│   ├── profile/           # Perfil de usuario
│   ├── purchases/         # Gestión de compras
│   ├── quotes/            # Cotizaciones (create, view, list)
│   ├── reports/           # Reportes financieros / operativos
│   └── settings/          # Configuración de la app (catálogos, envíos, métodos, etc.)
├── shared/                # Componentes de UI compartidos
│   ├── screens/           # Pantallas genéricas (ej. pdf_preview_screen.dart)
│   └── widgets/           # Widgets reusables (ej. custom_text_field.dart, generic_list_screen.dart)
└── main.dart              # Punto de entrada de la aplicación
```

## 2. Archivos Clave de Configuración

### `pubspec.yaml`
El proyecto tiene definidas las siguientes dependencias críticas (basado en `pubspec.yaml` versión 1.0.0+1):
- **Backend / DB:** `supabase_flutter` (^2.8.2) para backend as a service, autenticación y base de datos.
- **Manejo del Estado:** `flutter_riverpod` (^2.5.1) y `riverpod_annotation` (^2.3.5) con generación de código.
- **Rutas:** `go_router` (^14.8.0).
- **Persistencia Local:** `shared_preferences` (^2.5.4) (no se detecta SQLite/Isar para sincronización compleja offline).
- **Otras dependencias importantes:** `json_annotation`/`json_serializable` para serialización de DTOs, `pdf` y `printing` para generación de documentos.

### `analysis_options.yaml`
- Se incluye `package:flutter_lints/flutter.yaml`.
- Aplica las reglas estándar recomendadas para Flutter.

### Variables de Entorno (`.env`)
- No se han detectado esquemas locales basados en paquetes como `flutter_dotenv` integrados en el `pubspec.yaml` actual, por lo que las llaves de Supabase se están manejando a nivel de inicialización en `main.dart` directamente o a través de otro mecanismo inyectado.

## 3. Estado de las Capas (Clean Architecture)

Las features más avanzadas ya implementan el esquema de Clean Architecture con sus 3 capas principales (`data`, `domain` y `presentation`):

- **Feature: `portfolio`**
  - **`data/`:** Implementaciones de repositorios y DTOs del inventario.
  - **`domain/`:** Entidades y reglas lógicas como utilidades de validación (`ProductValidators`).
  - **`presentation/`:** Contiene sub-features como `inventory`, `suppliers_directory` (con pantallas, providers generados por @riverpod y widgets específicos) y la vista principal `portfolio_screen.dart`.

- **Feature: `quotes`**
  - **`data/` & `domain/`:** Lógica de datos de cotizaciones.
  - **`presentation/`:** Pantallas divididas lógicamente en `create_quote`, `quotes_list` y `view_quote`.

- **Feature: `settings`** (Altamente desarrollada)
  - **`presentation/`:** Extensa cantidad de pantallas y Data Providers (`brands_list_screen.dart`, `categories_list_screen.dart`, `add_edit_*_sheet.dart`) implementando BottomSheets estándar para CRUDs rápidos.

## 4. Reglas de Negocio Ya Codificadas

Para no romper el código actual, todo agente debe respetar las siguientes implementaciones transversales:

- **Validadores:** 
  - Existen validadores globales en `lib/core/utils/validators.dart` (`Validators`).
  - Existen validadores específicos de dominio, como `ProductValidators` en `lib/features/portfolio/domain/utils/product_validators.dart`.
- **Lógica Asíncrona (Sync):**
  - La aplicación **no** posee una lógica compleja offline-first con SQLite o Hive en su estado actual. Se basa primordialmente en la carga asíncrona de datos desde Supabase y el uso generalizado de `AsyncValue` (Riverpod) para representar los estados de carga en pantallas genéricas compartidas (ej. `GenericListScreen`).
- **Interceptores:** 
  - No hay interceptores HTTP clásicos (tipo Dio) declarados formalmente, ya que la conexión principal con el backend es directa mediante el SDK nativo de `supabase_flutter`.

## 5. Flujos Internos (`.agent`)

El espacio de trabajo cuenta con guías y guardarraíles vitales definidos en el directorio `.agent/` que rigen el comportamiento de las IA:

- **`.agent/workflows/` (Protocolos Paso a Paso):**
  1. `bug_resolution_protocol.md` (Protocolo estricto para solución de bugs).
  2. `create_feature_scaffold.md` (Creación de nueva feature Clean Architecture).
  3. `create_wizard_step.md` (Paso a paso para flujos de asistentes/wizards).
  4. `integrate_api_endpoint.md` (Integración con backend).
  5. `safety_check.md` (Checklist obligatorio para evitar daños críticos).
  6. `standardize_screen_ui.md` (Estandarización de interfaz usando `/lib/shared`).

- **Guardarraíles / Skills Activos:**
  - `development_safety_guardrails`: Reglas obligatorias para no causar regresiones (especialmente en políticas RLS de base de datos o lógica núcleo).
  - Uso de estandarizadores de UI (`standardize_details_ui`, `standardize_form_screen`, `standardize_list_main_screen_ui`, `standardize_search_ui`) basándose en los componentes de `/lib/shared/`.
