import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile_menu_tile.dart';
import '../providers/profile_provider.dart';
import '../providers/occupations_provider.dart';
import '../../../../core/utils/session_manager.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              context.pop(); // Close dialog
              try {
                await Supabase.instance.client.auth.signOut();
                await SessionManager().clearSessionData();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar sesión: $e')),
                  );
                }
              }
            },
            child: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(userProfileProvider);

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
          'Perfil',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (profile) {
          final currentFirstName = profile?.firstName ?? 'Usuario';
          final currentLastName = profile?.lastName ?? '';
          final currentOccupation = profile?.occupation ?? 'Sin ocupación';
          final currentFullName = '$currentFirstName $currentLastName'.trim();
          final currentAvatarUrl = profile?.avatarUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            child: Column(
              children: [
                // HEADER SECTION
                Center(
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          (currentAvatarUrl ?? '').isNotEmpty
                              ? currentAvatarUrl!
                              : 'https://i.pravatar.cc/300?img=11',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        currentFullName.isEmpty ? 'Usuario' : currentFullName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Occupation
                      Consumer(
                        builder: (context, ref, child) {
                          final occupationId = profile?.occupationId;
                          final occupationName = ref.watch(
                            occupationNameProvider(occupationId),
                          );
                          return Text(
                            occupationName ?? 'Sin ocupación',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Verification Badge
                      // Verification Badge
                      () {
                        final status =
                            profile?.verificationStatus ?? 'unverified';
                        String text;
                        Color color;
                        IconData icon;

                        switch (status) {
                          case 'verified':
                            text = 'Verificado';
                            color = Colors.green;
                            icon = Icons.verified;
                            break;
                          case 'pending':
                            text = 'Pendiente de verificación';
                            color = Colors.orange;
                            icon = Icons.access_time_filled;
                            break;
                          case 'unverified':
                          default:
                            text = 'No verificado';
                            color = colors.error;
                            icon = Icons.info_outline;
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                text,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(icon, color: color, size: 18),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // MENU OPTIONS
                ProfileMenuTile(
                  icon: Icons.person_outline,
                  title: 'Datos básicos',
                  subtitle: 'Nombre, ID, entre otros.',
                  onTap: () => context.push('/profile/basic-data'),
                ),
                ProfileMenuTile(
                  icon: Icons.mail_outline,
                  title: 'Datos de contacto',
                  subtitle: 'Correo y teléfono.',
                  onTap: () => context.push('/profile/contact-data'),
                ),
                ProfileMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Dirección principal',
                  subtitle: 'Tu dirección principal o fiscal',
                  onTap: () => context.push('/profile/main-address'),
                ),
                ProfileMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Métodos de envío',
                  subtitle:
                      'Las empresas de envíos que usas para recibir productos desde otra ciudad.',
                  onTap: () => context.push('/profile/shipping-methods'),
                ),
                ProfileMenuTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Ocupación',
                  subtitle: 'A lo que te dedicas.',
                  onTap: () {
                    context.push('/profile/occupation');
                  },
                ),
                ProfileMenuTile(
                  icon: Icons.security,
                  title: 'Seguridad',
                  subtitle: 'Contraseña.',
                  onTap: () {
                    context.push('/profile/security');
                  },
                ),
                ProfileMenuTile(
                  icon: Icons.verified_outlined,
                  title: 'Verificación',
                  subtitle: 'Para aprovechar al máximo la app.',
                  onTap: () {
                    context.push('/profile/verification');
                  },
                ),

                const SizedBox(height: 24),

                // LOGOUT BUTTON
                TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    'Cerrar sesión',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
