---
name: shared_components_guide
description: Guía Maestra y Sistema de Diseño UI/UX de D'Una App. Contiene los Design Tokens oficiales, el catálogo exhaustivo clasificado de los 48 componentes compartidos en /lib/shared/widgets/, fórmulas matemáticas de padding dinámico y la matriz de decisión de arquetipos de pantalla.
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

### D. Iconografía Oficial y Familias Canónicas
El sistema utiliza prioritariamente la familia **Material Symbols** (`material_symbols_icons/symbols.dart`) para componentes y bloques analíticos modernos, complementado por **Material Icons** para controles del sistema:
- **Garantía (Productos, Servicios, Documentos):**
  - **Con garantía activa:** `Symbols.verified_user` (Escudo con check: protección, respaldo técnico y comercial).
  - **Sin garantía:** `Symbols.shield_moon` (o `Symbols.verified_user` atenuado con `colors.onSurfaceVariant.withValues(alpha: 0.38)`).
- **Verificación de Usuario / Cuenta (Perfil):**
  - `Icons.badge_outlined` / `Symbols.badge` (Credencial o identificación personal y comercial para KYC/RIF/DNI), diferenciándose inequívocamente de los escudos de garantía.

### E. 📐 Regla Matemática Universal de Padding Dinámico para FABs (MD3 Nativo)
Cuando una vista con scroll (`SingleChildScrollView`, `ListView`, `PaginatedListView`) contiene Floating Action Buttons, el contenido inferior **nunca debe quedar oculto** detrás de los botones flotantes. Bajo el estándar nativo de Material Design 3 (sin envoltorios manuales adicionales), el botón reposa a $16\text{px}$ sobre el fondo del Scaffold (`SafeArea` o `NavigationBar`). Para garantizar una holgura de respiro visual confortable entre el contenido y el FAB más alto, se utiliza la clase canónica [`FabScrollPadding`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/utils/fab_scroll_padding.dart):

$$\text{bottomPadding}(N) = \begin{cases} 
24.0\text{ px} & \text{si } N = 0 \text{ (`FabScrollPadding.none`: sin ningún FAB activo)} \\ 
88.0\text{ px} & \text{listas paginadas (`FabScrollPadding.list`: con pie de página/footer en `PaginatedListView`)} \\
112.0\text{ px} & \text{si hay 1 FAB } (\text{`FabScrollPadding.single`: } 16\text{px base} + 56\text{px FAB} + 40\text{px clearance}) \\ 
184.0\text{ px} & \text{si hay 2 FABs apilados } (\text{`FabScrollPadding.doubleFab`: } 16\text{px base} + 112\text{px FABs} + 16\text{px gap} + 40\text{px clearance}) \\ 
256.0\text{ px} & \text{si hay 3 FABs apilados } (\text{`FabScrollPadding.tripleFab`: } 16\text{px base} + 168\text{px FABs} + 32\text{px gaps} + 40\text{px clearance}) 
\end{cases}$$

```dart
// Cálculo dinámico para vistas de documentos con N FABs (Resumen, Pestañas):
final double dynamicBottomPadding = FabScrollPadding.calculate(activeFabsCount);

SingleChildScrollView(
  padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: dynamicBottomPadding),
  child: ...
)

// Para listas principales o paginadas (PaginatedListView):
PaginatedListView<Entity>(
  // Usa por defecto FabScrollPadding.list (88.0 px) cuando hay FAB activo
  ...
)
```

#### ⚠️ Reglas Obligatorias de Integración:
1. **Prohibición de Wrappers Artificiales en FABs:** Queda **estrictamente prohibido** envolver cualquier `FloatingActionButton` o `CustomExtendedFab` dentro de `Padding(bottom: 40.0)`. Los FABs deben colocarse directamente en la propiedad `floatingActionButton` del `Scaffold`.
2. **Coordinación de `SafeArea` en Pantallas Standalone:**
   - **Pantallas con `BottomNavigationBar`** (Rutas principales `/portfolio`, `/quotes`, `/reports`, `/clients`): La barra absorbe el inset del sistema (`MediaQuery.padding.bottom = 0`), manteniendo el FAB y la lista alineados naturalmente.
   - **Pantallas Standalone (sin `BottomNavigationBar`)** (Notas de Entrega, Órdenes de Compra, Compras, Wizards, Selectores): Flutter empuja automáticamente el FAB hacia arriba según el inset del sistema (`MediaQuery.padding.bottom`). Para que la lista y el FAB mantengan su separación matemática exacta y no se encimen, el cuerpo del `Scaffold` **DEBE** envolverse siempre en `SafeArea(child: ...)` (por ejemplo, `body: SafeArea(child: Column(...))` o `body: SafeArea(child: TabBarView(...))`).
3. **Modales y Bottom Sheets con FAB Flotante (`DraggableScrollableSheet` / `Stack`):**
   - En hojas modales donde el FAB flota sobre una lista dentro de un `Stack` (como [`FilterBottomSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/filter_bottom_sheet.dart), [`CustomMultiDropdown`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_multi_dropdown.dart) o [`SelectOcSuppliersSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/view_quote/widgets/select_oc_suppliers_sheet.dart)), el FAB **DEBE** posicionarse a $16.0\text{px}$ sobre el inset del sistema:
     ```dart
     final bottomInset = MediaQuery.paddingOf(context).bottom;
     ...
     Positioned(
       bottom: 16.0 + bottomInset,
       right: 16.0,
       child: CustomExtendedFab(...),
     )
     ```
   - **Scroll Clearance:** El listado interno **DEBE** dejar un clearance inferior dinámico que compense tanto el FAB como el área segura:
     ```dart
     SizedBox(height: FabScrollPadding.single + bottomInset)
     ```
   - **Prohibición Estricta:** Queda **estrictamente prohibido** hardcodear valores como `bottom: 40`, `bottom: 24` o espaciadores fijos insuficientes como `SizedBox(height: 80)` en modales.
4. **Regla de Permanencia Estable y Bloqueo Visual en EFABs (`isEnabled: false` vs `null`):**
   - **Prohibición de Ocultar el FAB en Selectores y Búsquedas:** Queda **estrictamente prohibido** utilizar `floatingActionButton: hasSelection ? CustomExtendedFab(...) : null` en pantallas de selección de productos/servicios y búsquedas. Dado que la vista con scroll ya reserva permanentemente el espacio de respiro inferior (`FabScrollPadding.single = 112.0 px`), el botón DEBE permanecer siempre renderizado en el árbol de widgets, presentándose en estado **bloqueado / inactivo** (`isEnabled: false`) con etiqueta base (ej. `'Confirmar'`).
   - **Activación Reactiva:** En cuanto el usuario selecciona una cantidad mayor a cero con el stepper (`+`), el botón se activa reactivamente (`isEnabled: true`), adquiere elevación Material 3 (`elevation: 4`), fondo `primaryContainer` y actualiza dinámicamente su texto según la naturaleza del flujo (ej. `'Confirmar ($formattedQty $uom)'` en compras o `'Confirmar ($formattedQty $uom - $formattedTotal)'` en ventas). Al volver a cero, retorna a su estado bloqueado sin desaparecer ni alterar el layout del scroll.
   - **Acciones Secundarias de Creación en Selectores:** En selectores de catálogo (como Compras), la acción para crear una nueva entidad (ej. "Nuevo producto") no debe competir ni mutar el EFAB inferior; debe colocarse en `StandardAppBar.actions` como `IconButton(icon: Icon(Icons.add), tooltip: 'Nuevo...')`.
   - **Regla de Habilitación en Gestión de Seriales:** En pantallas de seriales (`manage_product_serials_screen.dart` y `delivery_note_manage_serials_screen.dart`), el botón `Guardar` DEBE permanecer bloqueado (`isEnabled: false`) hasta que el usuario haya agregado al menos un número de serie o haya modificado el interruptor de requerimiento de seriales frente al estado inicial (`isDirty`).
5. **Diferenciación de Tarjetas y EFABs en Selección de Productos (Venta vs Compra/Abastecimiento):**
   - **Flujos de Salida/Venta (Cotizaciones, Notas de Entrega, Facturación):** Los productos del catálogo cuentan con un precio de venta preestablecido. La tarjeta de selección muestra el precio unitario en `trailing` y el EFAB de confirmación muestra el total acumulado estimado (`Confirmar ($formattedQty $uom - $formattedTotal)`).
   - **Flujos de Entrada/Abastecimiento (Registros de Compra, Recepción de Mercancía):** El costo unitario **NO** se toma ni se fija desde el catálogo, sino que se define en la factura física o real de compra provista por el proveedor (ingresada en el modal de detalles del producto).
     - **Tarjeta de Selección ([`PurchaseProductSelectionCard`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/purchases/presentation/widgets/purchase_product_selection_card.dart)):** Queda **estrictamente prohibido** mostrar precios o costos promedio de catálogo en el slot `trailing`. El slot `trailing` debe contener exclusivamente el [`UomStatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart) indicando la unidad de medida y la cantidad seleccionada.
     - **EFAB de Confirmación:** El texto debe reflejar únicamente la cantidad y la unidad de medida a agregar (`Confirmar ($formattedQty $uom)`), sin montos calculados o precios ficticios.
6. **Estándar de Advertencias de Stock Reservado en Selección de Productos (Notas de Entrega, Reportes de Servicio):**
   - Toda tarjeta de selección de productos de inventario propio ([`DeliveryNoteProductSelectionCard`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_product_selection_card.dart) y [`ReportProductSelectionCard`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/reports/presentation/create_report/widgets/report_product_selection_card.dart)) **DEBE** evaluar y reflejar el stock reservado:
     - `physicalStock = widget.product.inventoryQuantity;` (Stock físico en almacén).
     - `effectiveAvailable = widget.product.availableQuantity;` (Stock disponible neto tras restar reservas de cotizaciones aprobadas y notas de entrega activas).
     - `isReservedByOthers = physicalStock > 0 && effectiveAvailable <= 0;`
   - **Comportamiento en el Subtítulo de la Tarjeta:**
     - **Caso A (Todo Reservado):** Si `isReservedByOthers`, se renderiza una advertencia en `colors.error` (12px, negrita):
       > *"Todo el inventario propio está reservado en cotizaciones aprobadas o notas de entrega no finalizadas."*
       La tarjeta pasa a estado inactivo (`isInactive = true`), con opacidad reducida (`0.5`) e `IgnorePointer`.
     - **Caso B (Reserva Parcial):** Si `widget.product.reservedQuantity > 0 && effectiveAvailable > 0`, se muestra un subtítulo informativo en `colors.onSurfaceVariant` (12px, w500):
       > *"Hay X [uom] disponibles de Y en inventario propio."*
   - **Insignia [`UomStatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart):**
     - Muestra `quantity: widget.selectedQty > 0 ? widget.selectedQty : (isReservedByOthers ? physicalStock : effectiveAvailable)`.
     - Configura `maxStock: widget.selectedQty > 0 ? effectiveAvailable : null`.
7. **Estándar de Padding y SafeArea en Pantallas Selectoras sin FAB:**
   - En pantallas de selección directa o listados de sugerencias donde no se requiere un `CustomExtendedFab` inferior de confirmación (porque la acción se desencadena con el toque directo sobre la tarjeta, como [`SelectProductScreen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/create_quote/screens/select_product_screen.dart) o [`SelectSupplierOrderProductScreen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/supplier_orders/presentation/create_supplier_order/screens/select_supplier_order_product_screen.dart)):
     - **Envoltorio Obligatorio de `SafeArea`:** El cuerpo del `Scaffold` **DEBE** envolverse siempre en `SafeArea(child: Column(...))` para aislar el contenido de la barra de navegación gestual del sistema.
     - **Padding Inferior Canónico de Respiro:** El `ListView` o `ListView.separated` **DEBE** usar `padding: const EdgeInsets.fromLTRB(16, 8, 16, 40)`.
     - **Prohibición Estricta:** Queda **terminantemente prohibido** utilizar `padding: const EdgeInsets.symmetric(horizontal: 16)` con padding vertical en cero, ya que deja la última tarjeta rozando el borde físico de la pantalla.
8. **Estándar Oficial de Interruptores (`SwitchListTile` vs `Switch`):**
   - **Prohibición de Widgets Ad-Hoc y Escalas:** Queda **estrictamente prohibido** construir interruptores usando `Row(children: [Text(...), Switch(...)])` o `Transform.scale(scale: 0.9, child: Switch(...))`.
   - **Uso Obligatorio de `SwitchListTile`:** En todas las pantallas, formularios, pasos de wizards y hojas modales (`bottom sheets`), se debe utilizar el componente nativo accesible `SwitchListTile`.
   - **Alineación a Ras con Márgenes:** Debe configurarse obligatoriamente con `contentPadding: EdgeInsets.zero` para que el texto del interruptor coincida con la línea vertical de los campos de texto (`CustomTextField`) y selectores del formulario.
   - **Tipografía Institucional:** El título debe estilizarse con `fontWeight: FontWeight.w600` (o estilo seminegrita equivalente del `textTheme`). Si incluye texto explicativo, debe utilizar el parámetro `subtitle: Text(...)`.
   - **Paleta Material 3 Homologada:**
     - **Color Activo del Thumb:** `activeThumbColor: Theme.of(context).colorScheme.primary` (o `colors.primary`).
     - **Preservación del Track Color M3:** Queda prohibido forzar manualmente `activeTrackColor: colors.primary` con `activeThumbColor: colors.onPrimary` (inversión cromática), ya que rompe el contraste y la animación estándar de Material 3. La pista debe conservar el tintado armónico provisto por Flutter.
   - **Referencia Canónica:** [`edit_product_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/portfolio/presentation/inventory/screens/edit_product/edit_product_screen.dart#L568-L601).

### E. 📐 Regla Canónica para Barras de Botones Fijas Inferiores y Hojas Modales

Para formularios de pantalla completa (Arquetipo 5) y pasos de wizard (Arquetipo 3), las barras de botones fijas inferiores ([`FormBottomBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/form_bottom_bar.dart) y [`WizardButtonBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_bottom_bar.dart)) implementan una arquitectura autocontenida para garantizar simetría visual y protección de área segura:

1. **Estructura Interna Encapsulada:**
   - **Contenedor con fondo sólido:** `colors.surface` para evitar que el contenido en scroll se transparente de forma desprolija detrás de los botones.
   - **Línea divisoria superior tenue:** `Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5), width: 1.0))` que delimita sutilmente la barra fija del área scrollable.
   - **Área segura integrada:** `SafeArea(top: false)` para absorber el inset inferior del sistema (gestos o botones de navegación de Android/iOS) manteniendo el fondo de superficie hasta el borde físico del dispositivo.
   - **Padding simétrico:** `EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)`. Tanto la distancia superior como la inferior respecto al borde del contenedor son exactamente de 12.0 px, garantizando centrado vertical perfecto.

2. **Invocación Limpia en Pantallas (Cero Wrappers Externos):**
   - Queda **estrictamente prohibido** envolver `FormBottomBar` o `WizardButtonBar` en `SafeArea`, `Padding(bottom: 40)`, o cálculos manuales de `MediaQuery.of(context).padding.bottom`.
   - Se colocan como hijo directo final del `Column` del Scaffold:
     ```dart
     Column(
       children: [
         Expanded(
           child: SingleChildScrollView(
             padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
             child: ...,
           ),
         ),
         FormBottomBar(
           onCancel: () => context.pop(),
           onSave: _onSave,
         ),
       ],
     )
     ```

3. **Hojas Modales y Bottom Sheets Operativos (`CustomActionSheet`):**
   - [`CustomActionSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart) implementa internamente `SafeArea(top: false)` y un padding inferior canónico de 16px.
   - **Encabezado Limpio Sin Cards Redundantes:** El modal debe iniciar directamente con el título institucional de la acción. Queda prohibido añadir tarjetas inventadas o contenedores ad-hoc en la cabecera del sheet.
   - **Avisos Informativos Canónicos:** Cuando sea necesario advertir sobre consecuencias de una acción (por ejemplo, descuento de stock o finalización), usar exclusivamente el componente compartido [`InfoDisclaimerCard`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_disclaimer_card.dart).
   - **Botón de Acción Inferior:** En modales con formulario o confirmación operativa, el botón principal (`CustomButton`) debe alinearse a la derecha:
     ```dart
     Align(
       alignment: Alignment.centerRight,
       child: CustomButton(
         text: 'Confirmar entrega',
         icon: Symbols.check_circle,
         isLoading: _isSaving,
         onPressed: _handleConfirm,
       ),
     )
     ```
   - **Prohibición de Spacers Redundantes:** No agregar `SizedBox(height: 16)` ni paddings inferiores adicionales al final del array `actions` de un `CustomActionSheet`.

4. **Lienzo de Firma Digital Confinado (`ClipRRect` + Control Gestual + Tema Dinámico):**
   Para modales o pantallas que capturen firma digital presencial:
   - **Envoltura con `ClipRRect`:** Envolver el lienzo en `ClipRRect(borderRadius: BorderRadius.circular(12))` para garantizar que el renderizador GPU corte cualquier trazo que exceda el contenedor físico.
   - **Control de Límites en Gestos (`LayoutBuilder` + `onPanUpdate`):** Evaluar `details.localPosition` respecto a `constraints.maxWidth` y la altura fija (140px). Si el puntero o dedo sale del recuadro, añadir `null` a la lista de puntos (levantar el trazo), impidiendo registrar coordenadas negativas o rallar fuera de la caja o del modal:
     ```dart
     onPanUpdate: (details) {
       final pos = details.localPosition;
       if (pos.dx < 0 || pos.dx > constraints.maxWidth || pos.dy < 0 || pos.dy > fixedHeight) {
         _points.add(null);
       } else {
         _points.add(pos);
       }
     }
     ```
   - **Soporte Dinámico de Tema Claro/Oscuro:** El pincel en `CustomPainter` debe usar `colors.onSurface` (en lugar de `Colors.black87` fijo) para que el trazo sea perfectamente nítido y legible tanto en fondo claro como en superficie oscura.
   - **Acción Limpiar:** Utilizar un botón sutil con `Symbols.ink_eraser` y etiqueta 'Limpiar firma'.

5. **Regla Canónica de Entradas de Texto y Patrón de Teléfono Modular:**
   - **Regla Estricta de Campos de Texto (`CustomTextField`):**
     - **PROHIBIDO:** Usar `hintText:`.
     - **OBLIGATORIO:** Usar `helperText:` para proporcionar contexto, ejemplos de formato o ayudas al usuario en todas las entradas de datos de la aplicación.
   - **Patrón Estandarizado de Entrada de Teléfono:**
     - Desacoplar siempre en dos componentes contiguos en un `Row`:
       1. [`CustomDropdown<String>`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dropdown.dart) de ancho compacto (`width: 105px`) para seleccionar el prefijo/código de área (`'0412'`, `'0422'`, `'0414'`, `'0424'`, `'0416'`, `'0426'`).
       2. [`CustomTextField`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_text_field.dart) expandido para el número con `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` y `helperText: 'Ej. 1234567'`.

---

## 2. Catálogo Exhaustivo Clasificado de Componentes Compartidos (`/lib/shared/widgets/`)

### 📌 A. Navegación, Shell y Estructura Base
1. **[`standard_app_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_app_bar.dart)**: AppBar institucional con soporte para título, subtítulo, botón de regreso y acciones personalizadas (`actions`).
2. **[`main_navigation_drawer.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/main_navigation_drawer.dart)**: Menú lateral principal con navegación entre los módulos del sistema (Cotizaciones, Clientes, Reportes, Ajustes, etc.).
3. **[`generic_list_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_list_screen.dart)**: Plantilla base genérica para pantallas de listado con búsqueda y estados asíncronos.
4. **[`generic_search_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/generic_search_screen.dart)**: Estructura estándar para vistas de búsqueda interactiva a pantalla completa con historial local (`SharedPreferences`), barra de búsqueda autoenfocada y chips de filtro.

---

### 📌 B. Entradas de Datos, Formularios y Selectores
5. **[`custom_text_field.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_text_field.dart)**: Campo de texto estándar con botón de limpieza (`clear`), validación integrada, soporte multilínea, formato monetario y estilos del tema. **Regla de oro:** Siempre configurar con `helperText:` (nunca `hintText:`).
6. **[`custom_dropdown.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dropdown.dart)**: Dropdown configurable con soporte para selección simple, modo autocompletado con búsqueda y botón para agregar nuevos ítems en línea.
7. **[`custom_multi_dropdown.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_multi_dropdown.dart)**: Selector desplegable para selección múltiple con chips visuales y diálogo modal optimizado para colecciones grandes.
8. **[`custom_stepper.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_stepper.dart)**: Control numérico con botones decrementar/incrementar (`-` / `+`) para valores enteros o porcentajes.
9. **[`editable_quantity_stepper.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/editable_quantity_stepper.dart)**: Stepper interactivo de cantidad donde el usuario puede pulsar sobre el número para escribirlo directamente mediante el teclado numérico.
10. **[`custom_location_picker.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_location_picker.dart)**: Selector estandarizado y reactivo de País, Estado/Provincia y Ciudad.
11. **[`form_bottom_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/form_bottom_bar.dart)**: Barra inferior fija para formularios con botones de Cancelar (`TextButton`) y Guardar (`FilledButton`), con indicador de carga integrado. Está autocontenida con fondo de superficie (`colors.surface`), borde superior tenue (`colors.outlineVariant`), `SafeArea(top: false)` y padding simétrico de 12px vertical. Se invoca directamente sin wrappers externos.

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
21. **[`linked_document_card.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/linked_document_card.dart)**: Componente canónico para enlaces de documentos cruzados y relacionados en pestañas de Resumen.
    - Soporta colecciones múltiples (`LinkedDocumentCard(items: [...])`) con separadores `Divider` tenues y un único borde exterior, o elementos individuales con el constructor de conveniencia `LinkedDocumentCard.single(...)`.
    - **Regla Maestra de Negocio (Empresa entre paréntesis):**
      - *Relaciones Cruzadas (Venta ↔ Compra / Cliente ↔ Proveedor):* Se debe proporcionar `companyName` para mostrar `$documentNumber ($companyName)`. Ejemplos: Cotización listando OCs con su proveedor; OC mostrando Cotización con su cliente.
      - *Relaciones Homogéneas (Mismo Cliente o Mismo Proveedor):* Se omite `companyName` porque es redundante. Ejemplos: Cotización listando Notas de Entrega; OC mostrando Registro de Compra; Nota de Entrega mostrando Cotización; Compra mostrando OC.
    - **Elementos Visuales Obligatorios:** Título en negrita (con tachado si el documento está cancelado), `Tooltip` interactivo sobre el icono de estatus oficial y chevron `Icons.chevron_right`. Al pulsar (`onTap`), se debe esperar el retorno de `context.push(...)` e invalidar de inmediato los providers vinculados.

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
28. **[`wizard_bottom_bar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/wizard_bottom_bar.dart)**: Barra inferior de navegación para wizards con botón de Cancelar a la izquierda y Atrás/Siguiente/Finalizar a la derecha. Comparte la misma arquitectura autocontenida de `FormBottomBar` (fondo `colors.surface`, borde superior tenue, `SafeArea` y 12px simétricos), colocándose directamente como último hijo de la columna sin padding inferior externo.

---

### 📌 F. Botones y FABs
29. **[`custom_button.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_button.dart)**: Botón estilizado primario y secundario con soporte para estado de carga (`isLoading`) e icono.
30. **[`custom_extended_fab.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_extended_fab.dart)**: FAB extendido oficial para pantallas principales de listado ("Nuevo"), pantallas de selección ("Confirmar") y guardado en pestañas de Resumen. Soporta estados reactivos mediante `isEnabled`: cuando es `false`, se muestra bloqueado con fondo tenue (`surfaceContainerHighest`), elevación 0 y texto atenuado (`onSurface` al 38%). Soporta `trailingIcon` y `trailingTooltip` para mostrar indicadores auxiliares como el marcador de borrador en progreso (`DraftConstants.draftIcon`). Debe ocultarse únicamente durante el modo selección múltiple en listados.

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
39. **[`uom_status_badge.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart)**: Badge que combina icono dinámico de Unidad de Medida (UOM) y texto de estatus o cantidad (`quantity` o `quantity/maxStock`).
   - *Patrón de Reserva de Stock Propio:* Si un producto tiene stock físico en almacén pero su disponibilidad libre es 0 por estar reservado en otros documentos, el badge debe mostrar la cantidad física real (p. ej. `1 ud.`) en lugar de `"Sin stock"`, mientras que la tarjeta se deshabilita (`hasStock: false`, opacidad `0.5`) acompañada de subtítulo en rojo explicativo. Si tiene disponibilidad libre parcial, el badge muestra el saldo libre (p. ej. `2 ud.`) con subtítulo neutral informativo.
40. **[`dynamic_material_symbol.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/dynamic_material_symbol.dart)**: Renderizador de Material Symbols dinámicos desde cadenas de texto (SVG/nombre) con caché en memoria.
41. **[`product_image_avatar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/product_image_avatar.dart)**: Contenedor con fallback elegante para miniaturas de productos.
42. **[`user_profile_avatar.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/user_profile_avatar.dart)**: Avatar del usuario autenticado para encabezados principales.
43. **[`custom_menu_tile.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_menu_tile.dart)**: Fila de menú estilizada con icono, título y flecha de navegación para dashboards (Ajustes, Perfil).
44. **[`document_draft_icon.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/document_draft_icon.dart)**: Indicador visual estandarizado para señalar cambios locales no guardados en base de datos (`Icons.bookmark_added_outlined`) en tarjetas de documentos ejecutivos. Se ubica a la izquierda del estatus principal.

---

### 📌 I. Hojas de Acción y Envío
45. **[`custom_action_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart)**: Hoja inferior estándar para desplegar menús de opciones y acciones (`CustomActionSheet.show(...)`).
46. **[`bottom_sheet_action_item.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/bottom_sheet_action_item.dart)**: Fila individual de acción dentro de un `CustomActionSheet`.
47. **[`send_document_email_sheet.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/send_document_email_sheet.dart)**: Hoja estandarizada para envío de documentos por correo electrónico con prellenado de plantilla y destinatarios.

---

### 📌 J. Herramientas Especializadas
48. **[`barcode_scanner_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/barcode_scanner_screen.dart)**: Pantalla completa con visor de cámara para escanear códigos de barras y QR con linterna y retorno de valor.

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
