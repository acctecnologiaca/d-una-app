---
name: shared_components_guide
description: Guía Maestra y Sistema de Diseño UI/UX de D'Una App. Contiene los Design Tokens oficiales, el catálogo exhaustivo clasificado de los 47 componentes compartidos en /lib/shared/widgets/, fórmulas matemáticas de padding dinámico y la matriz de decisión de arquetipos de pantalla.
---

# Master UI/UX Design System & Shared Components Guide

Esta es la **Guía Maestra y Fuente Única de Verdad de UI/UX** para D'Una App.
**REGLA MANDATORIA:** Antes de crear cualquier vista, modal, tarjeta, botón o campo de entrada nuevo, **DEBES** consultar este catálogo para reutilizar los componentes existentes de [`lib/shared/widgets/`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets). Queda estrictamente prohibido reinventar componentes ya provistos por la biblioteca compartida.

---

## 1. Design Tokens del Sistema

### A. Paleta de Colores Canónica (`AppTheme` / Material 3)
La aplicación utiliza un esquema de color armonizado basado en la semilla `Color(0xFF263547)` configurado en [`lib/core/theme/app_theme.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/core/theme/app_theme.dart). Siempre accede a los colores mediante `Theme.of(context).colorScheme`:

- **Fondos de Pantalla y Superficies:**
  - `colors.surface`: Fondo base estándar para Scaffolds, tarjetas y vistas principales (`#F8F9FF` en Light / `#111418` en Dark).
  - `colors.surfaceContainer`: Superficie de contenedores secundarios y `NavigationBar` (`#ECEEF4` en Light).
  - `colors.surfaceContainerHigh`: Fondo para encabezados contrastados, chips inactivos o bloques de tarjetas (`#EBEDF5` en Light / `#25282D` en Dark).
  - `colors.surfaceContainerHighest`: Para áreas de arrastre o bordes tenues (`#E1E2E8` en Light).
- **Acciones y Énfasis Principal:**
  - `colors.primary`: Color institucional para botones principales, acentos y encabezados de `AppBar` (`#36618E`).
  - `colors.onPrimary`: Texto e iconos sobre color primario (`#FFFFFF`).
  - `colors.primaryContainer`: Fondo para FABs principales, badges destacados o selección activa (`#D1E4FF`).
  - `colors.onPrimaryContainer`: Iconos y texto dentro de `primaryContainer` (`#194975`).
- **Acentos Secundarios y Terciarios:**
  - `colors.secondary` y `secondaryContainer`: Para acciones alternativas, tarjetas de servicios y estados intermedios.
  - `colors.tertiary` y `tertiaryContainer`: Para analíticas, tarjetas de proveedores o tags auxiliares.
- **Bordes y Divisores:**
  - `colors.outline`: Bordes principales de campos y cajas (`#73777F`).
  - `colors.outlineVariant`: Bordes estándar para `Card`, `Container` y líneas divisorias sutiles (`#C3C6CF` en Light / `#43474E` en Dark).
- **Estados de Error y Destructivos:**
  - `colors.error`: Rojo canónico para advertencias, badges de alerta y acciones destructivas (`#BA1A1A`).
  - `colors.errorContainer`: Fondo suave para banners o alertas (`#FFDAD6`).

### B. Tipografía y Escala
- **Fuente Principal:** Google Fonts **Inter** (`GoogleFonts.inter()`).
- **Jerarquía:**
  - `textTheme.headlineSmall`: Títulos principales de páginas de detalle o pasos de wizard (24px, w400-w600).
  - `textTheme.titleLarge`: Títulos de AppBar, nombres de entidades o títulos de sección (20-22px, w500).
  - `textTheme.titleMedium`: Títulos de tarjetas (`StandardListItem`, `DashboardCard`, 16px, w600).
  - `textTheme.bodyMedium`: Textos descriptivos, valores de formularios (14px).
  - `textTheme.bodySmall` / `labelSmall`: Metadatos, subtítulos de chips, horas y fechas (12px, `colors.onSurfaceVariant`).

### C. Escala de Espaciado Estándar
- `4.0 px`: Micro-espaciado entre texto e icono adyacente.
- `8.0 px`: Espaciado estándar entre elementos de una fila (`Row`) o chips.
- `12.0 px`: Separación entre campos compactos o padding interno de tarjetas.
- `16.0 px`: Margen horizontal canónico de pantalla (`EdgeInsets.symmetric(horizontal: 16)`), padding de listas y separación entre tarjetas.
- `24.0 px`: Separación vertical entre bloques temáticos de formularios (`SizedBox(height: 24)`).
- `32.0 px`: Separación vertical antes de bloques de acción final o grupos de inputs.
- `40.0 px`: Margen inferior mínimo para pantallas sin FAB o respiro para botones fijos.

### D. 📐 Regla Matemática Universal de Padding Dinámico para FABs
Cuando una vista con scroll (`SingleChildScrollView` o `ListView`) contiene Floating Action Buttons, el contenido inferior **nunca debe quedar oculto** detrás de los botones flotantes. Debe calcularse y aplicarse en el `padding` inferior del scroll view:

$$\text{bottomPadding} = \begin{cases} 
184.0\text{ px} & \text{si hay 2 FABs apilados } (40\text{px base} + 56\text{px FAB 1} + 16\text{px gap} + 56\text{px FAB 2} + 16\text{px respiro}) \\ 
112.0\text{ px} & \text{si hay 1 FAB } (40\text{px base} + 56\text{px FAB} + 16\text{px respiro}) \\ 
24.0\text{ px} & \text{si no hay ningún FAB activo} 
\end{cases}$$

```dart
final hasTwoFabs = showFab1 && showFab2;
final hasOneFab = showFab1 ^ showFab2;
final double dynamicBottomPadding = hasTwoFabs ? 184.0 : (hasOneFab ? 112.0 : 24.0);

SingleChildScrollView(
  padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: dynamicBottomPadding),
  child: ...
)
```

---

## 2. Catálogo Exhaustivo Clasificado de Componentes Compartidos (`/lib/shared/widgets/`)

### 📌 A. Navegación, Shell y Estructura Base
1. **[`standard_app_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_app_bar.dart)**: AppBar institucional con soporte para título, subtítulo, botón de regreso y acciones personalizadas (`actions`).
2. **[`main_navigation_drawer.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/main_navigation_drawer.dart)**: Menú lateral principal con navegación entre los módulos del sistema (Cotizaciones, Clientes, Reportes, Ajustes, etc.).
3. **[`generic_list_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_list_screen.dart)**: Plantilla base genérica para pantallas de listado con búsqueda y estados asíncronos.
4. **[`generic_search_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_search_screen.dart)**: Estructura estándar para vistas de búsqueda interactiva a pantalla completa con historial local (`SharedPreferences`), barra de búsqueda autoenfocada y chips de filtro.

---

### 📌 B. Entradas de Datos, Formularios y Selectores
5. **[`custom_text_field.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_text_field.dart)**: Campo de texto estándar con botón de limpieza (`clear`), validación integrada, soporte multilínea, formato monetario y estilos del tema.
6. **[`custom_dropdown.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dropdown.dart)**: Dropdown configurable con soporte para selección simple, modo autocompletado con búsqueda y botón para agregar nuevos ítems en línea.
7. **[`custom_multi_dropdown.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_multi_dropdown.dart)**: Selector desplegable para selección múltiple con chips visuales y diálogo modal optimizado para colecciones grandes.
8. **[`custom_stepper.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_stepper.dart)**: Control numérico con botones decrementar/incrementar (`-` / `+`) para valores enteros o porcentajes.
9. **[`editable_quantity_stepper.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/editable_quantity_stepper.dart)**: Stepper interactivo de cantidad donde el usuario puede pulsar sobre el número para escribirlo directamente mediante el teclado numérico.
10. **[`custom_location_picker.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_location_picker.dart)**: Selector estandarizado y reactivo de País, Estado/Provincia y Ciudad.
11. **[`form_bottom_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/form_bottom_bar.dart)**: Barra inferior fija para formularios con botones de Cancelar (`TextButton`) y Guardar (`FilledButton`), con indicador de carga integrado.

---

### 📌 C. Listas, Paginación, Tarjetas y Estados
12. **[`paginated_list_view.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/paginated_list_view.dart)**: Vista de lista con paginación infinita automática, scroll controller desacoplado y separadores transparentes estándar.
13. **[`standard_list_item.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_list_item.dart)**: ListTile versátil con soporte para `overline` (categoría/código), título en negrita, subtítulo informativo, leading y trailing personalizado.
14. **[`aggregated_product_card.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/aggregated_product_card.dart)**: Tarjeta especializada para inventario que muestra stock consolidado, precio, cantidad de proveedores y badges de UOM.
15. **[`service_list_item.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/service_list_item.dart)**: Ítem especializado para la lista de servicios propios del portafolio.
16. **[`collapsible_card_block.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/collapsible_card_block.dart)**: Tarjeta expandible/colapsable para organizar secciones densas de información.
17. **[`expandable_action_card.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/expandable_action_card.dart)**: Tarjeta con encabezado desplegable y acciones rápidas integradas.
18. **[`info_block.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_block.dart)**: Visualizador de datos clave-valor con icono. Usar `InfoBlock.text(icon: ..., label: ..., value: ...)` para pantallas de detalle.
19. **[`empty_list_state.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/empty_list_state.dart)**: Widget de estado vacío con ilustración/icono, mensaje explicativo y botón de acción opcional.
20. **[`friendly_error_widget.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/friendly_error_widget.dart)**: Widget para capturar y mostrar errores de red o consulta con botón de reintentar (`Retry`).

---

### 📌 D. Búsqueda, Filtros y Ordenamiento
21. **[`custom_search_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_search_bar.dart)**: Campo de búsqueda redondeado con icono de lupa, botón de borrado rápido y botón de filtros opcional. Soporta modo `readOnly: true` para redirigir a pantalla completa.
22. **[`filter_bottom_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/filter_bottom_sheet.dart)**: Modal estándar para filtros con búsqueda interna, modo selección simple (`showSingle`) o múltiple (`showMulti`).
23. **[`price_filter_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/price_filter_sheet.dart)**: Modal especializado para ingresar rangos de precios (mínimo - máximo).
24. **[`sort_selector.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/sort_selector.dart)**: Selector desplegable que abre un modal con las opciones de ordenamiento (`SortOption`).
25. **[`horizontal_filter_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/horizontal_filter_bar.dart)**: Barra horizontal de scroll con chips para filtrar activamente en vistas de búsqueda.
26. **[`searchable_selection_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/searchable_selection_sheet.dart)**: Bottom sheet con barra de búsqueda para seleccionar entidades de catálogos extensos.

---

### 📌 E. Procesos y Wizards
27. **[`wizard_progress_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_progress_bar.dart)**: Barra segmentada de progreso para indicar visualmente el avance en flujos por pasos (`currentStep` / `totalSteps`).
28. **[`wizard_bottom_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_bottom_bar.dart)**: Barra inferior de navegación para wizards con botón de Cancelar a la izquierda y Atrás/Siguiente/Finalizar a la derecha.

---

### 📌 F. Botones y FABs
29. **[`custom_button.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_button.dart)**: Botón estilizado primario y secundario con soporte para estado de carga (`isLoading`) e icono.
30. **[`custom_extended_fab.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_extended_fab.dart)**: FAB extendido oficial para pantallas principales de listado (con icono `Icons.add` y etiqueta "Nuevo"). Debe ocultarse automáticamente durante el modo selección.

---

### 📌 G. Feedback, Notificaciones, Avisos y Diálogos
31. **[`app_toast.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/app_toast.dart)**: Sistema estándar de feedback flotante. Usar siempre `AppToast.showSuccess(context, '...')` o `AppToast.showError(context, '...')` en lugar de `SnackBar` manuales o crudos.
32. **[`draft_toast.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/draft_toast.dart)**: Notificación interactiva que informa al usuario sobre la recuperación de un borrador local, con acción de descarte rápido.
33. **[`draft_recovery_banner.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/draft_recovery_banner.dart)**: Banner persistente superior para advertir sobre la presencia de un borrador no guardado.
34. **[`custom_dialog.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dialog.dart)**: Diálogos modales con soporte para confirmaciones estándar y acciones destructivas en rojo (`CustomDialog.destructive`).
35. **[`no_internet_blocking_overlay.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/no_internet_blocking_overlay.dart)**: Capa de bloqueo con diseño de desconexión cuando se pierde la conexión de red.
36. **[`credit_banner_card.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/credit_banner_card.dart)**: Banner financiero que muestra límite de crédito disponible y balance consumido.
37. **[`info_disclaimer_card.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_disclaimer_card.dart)**: Tarjeta informativa con fondo suave para notas legales o aclaratorias.

---

### 📌 H. Badges, Iconografía y Avatares
38. **[`status_badge.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/status_badge.dart)**: Badge compacto con color contextual para estatus (Aprobado, Pendiente, Rechazado, etc.).
39. **[`uom_status_badge.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart)**: Badge que combina icono dinámico de Unidad de Medida (UOM) y texto de estatus.
40. **[`dynamic_material_symbol.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/dynamic_material_symbol.dart)**: Renderizador de Material Symbols dinámicos desde cadenas de texto (SVG/nombre) con caché en memoria.
41. **[`product_image_avatar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/product_image_avatar.dart)**: Contenedor con fallback elegante para miniaturas de productos.
42. **[`user_profile_avatar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/user_profile_avatar.dart)**: Avatar del usuario autenticado para encabezados principales.
43. **[`custom_menu_tile.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_menu_tile.dart)**: Fila de menú estilizada con icono, título y flecha de navegación para dashboards (Ajustes, Perfil).

---

### 📌 I. Hojas de Acción y Envío
44. **[`custom_action_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart)**: Hoja inferior estándar para desplegar menús de opciones y acciones (`CustomActionSheet.show(...)`).
45. **[`bottom_sheet_action_item.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/bottom_sheet_action_item.dart)**: Fila individual de acción dentro de un `CustomActionSheet`.
46. **[`send_document_email_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/send_document_email_sheet.dart)**: Hoja estandarizada para envío de documentos por correo electrónico con prellenado de plantilla y destinatarios.

---

### 📌 J. Herramientas Especializadas
47. **[`barcode_scanner_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/barcode_scanner_screen.dart)**: Pantalla completa con visor de cámara para escanear códigos de barras y QR con linterna y retorno de valor.

---

## 3. Matriz de Decisión de Arquetipos de Pantalla

Al abordar la creación o rediseño de cualquier pantalla en D'Una App, consulta esta matriz para identificar el arquetipo aplicable y el skill de especialización a seguir:

| Tipo de Pantalla Requerida | Arquetipo Oficial | Skill Especializado a Consultar | Componentes Clave Obligatorios |
| :--- | :--- | :--- | :--- |
| **Listado Principal de Módulo** (Cotizaciones, Clientes, Productos, etc.) | **Arquetipo 1: Listas Principales** | [`standardize_list_main_screen_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_list_main_screen_ui/SKILL.md) | Header Dual, `CustomSearchBar` (push), `SortSelector`, `PaginatedListView`, `CustomExtendedFab`, Ads |
| **Visualización Ejecutiva de Documentos** (Cotizaciones, Reportes, Órdenes) | **Arquetipo 2: Doc View Screen** | [`standardize_document_view_screen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_document_view_screen/SKILL.md) | `TabController` (Resumen al final), `_buildInfoCard`, `_buildSummaryRow`, `ContactListTile`, FABs dinámicos |
| **Creación de Documentos o Flujos Multi-Paso** | **Arquetipo 3: Wizards & Steppers** | [`create_wizard_step`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/create_wizard_step/SKILL.md) / [`implement_draftable_module`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/implement_draftable_module/SKILL.md) | `TabBar` con auto-guardado `DraftToast` O `WizardProgressBar` + `WizardButtonBar` |
| **Ficha de Lectura de Entidad Simple** (Detalle de Producto, Detalle de Cliente) | **Arquetipo 4: Detalle de Entidad** | [`standardize_details_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_details_ui/SKILL.md) | `AppBar` con eliminar preventivo (`CustomDialog.destructive`), `InfoBlock.text`, FAB editar, `bottomPadding: 112` |
| **Formularios de Creación / Edición Directa** | **Arquetipo 5: Formularios** | [`standardize_form_screen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_form_screen/SKILL.md) | `Form` + `GlobalKey`, `CustomTextField`, `CustomDropdown`, `CustomLocationPicker`, `FormBottomBar`, `PopScope` |
| **Búsqueda Filtrada con Historial** | **Arquetipo 6: Búsqueda** | [`standardize_search_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_search_ui/SKILL.md) | `GenericSearchScreen`, historial local, `FilterBottomSheet`, `HorizontalFilterBar` |
