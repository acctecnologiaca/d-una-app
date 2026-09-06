import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/pdf/templates/delivery_note_pdf_template.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
import '../../create_delivery_note/providers/create_delivery_note_provider.dart';
import '../widgets/send_delivery_note_whatsapp_sheet.dart';
import '../widgets/send_delivery_note_email_sheet.dart';
import '../widgets/confirm_delivery_note_reception_dialog.dart';

class ViewDeliveryNoteScreen extends ConsumerStatefulWidget {
  final String noteId;

  const ViewDeliveryNoteScreen({super.key, required this.noteId});

  @override
  ConsumerState<ViewDeliveryNoteScreen> createState() => _ViewDeliveryNoteScreenState();
}

class _ViewDeliveryNoteScreenState extends ConsumerState<ViewDeliveryNoteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSendOptions(BuildContext context, DeliveryNoteModel note) {
    CustomActionSheet.show(
      context: context,
      title: 'Enviar Nota de Entrega',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.chat,
          label: 'Enviar por WhatsApp',
          subtitle: 'Envía un enlace con token seguro para visualización y firma',
          onTap: () {
            context.pop();
            SendDeliveryNoteWhatsAppSheet.show(context, note);
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.mail,
          label: 'Enviar por Correo Electrónico',
          subtitle: 'Envía la plantilla oficial con enlace directo a la nota',
          onTap: () {
            context.pop();
            SendDeliveryNoteEmailSheet.show(context, note);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(deliveryNoteDetailProvider(widget.noteId));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return noteAsync.when(
      loading: () => Scaffold(
        appBar: StandardAppBar(title: 'Nota de Entrega', subtitle: 'Cargando...'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: StandardAppBar(title: 'Nota de Entrega', subtitle: 'Error'),
        body: Center(
          child: Text('Error al cargar la nota: $e'),
        ),
      ),
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: StandardAppBar(title: 'Nota de Entrega', subtitle: 'No encontrada'),
            body: const Center(child: Text('La nota de entrega no existe')),
          );
        }

        final dateFormat = DateFormat('dd/MM/yyyy');
        final isDelivered = note.status == DeliveryNoteStatus.delivered;

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Nota de Entrega',
            subtitle: '${note.deliveryNoteNumber} (${note.clientName})',
            actions: [
              IconButton(
                icon: const Icon(Icons.send_outlined),
                tooltip: 'Enviar',
                onPressed: () => _showSendOptions(context, note),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Opciones',
                onPressed: () {
                  CustomActionSheet.show(
                    context: context,
                    title: 'Opciones',
                    actions: [
                      BottomSheetActionItem(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'Descargar / Ver PDF',
                        onTap: () async {
                          final userProfile = ref.read(userProfileProvider).value;
                          final userEmail =
                              Supabase.instance.client.auth.currentUser?.email;

                          if (userProfile == null) return;
                          context.pop();

                          context.push(
                            '/pdf-preview',
                            extra: {
                              'title': 'Previsualizar Nota de Entrega',
                              'subtitle':
                                  '${note.deliveryNoteNumber} (${note.clientName})',
                              'fileName': StringUtils.sanitizeForFileName(
                                '${note.date.toIso8601String().substring(0, 10)}_${note.clientName}_${note.deliveryNoteNumber}.pdf',
                              ),
                              'buildPdf': (PdfPageFormat format) =>
                                  DeliveryNotePdfTemplate(
                                    note: note,
                                    userProfile: userProfile,
                                    userEmail: userEmail,
                                  ).generate(format),
                            },
                          );
                        },
                      ),
                      if (!isDelivered)
                        BottomSheetActionItem(
                          icon: Symbols.signature,
                          label: 'Confirmar recepción y firma',
                          onTap: () {
                            context.pop();
                            ConfirmDeliveryNoteReceptionDialog.show(context, ref, note);
                          },
                        ),
                      if (!isDelivered && note.status != DeliveryNoteStatus.cancelled)
                        BottomSheetActionItem(
                          icon: Icons.edit_outlined,
                          label: 'Modificar nota',
                          onTap: () {
                            context.pop();
                            ref
                                .read(createDeliveryNoteProvider.notifier)
                                .loadExistingDeliveryNote(note);
                            context.push('/delivery-notes/edit/${note.id}');
                          },
                        ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      BottomSheetActionItem(
                        icon: Symbols.chat,
                        label: 'Enviar por WhatsApp',
                        onTap: () {
                          context.pop();
                          SendDeliveryNoteWhatsAppSheet.show(context, note);
                        },
                      ),
                      BottomSheetActionItem(
                        icon: Symbols.mail,
                        label: 'Enviar por Correo',
                        onTap: () {
                          context.pop();
                          SendDeliveryNoteEmailSheet.show(context, note);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                const Tab(text: 'Despacho'),
                Tab(text: 'Productos (${note.items.length})'),
                Tab(text: 'Condiciones (${note.observations.length})'),
                const Tab(text: 'Recepción y Firma'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Despacho
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Badge Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: note.status.statusColor(colors).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: note.status.statusColor(colors).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            note.status.iconData,
                            color: note.status.statusColor(colors),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estatus: ${note.status.label}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: note.status.statusColor(colors),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Emitida el ${dateFormat.format(note.date)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (note.isDropshipping)
                            Chip(
                              label: const Text('Dropshipping', style: TextStyle(fontSize: 11)),
                              avatar: const Icon(Symbols.local_shipping, size: 14),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Blocks
                    InfoBlock.text(
                      label: 'Cliente',
                      value: '${note.clientName}${note.clientTaxId != null ? " (${note.clientTaxId})" : ""}',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 8),

                    if (note.contactName != null) ...[
                      InfoBlock.text(
                        label: 'Contacto receptor',
                        value: '${note.contactName} ${note.contactPhone != null ? "(${note.contactPhone})" : ""}',
                        icon: Icons.contact_phone_outlined,
                      ),
                      const SizedBox(height: 8),
                    ],

                    InfoBlock.text(
                      label: 'Dirección de Entrega',
                      value: '${note.recipientAddress ?? "No especificada"}${note.recipientCity != null ? ", ${note.recipientCity}" : ""}${note.recipientState != null ? ", ${note.recipientState}" : ""}',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 8),

                    InfoBlock.text(
                      label: 'Modalidad de Entrega',
                      value: note.deliveryType == 'store_pickup'
                          ? 'Retiro en tienda / almacén'
                          : (note.deliveryType == 'carrier'
                              ? 'Envío por encomienda / transportista'
                              : 'Despacho propio'),
                      icon: Icons.local_shipping_outlined,
                    ),
                    const SizedBox(height: 8),

                    if (note.shippingCompanyName != null && note.shippingCompanyName!.isNotEmpty) ...[
                      InfoBlock.text(
                        label: 'Empresa de Transporte',
                        value: '${note.shippingCompanyName}${note.trackingNumber != null ? " - Guía: ${note.trackingNumber}" : ""}',
                        icon: Icons.directions_bus_outlined,
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (note.deliveryInstructions != null &&
                        note.deliveryInstructions!.isNotEmpty) ...[
                      InfoBlock.text(
                        label: 'Instrucciones Especiales',
                        value: note.deliveryInstructions!,
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (note.clientPoNumber != null && note.clientPoNumber!.isNotEmpty) ...[
                      InfoBlock.text(
                        label: 'Orden de Compra del Cliente (O/C)',
                        value: note.clientPoNumber!,
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),

              // TAB 2: Productos
              ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: note.items.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = note.items[index];
                  return Card(
                    elevation: 0,
                    color: colors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.uom}',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (item.brand != null || item.model != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${item.brand ?? ""} ${item.model ?? ""}'.trim(),
                              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Precio: ${CurrencyFormatter.format(item.unitPrice)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                'Total: ${CurrencyFormatter.format(item.totalPrice)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (item.warrantyTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Garantía: ${item.warrantyTime} ${item.warrantyUnit == "years" ? "años" : (item.warrantyUnit == "months" ? "meses" : "días")}',
                              style: TextStyle(fontSize: 11, color: colors.secondary),
                            ),
                          ],

                          // Serials chips
                          if (item.serials.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Seriales entregados:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: item.serials.map((s) {
                                return Chip(
                                  label: Text(s.serialNumber, style: const TextStyle(fontSize: 11)),
                                  avatar: const Icon(Icons.qr_code, size: 14),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // TAB 3: Condiciones
              note.observations.isEmpty
                  ? const Center(child: Text('No hay condiciones u observaciones registradas'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: note.observations.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final obs = note.observations[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 12,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(obs.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(obs.description, style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),

              // TAB 4: Recepción y Firma
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (note.receivedByName != null && note.receivedByName!.isNotEmpty) ...[
                      InfoBlock.text(
                        label: 'Receptor de la Mercancía',
                        value: note.receivedByName!,
                        icon: Icons.person_pin_outlined,
                      ),
                      const SizedBox(height: 8),

                      if (note.receivedById != null) ...[
                        InfoBlock.text(
                          label: 'Cédula / Documento de Identidad',
                          value: note.receivedById!,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (note.receivedByPhone != null) ...[
                        InfoBlock.text(
                          label: 'Teléfono del Receptor',
                          value: note.receivedByPhone!,
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (note.receiverRelationship != null) ...[
                        InfoBlock.text(
                          label: 'Relación / Cargo',
                          value: note.receiverRelationship!,
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (note.receivedAt != null) ...[
                        InfoBlock.text(
                          label: 'Fecha y Hora de Recepción',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(note.receivedAt!),
                          icon: Icons.access_time,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (note.signatureData != null && note.signatureData!.isNotEmpty) ...[
                        const Text(
                          'Firma Digital Registrada:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: note.signatureData!.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(note.signatureData!.split(',').last),
                                    fit: BoxFit.contain,
                                  )
                                : const Text('Firma en formato digital guardada'),
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Symbols.draw,
                              size: 48,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Entrega pendiente de confirmación',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'El cliente puede firmar digitalmente desde el enlace enviado por WhatsApp/Correo, o puede registrar la firma directamente en persona.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                ConfirmDeliveryNoteReceptionDialog.show(context, ref, note);
                              },
                              icon: const Icon(Symbols.signature),
                              label: const Text('Registrar firma presencial ahora'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isDelivered
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: FilledButton.icon(
                      onPressed: () {
                        ConfirmDeliveryNoteReceptionDialog.show(context, ref, note);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar Recepción y Entrega'),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
