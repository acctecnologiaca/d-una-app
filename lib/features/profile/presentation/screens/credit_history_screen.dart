import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/credit_status.dart';
import '../../../../core/models/credit_transaction_model.dart';
import '../../../../core/providers/credits_providers.dart';
import '../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../shared/widgets/standard_list_item.dart';

enum CreditFilterType { all, earned, spent }

class CreditHistoryScreen extends ConsumerStatefulWidget {
  const CreditHistoryScreen({super.key});

  @override
  ConsumerState<CreditHistoryScreen> createState() =>
      _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends ConsumerState<CreditHistoryScreen> {
  CreditFilterType _selectedFilter = CreditFilterType.all;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final creditStatusAsync = ref.watch(userCreditsStatusProvider);
    final historyAsync = ref.watch(creditTransactionsHistoryProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Historial de créditos',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userCreditsStatusProvider);
          ref.invalidate(creditTransactionsHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta Resumen del Saldo Actual
              creditStatusAsync.when(
                data: (status) => _buildSummaryHeaderCard(context, status),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // 2. Sección Informativa FAQ (¿Cómo funcionan los créditos?)
              _buildFaqSection(context),

              const SizedBox(height: 24),

              // 3. Filtros Rápidos (Pills/SegmentedButton)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Movimientos',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<CreditFilterType>(
                      segments: const [
                        ButtonSegment<CreditFilterType>(
                          value: CreditFilterType.all,
                          label: Text('Todos'),
                        ),
                        ButtonSegment<CreditFilterType>(
                          value: CreditFilterType.earned,
                          label: Text('Acreditados'),
                        ),
                        ButtonSegment<CreditFilterType>(
                          value: CreditFilterType.spent,
                          label: Text('Consumidos'),
                        ),
                      ],
                      selected: {_selectedFilter},
                      onSelectionChanged: (Set<CreditFilterType> newSelection) {
                        setState(() {
                          _selectedFilter = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Lista de Transacciones (omitiendo amount == 0)
              historyAsync.when(
                data: (transactions) {
                  final activeTransactions = transactions
                      .where((t) => t.amount != 0)
                      .toList();

                  final filtered = activeTransactions.where((t) {
                    if (_selectedFilter == CreditFilterType.earned) {
                      return t.amount > 0;
                    } else if (_selectedFilter == CreditFilterType.spent) {
                      return t.amount < 0;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 56,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin movimientos en este filtro',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _buildTransactionItem(
                        context,
                        tx,
                        activeTransactions,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => FriendlyErrorWidget(error: err),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeaderCard(BuildContext context, CreditStatus status) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final cycleStartStr = dateFormat.format(status.cycleStart.toLocal());
    final cycleEndStr = dateFormat.format(status.cycleEnd.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    size: 24,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo disponible',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${status.remainingCredits} crédito(s)',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_repeat_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ciclo del $cycleStartStr al $cycleEndStr',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn(context, 'Base', '${status.baseCredits}'),
                _buildMetricColumn(
                  context,
                  'Acreditados',
                  '+${status.earnedCredits}',
                  color: const Color(0xFF388E3C),
                ),
                _buildMetricColumn(
                  context,
                  'Consumidos',
                  '-${status.spentCredits}',
                  color: colors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    CreditTransactionModel tx,
    List<CreditTransactionModel> allTransactions,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm:ss a');
    final isPositive = tx.amount > 0;

    final IconData icon;
    final Color iconColor;
    final Color backgroundColor;

    final isWhatsApp =
        tx.referenceType == 'whatsapp' ||
        tx.description?.contains('WhatsApp') == true;

    if (tx.transactionType == 'credit_expired') {
      icon = Icons.timer_off_rounded;
      iconColor = Colors.amber.shade900;
      backgroundColor = Colors.amber.shade100;
    } else if (tx.transactionType == 'oc_reversal') {
      icon = Icons.replay_rounded;
      iconColor = colors.error;
      backgroundColor = colors.errorContainer.withValues(alpha: 0.5);
    } else if (isPositive) {
      icon = Icons.add_circle_rounded;
      iconColor = const Color(0xFF388E3C);
      backgroundColor = colors.secondaryContainer.withValues(alpha: 0.5);
    } else {
      icon = Icons.mail_outline_rounded;
      iconColor = colors.error;
      backgroundColor = colors.errorContainer.withValues(alpha: 0.3);
    }

    final Widget leadingWidget;
    if (isWhatsApp) {
      leadingWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          'assets/icons/whatsapp_icon.png',
          width: 20,
          height: 20,
          color: colors.error,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.chat_outlined, color: colors.error, size: 20),
        ),
      );
    } else {
      leadingWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      );
    }

    final String amountText = isPositive ? '+${tx.amount}' : '${tx.amount}';

    String? expirationText;
    if (tx.transactionType == 'oc_reward' && tx.expiresAt != null) {
      final localExpiresAt = tx.expiresAt!.toLocal();
      final daysLeft = localExpiresAt.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        expirationText = 'Vence en $daysLeft días';
      } else if (daysLeft == 0) {
        expirationText = 'Vence hoy';
      } else {
        expirationText = 'Vencido';
      }
    }

    final Color amountColor = tx.transactionType == 'credit_expired'
        ? Colors.amber.shade900
        : (isPositive ? const Color(0xFF388E3C) : colors.error);

    final localCreated = tx.createdAt.toLocal();
    final DateTime displayDate = tx.transactionType == 'monthly_reset'
        ? DateTime(
            tx.createdAt.toUtc().year,
            tx.createdAt.toUtc().month,
            tx.createdAt.toUtc().day,
            0,
            0,
            0,
          )
        : localCreated;

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      leading: leadingWidget,
      overline: Text(dateFormat.format(displayDate)),
      title: _formatTransactionTitle(tx, allTransactions),
      subtitle: expirationText != null
          ? Text(
              expirationText,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: Text(
        amountText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
    );
  }

  String _formatTransactionTitle(
    CreditTransactionModel tx,
    List<CreditTransactionModel> allTransactions,
  ) {
    final type = tx.transactionType;
    final desc = tx.description ?? '';

    if (type == 'monthly_reset') {
      return 'Asignación mensual base';
    }

    if (type == 'credit_expired') {
      if (desc.contains('#')) {
        final ocNum = desc.split('#').last.trim();
        return 'Créditos vencidos (Ref. #$ocNum';
      }
      return 'Créditos vencidos';
    }

    if (type == 'oc_reward') {
      if (desc.contains('#')) {
        final ocNum = desc.split('#').last.trim();
        return 'Acreditados (Ref. $ocNum)';
      }
      return 'Acreditados por orden de compra';
    }

    if (type == 'oc_reversal') {
      if (desc.contains('#')) {
        final ocNum = desc.split('#').last.trim();
        return 'Revocados (Ref. $ocNum)';
      }
      return 'Revocados por soporte rechazado en registro de compra';
    }

    if (type == 'email_sent' || type == 'whatsapp_sent') {
      final isWhatsApp =
          type == 'whatsapp_sent' ||
          tx.referenceType == 'whatsapp' ||
          desc.toLowerCase().contains('whatsapp');
      final channel = isWhatsApp ? 'WhatsApp' : 'Email';

      final refType = (tx.referenceType ?? '').toLowerCase();
      final descLower = desc.toLowerCase();

      String docName = 'Documento';
      if (refType == 'quote' ||
          descLower.contains('quote') ||
          descLower.contains('cotizac')) {
        docName = 'Cotización';
      } else if (refType == 'report' || descLower.contains('report')) {
        docName = 'Reporte de servicio';
      } else if (refType == 'delivery_note' ||
          descLower.contains('entrega') ||
          descLower.contains('delivery')) {
        docName = 'Nota de Entrega';
      } else if (refType == 'receipt' ||
          descLower.contains('recibo') ||
          descLower.contains('receipt')) {
        docName = 'Recibo';
      }

      // Determinar si es "Envío" o "Reenvío"
      bool isResend = desc.startsWith('Reenvío') || desc.startsWith('Reenvio');
      if (!isResend && tx.referenceId != null) {
        isResend = allTransactions.any(
          (other) =>
              other.id != tx.id &&
              other.referenceId == tx.referenceId &&
              other.createdAt.isBefore(tx.createdAt),
        );
      }

      final actionWord = isResend ? 'Reenvío' : 'Envío';

      if (desc.contains('#')) {
        final afterHash = desc.split('#').last.trim();
        final docNum = afterHash.split(' ').first.trim();
        if (docNum.isNotEmpty) {
          return '$actionWord vía $channel (Ref. $docNum)';
        }
      }

      return '$actionWord de $docName vía $channel';
    }

    return desc.isNotEmpty ? desc : 'Transacción de créditos';
  }

  Widget _buildFaqSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          Icons.help_outline_rounded,
          color: colors.secondary,
          size: 22,
        ),
        title: Text(
          '¿Cómo funcionan los créditos?',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        iconColor: colors.secondary,
        collapsedIconColor: colors.onSurfaceVariant,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildFaqItem(
            context,
            icon: Icons.calendar_month_rounded,
            title: 'Asignación Mensual Base',
            description:
                'Recibes 30 créditos mensuales en tus primeros 3 meses, y 15 créditos mensuales de por vida desde el 4º mes. Se renuevan en tu fecha de corte y no son acumulativos.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context,
            icon: Icons.stars_rounded,
            title: 'Créditos por Órdenes de Compra (OC)',
            description:
                'Ganas 1 crédito por cada \$10 USD en OCs finalizadas y verificadas (hasta un máximo de 15 créditos por OC). Tienen una validez continua de 30 días.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context,
            icon: Icons.send_rounded,
            title: 'Consumo y Regla FIFO',
            description:
                'Gastas 1 crédito por cada cotización o documento enviado vía Email o WhatsApp. El sistema consume siempre primero los créditos que tengan la fecha de vencimiento más cercana.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
