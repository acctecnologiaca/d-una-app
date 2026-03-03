import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../tabs/quote_products_tab.dart';
import '../tabs/quote_services_tab.dart';
import '../tabs/quote_client_tab.dart';
import '../tabs/quote_details_tab.dart';
import '../tabs/quote_conditions_tab.dart';
import '../tabs/quote_summary_tab.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  const CreateQuoteScreen({super.key});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasInitializedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedTab && _tabController.index == 0) {
      final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tabStr != null) {
        final initialTab = int.tryParse(tabStr);
        if (initialTab != null && initialTab >= 0 && initialTab < 6) {
          _tabController.index = initialTab;
        }
      }
      _hasInitializedTab = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Nueva cotización',
        subtitle: '#C-00000011', // Placeholder or fetched ID
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colors.onSurface),
            onPressed: () {},
          ),
        ],
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
            Tab(text: 'Resumen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const QuoteProductsTab(),
          const QuoteServicesTab(),
          const QuoteClientTab(),
          const QuoteDetailsTab(),
          const QuoteConditionsTab(),
          QuoteSummaryTab(
            onNavigateToTab: (index) {
              _tabController.animateTo(index);
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    // Only show FAB on Products (0), Services (1), and Conditions (4) tabs
    if (_tabController.index != 0 &&
        _tabController.index != 1 &&
        _tabController.index != 4) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/quotes/create/select-product');
          } else if (_tabController.index == 1) {
            context.push('/quotes/create/select-service');
          } else if (_tabController.index == 4) {
            final currentUri = GoRouterState.of(
              context,
            ).uri.replace(queryParameters: {'tab': '4'});
            final encodedUri = Uri.encodeComponent(currentUri.toString());
            context.push('/quotes/create/conditions?returnTo=$encodedUri');
          }
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }
}
