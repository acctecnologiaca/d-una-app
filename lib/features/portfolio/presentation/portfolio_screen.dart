import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'widgets/dashboard_card.dart';
import 'package:material_symbols_icons/symbols.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Fixed Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      // Open drawer
                    },
                  ),
                  Text(
                    'Portafolio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/profile'),
                    child: userProfileAsync.when(
                      data: (profile) {
                        final avatarUrl = profile?.avatarUrl;
                        return CircleAvatar(
                          radius: 18,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : const NetworkImage(
                                  'https://i.pravatar.cc/150?img=11',
                                ),
                        );
                      },
                      loading: () => const CircleAvatar(
                        radius: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=11',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Inventarios
                    Text(
                      'Inventarios',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Propio',
                      subtitle: 'Los productos de mi inventario',
                      icon: const Icon(Symbols.inventory_2, weight: 100),
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      onTap: () {
                        // Navigate to Own Inventory
                        context.go('/portfolio/own-inventory');
                      },
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Proveedores',
                      subtitle: 'Inventario de mis proveedores o terceros',
                      icon: Icon(Symbols.groups, weight: 100),
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      onTap: () => context.go('/portfolio/supplier-inventory'),
                    ),

                    const SizedBox(height: 32),

                    // Section 2: Servicios
                    Text(
                      'Servicios',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Propios',
                      subtitle: 'Los servicios que ofrezco',
                      icon: Icon(Symbols.handyman, weight: 100),
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      onTap: () => context.go('/portfolio/own-services'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
