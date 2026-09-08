---
name: standardize_document_view_screen
description: Guía y estándar oficial para pantallas de visualización de documentos ejecutivos con múltiples pestañas (Cotizaciones, Reportes, Órdenes de Compra). Incluye TabController con Resumen inicial, _buildInfoCard, _buildSummaryRow, ContactListTile, FABs dinámicos y hojas de envío (Email, WhatsApp, PDF).
---

# Standardize Document View Screen Skill (Arquetipo 2)

Esta guía establece el estándar visual y arquitectónico obligatorio para pantallas de visualización de documentos ejecutivos y comerciales en D'Una App.
Referencias canónicas en el proyecto:
- [`view_quote_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/quotes/presentation/view_quote/screens/view_quote_screen.dart)
- [`view_report_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/reports/presentation/view_report/screens/view_report_screen.dart)

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
La pantalla presenta acciones flotantes para editar el documento o contactar al cliente:
1. **Botón Principal:** Editar (`Icons.edit_outlined`), visible solo si el estado del documento permite modificaciones.
2. **Botón Secundario:** WhatsApp / Contacto (`Symbols.chat` o icono de WhatsApp).
3. **Cálculo Matemático de Padding Inferior:** En cada una de las pestañas que contenga un scroll (`SingleChildScrollView` o `ListView`), se debe aplicar:
   ```dart
   final bool hasTwoFabs = showWhatsAppFab && showEditFab;
   final bool hasOneFab = showWhatsAppFab ^ showEditFab;
   final double bottomPadding = hasTwoFabs ? 184.0 : (hasOneFab ? 112.0 : 24.0);

   SingleChildScrollView(
     padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: bottomPadding),
     child: ...
   )
   ```

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

## 5. Checklist de Verificación para Document View Screens

- [ ] ¿El `TabController` arranca en la pestaña Resumen (`initialIndex: totalTabs - 1`)?
- [ ] ¿Los nombres de las pestañas carecen de números entre paréntesis?
- [ ] ¿Los errores o alertas de tabs se indican con `Badge(backgroundColor: colors.error, smallSize: 8)`?
- [ ] ¿La pestaña Resumen incluye la tarjeta de auditoría con fecha formateada (`_buildInfoCard`)?
- [ ] ¿Las tarjetas de resumen tienen el botón "Ir a [Pestaña]" alineado a la derecha?
- [ ] ¿El contacto de empresa utiliza `ContactListTile`?
- [ ] ¿El padding inferior del scroll view respeta la fórmula dinámica de FABs (`184px` / `112px` / `24px`)?
