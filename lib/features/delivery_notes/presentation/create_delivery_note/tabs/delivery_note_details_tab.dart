import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteDetailsTab extends ConsumerStatefulWidget {
  const DeliveryNoteDetailsTab({super.key});

  @override
  ConsumerState<DeliveryNoteDetailsTab> createState() =>
      _DeliveryNoteDetailsTabState();
}

class _DeliveryNoteDetailsTabState extends ConsumerState<DeliveryNoteDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _clientPoController;
  late final TextEditingController _tagController;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _dateController = TextEditingController(text: _dateFormat.format(state.date));
    _clientPoController = TextEditingController(text: state.clientPoNumber ?? '');
    _tagController = TextEditingController(text: state.tag ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _clientPoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = ref.read(createDeliveryNoteProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      ref.read(createDeliveryNoteProvider.notifier).setDate(picked);
      _dateController.text = _dateFormat.format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DeliveryNoteCreateState>(createDeliveryNoteProvider, (previous, next) {
      final formattedDate = _dateFormat.format(next.date);
      if (_dateController.text != formattedDate) {
        _dateController.text = formattedDate;
      }
      if (next.clientPoNumber != previous?.clientPoNumber &&
          _clientPoController.text != (next.clientPoNumber ?? '')) {
        _clientPoController.text = next.clientPoNumber ?? '';
      }
      if (next.tag != previous?.tag &&
          _tagController.text != (next.tag ?? '')) {
        _tagController.text = next.tag ?? '';
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fecha de emisión
          CustomTextField(
            controller: _dateController,
            label: 'Fecha de emisión *',
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // 2. N° Orden de Compra del Cliente (Opcional)
          CustomTextField(
            controller: _clientPoController,
            label: 'OC del Cliente (Opcional)',
            onChanged: (val) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .setClientPoNumber(val.trim().isEmpty ? null : val.trim());
            },
          ),
          const SizedBox(height: 16),

          // 3. Etiqueta (Obligatoria, con helperText y límite de 35 caracteres)
          CustomTextField(
            controller: _tagController,
            label: 'Etiqueta*',
            helperText: 'Descripción corta que identifique a la nota de entrega.',
            maxLength: 35,
            onChanged: (val) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .setTag(val.trim().isEmpty ? null : val.trim());
            },
          ),
        ],
      ),
    );
  }
}
