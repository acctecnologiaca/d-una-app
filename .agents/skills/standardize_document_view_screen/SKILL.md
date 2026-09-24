---
name: standardize_document_view_screen
description: Guía y estándar oficial para pantallas de visualización de documentos ejecutivos con múltiples pestañas (Cotizaciones, Reportes, Órdenes de Compra, Notas de Entrega). Incluye TabController con Resumen inicial, _buildInfoCard, _buildSummaryRow, ContactListTile, FABs dinámicos, hojas de envío (Email, WhatsApp, PDF), suscripción a Supabase Postgres Realtime y homologación de visores web corporativos en Firebase Hosting.
---

# Standardize Document View Screen Skill (Arquetipo 2)

Esta guía establece el estándar visual, técnico y arquitectónico obligatorio para pantallas de visualización de documentos ejecutivos, comerciales y logísticos en D'Una App.

Referencias canónicas en el proyecto:
- [`view_quote_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/view_quote/screens/view_quote_screen.dart)
- [`view_report_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/reports/presentation/view_report/screens/view_report_screen.dart)
- [`view_delivery_note_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/delivery_notes/presentation/view_delivery_note/screens/view_delivery_note_screen.dart)

---

## 1. Arquitectura General de la Pantalla (`ViewDocumentScreen`)

### A. Estructura de Pestañas y TabController
1. **Replicación 1:1:** Las pestañas de visualización deben replicar exactamente la estructura del creador del documento.
2. **Estándar Universal de la Pestaña `[0] General`:**
   Todo documento transaccional en D'Una App inicia obligatoriamente en la pestaña `[0] General`, unificando al sujeto de la transacción (Cliente o Proveedor) con los metadatos operativos y comerciales:

   | Documento | Pestaña [0] | Pestaña [1] | Pestaña [2] | Pestaña [3] | Pestaña [4] | Total Pestañas | initialIndex |
   | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
   | **Cotización** | **General** *(Cliente + Datos)* | Productos | Servicios | Condiciones | Resúmen | **5** | **4** |
   | **Reporte de Servicio** | **General** *(Cliente + Servicio)* | Productos | Servicios | Condiciones | Resumen | **5** | **4** |
   | **Nota de Entrega** | **General** *(Cliente + Despacho)* | Productos | Despacho | Observaciones | Resumen | **5** | **4** |
   | **Orden de Compra** | **General** *(Proveedor + Datos)* | Productos | Resumen | — | — | **3** | **2** |
   | **Registro de Compra** | **General** *(Proveedor + Factura)* | Productos | Resumen | — | — | **3** | **2** |

3. **Resumen Inicial Obligatorio:** La última pestaña siempre es **Resumen**, y el `TabController` debe inicializarse obligatoriamente en ella:
   ```dart
   _tabController = TabController(
     length: totalTabs,
     vsync: this,
     initialIndex: totalTabs - 1, // Siempre arranca en Resumen (índice 4 en 5 pestañas, índice 2 en 3 pestañas)
   );
   ```
4. **Títulos de Pestañas Limpios:**
   - **PROHIBIDO:** No colocar números entre paréntesis en los títulos (ejemplo prohibido: `Productos (3)`).
   - **Badges de Alerta:** Si una sección tiene incidencias o campos incompletos, se muestra un punto circular rojo sin números:
     ```dart
     Tab(
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           const Text('Productos'),
           if (hasAlerts) ...[
             const SizedBox(width: 6),
             Badge(backgroundColor: colors.error, smallSize: 8),
           ],
         ],
       ),
     )
     ```

---

### B. Floating Action Buttons (FABs) & Padding Dinámico
La pantalla presenta acciones flotantes para editar el documento, contactar al cliente o firmar:
1. **Botón Principal:** Editar (`Icons.edit_outlined`), visible exclusivamente si el estado del documento permite modificaciones (`canEdit`).
2. **Botón Secundario:** WhatsApp / Contacto (`Symbols.chat` o icono de WhatsApp).
3. **Botón Terciario (si aplica):** Firmar documento presencialmente (`Symbols.signature`).
4. **Regla de Oro: Whitelist Estricta de Estados Editables (`canEdit`):**
   - **Estados Editables:** `draft`, `sent`, `resent`, `opened`.
   - **Estados Bloqueados:** `finalized`, `cancelled`, `delivered`.
   - **Comportamiento en UI:**
     - Si `!canEdit`: el FAB de edición no debe renderizarse.
     - En la hoja de opciones ([`CustomActionSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart)), la opción "Modificar nota / documento" se desactiva (`enabled: false`) con subtítulo informativo: `'Documento [estatus]. No se puede modificar'`.
     - En el creador/editor (`create_*.dart`), se debe implementar una cláusula de guarda en `_initializeData()` que rechace el acceso forzado por URL o ruta directa, mostrando `AppToast.error(context, message: '...')` y retornando con `context.pop()`.
   - **Reversión Automática a Borrador al Editar:** Al cargar cualquier documento previamente emitido (`sent`, `resent`, `opened`) para su modificación, su estado en el formulario de edición debe transicionar inmediatamente a `draft` (Borrador), garantizando que las modificaciones no alteren el estado formal hasta que el usuario guarde o reenvíe.
5. **Cálculo Matemático de Padding Inferior:** En cada una de las pestañas que contenga un scroll (`SingleChildScrollView` o `ListView`), se debe aplicar la utilidad estándar [`FabScrollPadding`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/utils/fab_scroll_padding.dart):
   ```dart
   final int activeFabs = (showWhatsAppFab ? 1 : 0) + (showEditFab ? 1 : 0) + (showSignatureFab ? 1 : 0);
   final double bottomPadding = FabScrollPadding.calculate(activeFabs); 
   // 256.0 si 3 FABs, 184.0 si 2 FABs, 112.0 si 1 FAB, 24.0 si 0 FABs

   SingleChildScrollView(
     padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: bottomPadding),
     child: ...
   )
   ```

> [!IMPORTANT]
> **Prohibición de Padding Artificial:** La columna de FABs (`Column(mainAxisSize: MainAxisSize.min, children: [...])`) reposa directamente sobre la propiedad `floatingActionButton` del `Scaffold`. Queda **estrictamente prohibido** envolverla en `Padding(bottom: 40.0)`.

---

## 2. Anatomía Obligatoria de la Pestaña `Resumen` (`SummaryTab`)

La pestaña `Resumen` es la vista consolidada del documento y debe seguir una jerarquía estricta:

### A. Tarjeta de Estatus y Auditoría (`_buildInfoCard`)
Muestra en una tarjeta de fondo `colors.surface` con borde `colors.outlineVariant`:
1. **Fila 1 (Estatus):**
   - Icono: `Symbols.conversion_path` (20px, `colors.onSurfaceVariant`).
   - Etiqueta: `'Estatus:'` (en negrita).
   - Badge oficial: Contenedor con borde curvo (8px), fondo `colors.surface`, borde sutil y:
     `Image.asset(status.iconPath, width: 16, height: 16)` + `Text(status.label, style: TextStyle(color: status.color(colors), fontWeight: FontWeight.bold))`.
2. **Fila 2 (Última Modificación):**
   - Icono: `Symbols.update` (20px, `colors.onSurfaceVariant`).
   - Etiqueta: `'Últ. mod:'` (en negrita).
   - Valor: `DateFormat('dd/MM/yyyy - hh:mm a').format(updatedAt.toLocal())`.

---

### B. Tarjetas de Sección del Resumen (Cliente, Productos, Condiciones, etc.)
Cada sección se compone de:
1. **Encabezado de Sección:**
   ```dart
   Row(
     children: [
       Icon(icon, size: 20, color: colors.onSurfaceVariant),
       const SizedBox(width: 8),
       Text(
         title,
         style: TextStyle(
           fontSize: 16,
           fontWeight: FontWeight.bold,
           color: colors.onSurfaceVariant,
         ),
       ),
     ],
   )
   ```
2. **Tarjeta Contenedora con Filas `_buildSummaryRow`:**
   ```dart
   Card(
     elevation: 0,
     color: colors.surface,
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(8),
       side: BorderSide(color: colors.outlineVariant),
     ),
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Column(
         children: [
           _buildSummaryRow(icon: Symbols.person, label: 'Nombre:', value: client.name),
           const Divider(height: 16),
           // Más filas...
           const SizedBox(height: 8),
           // Botón de navegación a la pestaña correspondiente:
           Align(
             alignment: Alignment.centerRight,
             child: TextButton.icon(
               onPressed: () => onNavigateToTab(targetTabIndex),
               icon: const Icon(Icons.arrow_forward_ios, size: 14),
               label: Text('Ir a $sectionName', style: const TextStyle(fontWeight: FontWeight.bold)),
             ),
           ),
         ],
       ),
     ),
   )
   ```

### C. Sección de Trazabilidad Cruzada y Mapa de Relaciones (Relationship Map)
En la parte inferior del scroll de la pestaña `Resumen`, deben mostrarse las tarjetas interactivas de los documentos vinculados en el ciclo de vida utilizando **obligatoriamente** el componente oficial [`LinkedDocumentCard`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/linked_document_card.dart) o `LinkedDocumentCard.single(...)`.

#### 📐 Regla Maestra de Negocio (Empresa entre paréntesis):
- **Relaciones Cruzadas (Venta ↔ Compra / Cliente ↔ Proveedor):** Se debe proporcionar `companyName` para mostrar `$documentNumber ($companyName)`.
  - *Cotizaciones:* Órdenes de compra vinculadas muestran el proveedor (`${order.orderNumber} (${order.supplierName})`).
  - *Órdenes de Compra:* Cotización de origen muestra el cliente (`$quoteNumber ($clientName)`).
  - *Notas de Entrega generadas desde OC:* Muestran el proveedor de la orden (`${order.orderNumber} (${order.supplierName})`).
- **Relaciones Homogéneas (Mismo Cliente o Mismo Proveedor):** Se omite `companyName` porque resulta redundante.
  - *Cotizaciones:* Notas de entrega vinculadas omiten el cliente (`note.deliveryNoteNumber`).
  - *Órdenes de Compra:* Registro de compra vinculado omite el proveedor (`$docType $cleanDocNumber`).
  - *Notas de Entrega generadas desde Cotización:* Cotización de origen omite el cliente (`$quoteNumber`).
  - *Registro de Compras:* Orden de compra vinculada omite el proveedor (`Orden de compra $cleanOrderNumber`).

#### ⚡ Reactividad en Tiempo Real y Actualización en Caliente:
1. **Navegación Interactiva (`onTap`):**
   ```dart
   onTap: () async {
     await context.push('/destination/path/$id');
     ref.invalidate(linkedDocumentProvider(currentId));
   }
   ```
2. **Ciclo de Vida de la App (`resumed`):** En `didChangeAppLifecycleState` o `AppLifecycleListener.onResume`, invalidar tanto el provider principal del documento como los providers de documentos vinculados.
3. **Suscripción Postgres Realtime:** Conectar canales de Supabase Realtime a las tablas relacionadas (`supplier_orders`, `delivery_notes`, `purchases`) filtradas por la clave foránea del documento actual.

---

## 3. Pestaña `[0] General` (`ViewDocumentDetailsTab`) y Unificación de Sujeto

La pestaña `[0] General` unifica de manera ordenada los datos fiscales del sujeto (Cliente o Proveedor) y los parámetros comerciales u operativos del documento:

1. **Sección 1: Cliente / Proveedor y Contacto:**
   - **Espaciado Canónico:** Separación vertical entre bloques informativos `const SizedBox(height: 24)`.
   - **Empresas (`company`):**
     - Razón Social, Identificación Fiscal (RIF/NIF/RUT), Dirección Fiscal con `InfoBlock.text`.
     - Si posee contacto registrado, usar obligatoriamente **`ContactListTile`** ([`contact_list_tile.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/widgets/contact_list_tile.dart)):
       - Avatar circular con iniciales.
       - Nombre completo y cargo/rol.
       - Botones integrados para llamada telefónica y WhatsApp directo usando `ContactUtils.makePhoneCall` y `ContactUtils.launchWhatsApp`.
       - Navegación al detalle del contacto al pulsar en la tarjeta.
   - **Personas Naturales:**
     - Nombre y Apellido, Cédula / Identificación, Dirección, Teléfono y Correo en `InfoBlock.text`.

2. **Sección 2: Parámetros del Documento:**
   - Fechas de emisión y vencimiento (con badge si expirada).
   - Asesor comercial o técnico responsable.
   - Categoría comercial.
   - Etiqueta identificadora del documento.
   - Documentos de origen vinculados (Cotización u Orden de Compra asociada).

3. **Renderizado Condicional de Notas Internas o Comentarios:**
   - **Regla Estricta:** Las notas solo se renderizan si el documento cuenta con texto registrado (`notes != null && notes.trim().isNotEmpty`). Si no hay notas, el contenedor no debe mostrarse ni ocupar espacio.
   - **Estilo Estándar del Contenedor de Notas:**
     ```dart
     Container(
       width: double.infinity,
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: colors.outlineVariant),
       ),
       child: Text(
         document.notes!,
         style: textTheme.bodyLarge?.copyWith(
           color: colors.onSurface,
         ),
       ),
     )
     ```

---

## 4. Opciones de Envío y Acciones del Documento

Las acciones del documento (descarga de PDF, envío por correo, WhatsApp, duplicación o anulación) se centralizan en un modal [`CustomActionSheet`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_action_sheet.dart):

```dart
void _showSendOptions(BuildContext context, DocumentModel document) {
  CustomActionSheet.show(
    context: context,
    title: 'Opciones de Documento',
    actions: [
      BottomSheetActionItem(
        icon: Icons.picture_as_pdf_outlined,
        label: 'Ver / Descargar PDF',
        onTap: () {
          context.pop();
          _exportPdf(context, document);
        },
      ),
      BottomSheetActionItem(
        icon: Symbols.chat,
        label: 'Enviar por WhatsApp',
        subtitle: 'Envía un enlace con token seguro de consulta',
        onTap: () {
          context.pop();
          _sendWhatsApp(context, document);
        },
      ),
      BottomSheetActionItem(
        icon: Symbols.mail,
        label: 'Enviar por Correo Electrónico',
        subtitle: 'Envía la plantilla oficial configurada',
        onTap: () {
          context.pop();
          SendDocumentEmailSheet.show(context, document);
        },
      ),
    ],
  );
}
```

### B. Modal Canónico de Confirmación de Recepción y Firma Presencial
Para documentos logísticos o de entrega física donde el receptor firma directamente en el dispositivo:
- Se invoca mediante diálogo modal estilizado con `CustomActionSheet` ([`ConfirmDeliveryNoteReceptionDialog.show(context, note)`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/delivery_notes/presentation/view_delivery_note/widgets/confirm_delivery_note_reception_dialog.dart)).
- **Salvaguarda Previa Obligatoria por Seriales Pendientes:**
  - Si el documento requiere seriales y tiene ítems incompletos (`document.hasMissingSerialsEffective == true`):
    - La opción de confirmar recepción y el FAB de firma presencial se deshabilitan o despliegan un diálogo informativo preventivo con `CustomDialog.confirmation` (`'Seriales pendientes: No se puede confirmar la recepción porque faltan seriales por asignar a uno o más productos.'`).
    - En el método `_handleConfirm()` del diálogo modal, se valida obligatoriamente esta condición antes de permitir la escritura en base de datos.

### C. Descuento de Stock Propio e Invalidación Reactiva en Supabase y Riverpod
1. **Lógica de Descuento en Base de Datos (PostgreSQL):**
   - Los ítems de inventario propio (`source_type = 'own'`, `is_dropshipping = false`) solo descuentan existencias cuando el documento transiciona a estado `finalized` mediante la función computed column `public.inventory_quantity(product products)`.
   - Si un documento previamente finalizado es cancelado (`cancelled`), el stock se restituye automáticamente en tiempo real y un trigger Postgres restaura los seriales asociados de `'dispatched'` a `'in_stock'`.
2. **Limitación de Realtime con Columnas Computadas (`inventory_quantity`):**
   - En PostgreSQL, las columnas computadas calculan el stock dinámicamente (`SUM(compras) - SUM(notas_finalizadas)`). Cuando una Nota de Entrega se finaliza o cancela, la fila modificada es de la tabla `delivery_notes`, **NO** de `products`. Por ende, PostgreSQL Realtime **nunca** emite un evento directo sobre la tabla `products`.
3. **Invalidación Reactiva de Proveedores en Flutter (Riverpod):**
   - Toda transición de estado a `finalized` o `cancelled` (en pantalla de detalle, menú de acciones individuales o acciones masivas por lote) **DEBE** invalidar obligatoriamente los proveedores de catálogo e inventario, y refrescar la lista paginada:
     ```dart
     ref.invalidate(productsProvider);
     ref.invalidate(paginatedProductsProvider);
     ref.read(paginatedProductsProvider.notifier).refresh();
     ```
   - **Invalidación Iterativa de Detalles de Producto:** Para evitar que la pantalla de detalle de un producto muestre existencias desactualizadas retenidas en caché al volver de una nota de entrega, se debe iterar sobre los ítems del documento e invalidar individualmente el proveedor de detalle de cada producto:
     ```dart
     for (final item in document.items) {
       if (item.productId != null) {
         ref.invalidate(productDetailProvider(item.productId!));
       }
     }
     ```

---

## 5. Sincronización en Tiempo Real (`Supabase Postgres Realtime`) y Telemetría

Toda pantalla de visualización de documentos ejecutivos debe actualizarse instantáneamente cuando el receptor interactúa con el visor web (apertura del enlace, confirmación o firma) o cuando un cambio concurrente ocurra:

1. **Suscripción en `initState` y Auto-Refresco en Montaje:**
   - Para evitar estados obsoletos si el usuario regresa a una pantalla ya montada o reingresa tras navegar, se debe forzar una invalidación en el primer frame tras montar la vista:
   ```dart
   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addObserver(this);
     _tabController = TabController(...);
     
     // Garantiza datos 100% frescos al entrar a la pantalla
     WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.invalidate(documentDetailProvider(widget.docId));
     });

     _initSingleDocRealtime();
   }
   ```
2. **Canal Realtime con Canal Único por Instancia:**
   ```dart
   RealtimeChannel? _singleDocChannel;

   void _initSingleDocRealtime() {
     _singleDocChannel = Supabase.instance.client
         .channel(
           'public:${tableName}_${widget.docId}_${DateTime.now().millisecondsSinceEpoch}',
         )
         .onPostgresChanges(
           event: PostgresChangeEvent.all,
           schema: 'public',
           table: tableName,
           filter: PostgresChangeFilter(
             type: PostgresChangeFilterType.eq,
             column: 'id',
             value: widget.docId,
           ),
           callback: (payload) {
             if (mounted) {
               ref.invalidate(documentDetailProvider(widget.docId));
               ref.read(paginatedDocumentsProvider.notifier).refresh();
             }
           },
         )
         .subscribe();
   }
   ```
3. **Ciclo de Vida de la App (`AppLifecycleState.resumed`):**
   - Crítico cuando el usuario abre el visor web en un navegador externo (o un cliente firma en su propio dispositivo) y el operador regresa a la aplicación:
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.resumed && mounted) {
       ref.invalidate(documentDetailProvider(widget.docId));
       ref.read(paginatedDocumentsProvider.notifier).refresh();
     }
   }
   ```
4. **Liberación en `dispose`:** Desuscribir el canal en `dispose()` para evitar fugas de memoria:
   ```dart
   @override
   void dispose() {
     _singleDocChannel?.unsubscribe();
     _singleDocChannel = null;
     WidgetsBinding.instance.removeObserver(this);
     _tabController.dispose();
     super.dispose();
   }
   ```
5. **Notificaciones Visuales Estandarizadas:**
   - **PROHIBIDO:** No usar `ScaffoldMessenger.of(context).showSnackBar`.
   - **OBLIGATORIO:** Usar `AppToast.success(...)`, `AppToast.warning(...)` o `AppToast.error(...)`, protegiendo siempre las llamadas asíncronas con `if (context.mounted)`.

---

## 6. Estándar de Visores Web de Documentos (`/firebase_hosting/public/`)

Los visores web públicos generados para clientes finales (`quote.html`, `report.html`, `order.html`, `delivery_note.html` y sus correspondientes `demo_*.html`) deben acatar rigurosamente las siguientes reglas:

### A. Regla Inmutable: Documentos Comerciales vs Documentos Logísticos
- **Documentos Comerciales (Cotizaciones, Reportes de Servicio, Órdenes de Compra):** Contemplan precios unitarios, subtotales, IVA y total en USD.
- **Documentos Logísticos (Notas de Entrega):** **PROHIBIDO TERMINANTEMENTE** incluir precios, subtotales, impuestos ni totales en USD. Su foco exclusivo es: Producto, Garantía, Cantidad, Seriales y Recepción Conforme.

### B. Detección Dinámica de Persona Natural vs Persona Jurídica
```javascript
const rawTaxId = (client.tax_id || '').trim();
const isCompany = client.type === 'company' || (rawTaxId.length > 0 && rawTaxId.toUpperCase().startsWith('J'));
const clientNameLabel = isCompany ? 'Razón Social' : 'Nombre';
const clientTaxLabel = isCompany ? 'RIF' : 'Cédula';
const showAttention = isCompany && client.contact_name && client.contact_name.trim() !== '' && client.contact_name !== '-';
```
- Si es **Persona Natural**: Se muestran `Nombre:` y `Cédula:`. La etiqueta y valor `Atención:` se ocultan por completo.
- Si es **Empresa / Jurídica**: Se muestran `Razón Social:`, `RIF:` y `Atención: [Nombre de contacto]`.

### C. Detalles del Despacho / Logística
- **No duplicar fecha de emisión:** La fecha de emisión pertenece al membrete superior del documento. No debe repetirse en el bloque de detalles de despacho.
- **Etiquetas oficiales:**
  - `Orden de Compra (Cliente):` (mostrar solo si existe el valor).
  - `Dirección de despacho:`.

### D. Formato de Seriales
- **Prohibido:** No repetir chips individuales con `S/N:` por cada serial.
- **Obligatorio:** Mostrar una sola etiqueta inicial `Serial(es):` y a continuación la lista de seriales separados por comas:
  ```javascript
  const serialsHtml = serials.length > 0
    ? `<div class="item-serials"><strong>Serial(es):</strong> ${serials.map(esc).join(', ')}</div>`
    : '';
  ```

### E. Aviso de Confidencialidad y Legalidad (`.disclaimer-card`)
Ubicado fuera del `#main-card`, antes del footer:
```html
<div class="disclaimer-card">
  <strong>Aviso de Confidencialidad y Términos / Recepción:</strong><br>
  [Texto legal formal adaptado a la naturaleza del documento].
</div>
```

### F. Footer Institucional Homologado
```html
<div class="footer">
  <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/public/app_images/logo_d_una.png" alt="D-UNA Logo" style="height: 24px; margin-bottom: 6px; vertical-align: middle; object-fit: contain;"><br>
  Tecnología D-UNA &bull; Plataforma de Gestión Transaccional &bull; &copy; 2026 Todos los derechos reservados.
</div>
```

### G. Botón Flotante PDF (`.print-fab`)
- `position: fixed; bottom: 24px; right: 24px;`
- `border-radius: 12px;` (no circular ni píldora de 50px).
- `background: var(--neutral-dark); color: #fff;`
- Icono y texto: `🖨️ Imprimir / Guardar PDF`.
- En `@media print`: ocultar `.print-fab`, `.validity-badge`, `.disclaimer-card`, `.footer`, `#reception-form`, `.no-print`.

### H. Recepción Conforme, Firma Digital y Botón de Acción
Para documentos que requieran constancia de entrega o firma electrónica en el visor web (p. ej. Notas de Entrega):
1. **Lienzo de Firma y Placeholder Interactivo (Estado Pendiente):**
   - Contenedor `.canvas-container` con bordes redondeados (`12px`), fondo claro `#FAFBFD`, borde sólido pulido `#CBD5E1` (`height: 150px`).
   - Placeholder `#sig-placeholder` centrado con ícono de lápiz que desaparece automáticamente al iniciar el trazo (`startDrawing`) y se restaura al pulsar `.btn-clear` ("Limpiar firma").
2. **Botón de Envío (`btn-submit`):**
   - Etiqueta estándar: **`"Confirmar recepción"`** (evitar frases largas como "Confirmar entrega y registrar firma").
   - Dimensiones y alineación: en desktop `width: auto;` y alineado a la derecha dentro de `.form-actions { display: flex; justify-content: flex-end; margin-top: 24px; }`.
   - Adaptación responsiva: en mobile (`max-width: 640px`), `.form-actions { justify-content: stretch; }` y `.btn-submit { width: 100%; }` para facilitar el toque ergonómico.
   - Feedback de carga: Deshabilitar el botón y mostrar `"Confirmando..."` durante la petición HTTP.
3. **Paridad Estricta y Sobriedad con el PDF (Estado Finalizado):**
   - **PROHIBICIÓN DE TINTES VERDES:** Queda terminantemente prohibido teñir el bloque de recepción finalizada con fondos verdes (`#F0FDF4`, `#ECFDF5`), bordes verdes (`#A7F3D0`) o badges chillones. Tanto en pantalla como al imprimir / guardar en PDF (`window.print()`), el resultado debe ser **idéntico al PDF nativo generado en Flutter**.
   - **Contenedor Sobrio:** Tarjeta `.reception-card` con fondo gris neutro `var(--neutral-bg-subtle)` (`#F8FAFC`), borde sutil `var(--neutral-border)` (`#E2E8F0`), esquinas de `12px` y padding `16px 20px`.
   - **Disposición de Firma Alineada a la Derecha:** Estructura idéntica a `_buildSignaturesBlock` del PDF nativo:
     - Ancho contenido (`240px`, centrado en mobile).
     - Trazo de la firma digital centrado sobre la línea divisoria.
     - Línea horizontal de firma de `200px`, altura `1px`, color `#CBD5E1`.
     - Leyenda institucional: `"Recibido Conforme / Cliente"` (11px, `var(--neutral-muted)`).
     - Nombre del receptor en negrita (12px, `var(--neutral-dark)`).
     - Datos formales: `C.I. / ID: [valor]`, `Cargo: [valor]` (si aplica) y `Fecha: [fecha formateada en hora local]`.
   - **Comportamiento en Impresión (@media print):**
     - Si la nota está finalizada, se imprime el bloque de firma sobrio institucional.
     - Si la nota está pendiente, `#reception-form` se oculta y en su lugar se imprime el bloque con la línea en blanco para firma física con `"Recibido Conforme / Cliente"` y `"Firma y Cédula"`, replicando con 100% de fidelidad el PDF de Flutter.

### I. Flujo de Respuesta y Landing Pages Institucionales (`*_response.html`)
1. **Prohibición de Alertas Nativas (`alert()`):** Queda terminantemente prohibido utilizar ventanas emergentes nativas de Javascript (`alert(...)` o recargas en bucle) tras completar una acción de cliente en la web.
2. **Redirección a Landing Page de Éxito:** Todo flujo de confirmación, aprobación o firma digital debe redirigir a una página de respuesta institucional dedicada (`delivery_note_response.html`, `quote_response.html`, `order_response.html`):
   ```javascript
   if (resJson.status === 'success' || resJson.status === 'already_processed') {
     const noteParam = docNumber ? `&note=${encodeURIComponent(docNumber)}` : '';
     window.location.href = `delivery_note_response.html?token=${encodeURIComponent(token)}&status=success${noteParam}`;
   }
   ```
3. **Anatomía de la Landing Page:**
   - Tarjeta centrada con sombra suave y fondo blanco.
   - Ícono circular animado de éxito (verde) o alerta (ámbar/rojo).
   - Encabezado con número de documento y badge de estatus.
   - Mensaje de confirmación claro y cordial ("Hemos registrado la recepción formal de los productos...").
   - Botón primario de consulta (`"Ver nota de entrega"` / `"Ver documento"`) para regresar a la vista formal en cualquier momento.
   - Footer institucional oficial D-UNA con logotipo corporativo.

### J. Homologación de Productos Multi-Origen en el Visor Web vs PDF
1. **Separación Operativa vs Vista Unificada del Cliente:** Cuando un producto se abastece desde múltiples orígenes (ej. parte de stock propio y parte de proveedor afiliado o externo), el sistema registra múltiples filas en `quote_items_products` bajo un mismo `group_index` para llevar el control de inventario y trazabilidad con proveedores.
2. **Consolidación Obligatoria en Documentos del Cliente:**
   - **En el PDF ([`quote_pdf_template.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/core/pdf/templates/quote_pdf_template.dart)):** Los productos se agrupan mediante `groupedProducts.putIfAbsent(product.groupIndex, ...)` sumando `quantity` y `totalPrice`.
   - **En el Visor Web ([`quote.html`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/firebase_hosting/public/quote.html)):** Es obligatorio agrupar los ítems en un `Map` por `group_index` (con fallback defensivo por firma `name_brand_model_unitPrice` si `group_index` no viniera), acumulando la cantidad total y el total consolidado antes de renderizar la tabla HTML. El cliente jamás debe ver el mismo producto duplicado o dividido por razones de abastecimiento interno.
   - **En la Edge Function ([`quotes_action/index.ts`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/supabase/functions/quotes_action/index.ts)):** Es mandatorio incluir `group_index: p.group_index` en el mapeo de `products` de la acción `get_details`.

---

## 7. Ciclo de Vida y Asignación de Fechas Logísticas y Recepción (Notas de Entrega)

En documentos logísticos o de despacho (como Notas de Entrega), intervienen 3 conceptos temporales que deben manejarse con precedencia estricta para evitar estados ambiguos como `"No especificada"`:
1. **Fecha de Emisión (`date`):** Momento administrativo en el que se generó la nota (por defecto `DateTime.now()` al crear).
2. **Fecha de Despacho (`delivery_date`):** Momento logístico en el que la mercancía sale del almacén/tienda o se entrega al courier.
3. **Fecha de Recepción Conforme (`received_at`):** Timestamp exacto en el que el cliente/receptor firma y confirma la entrega.

### Reglas de Precedencia y Automatización Logística:
1. **Inicialización por Defecto:**
   - En el estado del formulario (`CreateState`), `deliveryDate` se inicializa obligatoriamente con `DateTime.now()`, pre-cargándose en el controlador de la pestaña *Despacho*. Permanece 100% modificable para programar despachos futuros.
   - Al cargar una nota existente en edición, si `deliveryDate == null`, se asigna `DateTime.now()` como salvaguarda.
2. **Actualización Reactiva al Enviar (WhatsApp y Correo):**
   - Si la nota pasa de borrador a enviada (`sent` / `resent`):
     - Si `deliveryDate` era nula o anterior a hoy (un borrador guardado en días pasados), se actualiza automáticamente a `DateTime.now()`.
     - Si el usuario configuró una fecha programada igual o posterior a hoy, **se respeta la fecha futura intacta**.
3. **Garantía en Firma y Recepción (Modal Presencial y WebViewer):**
   - Siempre se registra el timestamp exacto de la firma en `received_at`.
   - Si `delivery_date` era nula o era una fecha futura (el cliente recibió y firmó antes de tiempo), se sincroniza automáticamente a la fecha de hoy.
   - Si ya tenía una fecha de despacho pasada o igual a hoy, se preserva como la fecha real en que salió el despacho.
4. **Prohibición de "No especificada" en la UI:**
   - En pestañas de resumen, detalle y plantillas PDF, queda terminantemente prohibido mostrar `"No especificada"` o `"No establecida"`. Si `deliveryDate` llegase a ser nulo, debe utilizar como fallback visual inmediato la fecha de emisión `date`.
5. **Conversión Obligatoria a Hora Local (`.toLocal()`):**
   - Los timestamps de recepción (`received_at`) se persisten en base de datos en formato UTC (ISO-8601). Al deserializar en el modelo (`fromJson`), es **obligatorio invocar `DateTime.tryParse(json['received_at'])?.toLocal()`**.
   - En vistas de resumen (`SummaryTab`) y en plantillas de exportación PDF (`DeliveryNotePdfTemplate`), la fecha y hora de recepción debe formatearse explícitamente en horario local con formato de 12 horas:
     ```dart
     DateFormat('dd/MM/yyyy - hh:mm a').format(note.receivedAt!.toLocal())
     ```
     para evitar que se muestre con el desfase de la hora UTC del servidor.

---

## 8. Ciclo de Vida de Descuento de Inventario Físico y Validación Preventiva RPC (Notas de Entrega y Reportes de Servicio)

Para documentos que consumen productos de inventario propio (`sourceType == 'own'`), el ciclo de descuento y validación opera bajo las siguientes reglas arquitectónicas:

### A. Descuento Automático en Base de Datos (PostgreSQL)
1. **Fórmula de Stock Físico:** La función calculada `public.inventory_quantity(product public.products)` deduce automáticamente las cantidades consumidas en documentos con estatus `finalized`:
   $$\text{inventory\_quantity} = \sum(\text{purchase\_items}) - \sum(\text{finalized delivery\_note\_items}) - \sum(\text{finalized service\_report\_items\_products})$$
2. **Reversión Automática:** Si un documento finalizado es anulado (`cancelled`), la condición `status = 'finalized'` deja de cumplirse y las unidades retornan automáticamente al inventario disponible.
3. **Inmutabilidad:** El trigger en base de datos (`check_*_status_immutability`) bloquea cualquier modificación o eliminación de ítems en documentos finalizados o cancelados.

### B. Validación Preventiva de Stock mediante RPC
1. **Verificación Previa a la Persistencia:** Antes de guardar el estatus `finalized` (tanto en cambios individuales como en lote), el repositorio debe invocar la función RPC preventiva:
   - Para Notas de Entrega: `check_delivery_note_insufficient_stock(p_delivery_note_id)`
   - Para Reportes de Servicio: `check_service_report_insufficient_stock(p_report_id)`
2. **Excepción de Dominio:** Si la RPC detecta que la cantidad requerida supera el stock físico neto disponible $(\text{inventory\_quantity} - \text{reserved\_quantity})$, el repositorio lanza `InsufficientStockException(productNames)`.

### C. Manejo en la Interfaz de Usuario (UI) y Feedback
1. **Diálogo de Advertencia Estándar:** Al capturar `InsufficientStockException`, la pantalla (`ViewDocumentScreen` o `SelectionActions`) presenta un [`CustomDialog.confirmation`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/custom_dialog.dart):
   ```dart
   CustomDialog.show(
     context: context,
     dialog: CustomDialog.confirmation(
       icon: Symbols.warning,
       iconColor: Colors.amber.shade800,
       title: 'Stock Insuficiente',
       contentText:
           'No se puede finalizar el documento porque no hay suficiente stock disponible en el inventario propio de los siguientes productos:\n\n${e.productNames.map((name) => '• $name').join('\n')}\n\nPor favor, reponga el stock en almacén para poder finalizarlo.',
       actions: [
         TextButton(
           onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
           child: const Text('Entendido'),
         ),
       ],
     ),
   );
   ```
2. **Sincronización Reactiva de Estado:** Tras cualquier cambio exitoso a `finalized` o `cancelled`, es mandatorio ejecutar:
   ```dart
   ref.invalidate(productsProvider);
   ```
   para refrescar el catálogo y portafolio en tiempo real.

---

## 9. Checklist de Verificación para Document View Screens

- [ ] ¿El `TabController` arranca en la pestaña Resumen (`initialIndex: totalTabs - 1`)?
- [ ] ¿Los nombres de las pestañas carecen de números entre paréntesis?
- [ ] ¿Los errores o alertas de tabs se indican con `Badge(backgroundColor: colors.error, smallSize: 8)`?
- [ ] ¿La pestaña Resumen incluye la tarjeta de auditoría con fecha formateada (`_buildInfoCard`)?
- [ ] ¿Las tarjetas de resumen tienen el botón "Ir a [Pestaña]" alineado a la derecha?
- [ ] ¿El contacto de empresa utiliza `ContactListTile`?
- [ ] ¿El padding inferior del scroll view respeta la fórmula dinámica `FabScrollPadding.calculate` (`256px` / `184px` / `112px` / `24px`)?
- [ ] ¿Los FABs reposan directamente sobre el `Scaffold` sin envoltorios `Padding(bottom: 40.0)`?
- [ ] ¿Está implementada la suscripción Postgres Realtime para actualizar la vista ante eventos web?
- [ ] ¿Se utiliza `AppToast` en lugar de `ScaffoldMessenger` protegiendo con `if (context.mounted)`?
- [ ] ¿El visor web respeta la distinción entre documento comercial (con montos) y logístico (sin montos)?
- [ ] ¿El visor web aplica la regla de persona natural (`Nombre:`, `Cédula:`, sin `Atención:`)?
- [ ] ¿Los seriales en el visor web usan una sola etiqueta `Serial(es):` separados por coma?
- [ ] ¿El botón flotante de PDF en la web cuenta con `border-radius: 12px` y el footer oficial D-UNA?
- [ ] ¿La opción y el FAB de edición respetan la whitelist `canEdit` (`'draft'`, `'sent'`, `'resent'`, `'opened'`) y se bloquean en `'finalized'`, `'cancelled'` y `'delivered'`?
- [ ] ¿Al editar un documento emitido, el estado en el formulario pasa automáticamente a `'draft'`?
- [ ] ¿Se previene la confirmación de entrega y firma presencial si hay seriales pendientes por asignar (`hasMissingSerialsEffective == true`)?
- [ ] ¿El modal de recepción física utiliza `CustomActionSheet`, campos con `helperText` (sin `hintText`), teléfono modular, lienzo con `ClipRRect` y botón `'Confirmar entrega'` alineado a la derecha?
- [ ] ¿Se programó `WidgetsBinding.instance.addPostFrameCallback` en `initState` para forzar la invalidación inicial del documento y evitar datos de caché obsoletos?
- [ ] ¿Se implementa `WidgetsBindingObserver` con invalidación en `AppLifecycleState.resumed` para capturar interacciones ocurridas en el visor web externo?
- [ ] ¿Al transicionar el estatus a `finalized` o `cancelled`, se ejecuta la validación RPC previa (`check_*_insufficient_stock`) y se invalida `productsProvider` para actualizar el stock en toda la aplicación?
- [ ] ¿La fecha de despacho (`delivery_date`) aplica el modelo híbrido con fallback automático a la fecha actual si está vacía o vencida al enviar/firmar, respetando fechas futuras programadas y evitando textos como `"No especificada"`?
- [ ] ¿El visor web utiliza el botón `"Confirmar recepción"` con ancho auto alineado a la derecha en escritorio y 100% en pantallas móviles?
- [ ] ¿El lienzo de firma digital en la web incluye placeholder interactivo centrado que se oculta al trazar y se restaura al limpiar?
- [ ] ¿Se eliminaron los `alert()` nativos al firmar/confirmar en la web, redirigiendo a su landing page institucional (`*_response.html`) con resumen y botón de consulta?
- [ ] ¿El área de firma en la web finalizada carece por completo de fondos o cabeceras verdes y replica el bloque de firma sobrio del PDF (`slate50`/`slate200`) alineado a la derecha sobre la línea `#CBD5E1`?
- [ ] ¿Los timestamps de recepción (`receivedAt`) se convierten explícitamente a hora local (`.toLocal()`) en el modelo y se formatean en 12h con AM/PM (`DateFormat('dd/MM/yyyy - hh:mm a')`) tanto en la app como en el PDF?
- [ ] ¿El estatus Borrador (`draft`) está excluido de `showStatusDialog` y solo se asigna automáticamente al crear o al guardar modificaciones en modo edición tras confirmar el diálogo preventivo?

---

## 10. Regla Arquitectónica de Inmutabilidad del Estatus Borrador (Draft) y Transición Exclusiva al Editar

### A. Prohibición en Selectores Manuales
1. **Exclusión de `draft` en `showStatusDialog`:** En los diálogos modales de cambio de estatus ([`QuoteSelectionActions`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/quotes_list/quote_selection_actions.dart), [`ReportSelectionActions`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/reports/presentation/reports_list/report_selection_actions.dart) y [`DeliveryNoteSelectionActions`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/delivery_notes/presentation/delivery_notes_list/delivery_note_selection_actions.dart)), el estatus `draft` (Borrador) está terminantemente prohibido.
2. **Protección en Selección Individual y por Lotes:** Ningún usuario u operador puede degradar manualmente a borrador uno o varios documentos emitidos (`sent`, `opened`, `approved`, etc.) desde la vista detallada ni desde la lista principal mediante acciones masivas.

### B. Transición Automática Exclusiva al Editar
1. **Punto Único de Transición a `draft`:** El estatus `draft` solo se adquiere por dos vías exclusivas:
   - Al crear un nuevo documento desde cero.
   - Al editar y guardar modificaciones deliberadas sobre un documento emitido.
2. **Diálogo Confirmatorio Preventivo:** En todos los creadores (`create_*_screen.dart`), si el documento actual no se encuentra en `draft`, al pulsar Guardar se debe desplegar un `CustomDialog.confirmation` alertando:
   - *"El/La [documento] se encuentra en estatus '[Estatus]'. Al guardar las modificaciones, pasará automáticamente a estatus Borrador. ¿Deseas continuar?"*
3. **Unificación de Puntos de Guardado en Modo Edición:** Tanto el icono de guardar en el `StandardAppBar` como el Extended FAB de la pestaña Resumen (tab 4) deben invocar invariablemente el método unificado `_handleSaveInEditMode`, garantizando la ejecución de la advertencia preventiva y el guardado formal con `status: 'draft'`.



