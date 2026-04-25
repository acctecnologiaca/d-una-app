import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../providers/view_quote_provider.dart';
import '../tabs/view_quote_products_tab.dart';
import '../tabs/view_quote_services_tab.dart';
import '../tabs/view_quote_client_tab.dart';
import '../tabs/view_quote_details_tab.dart';
import '../tabs/view_quote_conditions_tab.dart';
import '../tabs/view_quote_summary_tab.dart';

class ViewQuoteScreen extends ConsumerStatefulWidget {
  final String quoteId;
  const ViewQuoteScreen({super.key, required this.quoteId});

  @override
  ConsumerState<ViewQuoteScreen> createState() => _ViewQuoteScreenState();
}

class _ViewQuoteScreenState extends ConsumerState<ViewQuoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializamos con 6 pestañas, empezando en la última (Resúmen = índice 5)
    _tabController = TabController(length: 6, vsync: this, initialIndex: 5);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(viewQuoteProvider(widget.quoteId));

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Detalle de cotización',
        subtitle: state.currentQuoteNumber ?? 'Cargando...',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Productos'),
            Tab(text: 'Servicios'),
            Tab(text: 'Cliente'),
            Tab(text: 'Detalles'),
            Tab(text: 'Condiciones'),
            Tab(text: 'Resúmen'),
          ],
        ),
      ),
      body: state.isLoading && state.quote == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ViewQuoteProductsTab(quoteId: widget.quoteId),
                ViewQuoteServicesTab(quoteId: widget.quoteId),
                ViewQuoteClientTab(quoteId: widget.quoteId),
                ViewQuoteDetailsTab(quoteId: widget.quoteId),
                ViewQuoteConditionsTab(quoteId: widget.quoteId),
                ViewQuoteSummaryTab(
                  quoteId: widget.quoteId,
                  onNavigateToTab: (index) => _tabController.animateTo(index),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: () {
            context.push('/quotes/edit/${widget.quoteId}');
          },
          icon: Icons.edit,
          label: 'Editar',
        ),
      ),
    );
  }
}
