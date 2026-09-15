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
2. **Resumen Inicial Obligatorio:** La última pestaña siempre es **Resumen**, y el `TabController` debe inicializarse obligatoriamente en ella:
   ```dart
   _tabController = TabController(
     length: totalTabs,
     vsync: this,
     initialIndex: totalTabs - 1, // Siempre arranca en Resumen
   );
   ```
3. **Títulos de Pestañas Limpios:**
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
1. **Botón Principal:** Editar (`Icons.edit_outlined`), visible solo si el estado del documento permite modificaciones.
2. **Botón Secundario:** WhatsApp / Contacto (`Symbols.chat` o icono de WhatsApp).
3. **Botón Terciario (si aplica):** Firmar documento (`Icons.draw_outlined` o acción auxiliar).
4. **Cálculo Matemático de Padding Inferior:** En cada una de las pestañas que contenga un scroll (`SingleChildScrollView` o `ListView`), se debe aplicar la utilidad estándar [`FabScrollPadding`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/utils/fab_scroll_padding.dart):
   ```dart
   final int activeFabs = (showWhatsAppFab ? 1 : 0) + (showEditFab ? 1 : 0);
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

---

## 3. Pestaña de Cliente (`ViewDocumentClientTab`) y `ContactListTile`

1. **Espaciado Canónico:** Separación vertical entre bloques informativos `const SizedBox(height: 24)`.
2. **Contacto Receptor / Contacto Principal:**
   - Si el cliente es una empresa y posee contacto registrado, usar obligatoriamente **`ContactListTile`** ([`contact_list_tile.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/widgets/contact_list_tile.dart)):
     - Avatar circular con iniciales.
     - Nombre completo y cargo/rol.
     - Botones integrados para llamada telefónica y WhatsApp directo usando `ContactUtils.makePhoneCall` y `ContactUtils.launchWhatsApp`.
   - Si el cliente es una persona natural, presentar sus datos con `InfoBlock.text(icon: Symbols.phone, label: 'Teléfono', value: ...)`.

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

---

## 5. Sincronización en Tiempo Real (`Supabase Postgres Realtime`) y Telemetría

Toda pantalla de visualización de documentos ejecutivos debe actualizarse instantáneamente cuando el receptor interactúa con el visor web (apertura del enlace, confirmación o firma):

1. **Suscripción en `initState`:**
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
2. **Ciclo de Vida de la App:** Implementar `WidgetsBindingObserver` para invalidar la caché y refrescar datos al volver al foco (`AppLifecycleState.resumed`):
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.resumed && mounted) {
       ref.invalidate(documentDetailProvider(widget.docId));
     }
   }
   ```
3. **Liberación en `dispose`:** Desuscribir el canal en `dispose()` para evitar fugas de memoria:
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
4. **Notificaciones Visuales Estandarizadas:**
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

### H. Recepción Conforme y Firma Digital
- Etiqueta del cargo: `Cargo (opcional)` (no restrictivo).
- En el visor web finalizado, renderizar `Cargo: [valor]` y el preview de la firma digital Base64 capturada en el canvas.

---

## 7. Checklist de Verificación para Document View Screens

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
