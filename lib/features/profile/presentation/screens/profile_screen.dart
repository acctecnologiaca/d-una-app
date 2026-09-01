import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/custom_menu_tile.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/profile_provider.dart';
import '../providers/occupations_provider.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/custom_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    return CustomDialog.show(
      context: context,
      dialog: CustomDialog.destructive(
        title: 'Cerrar sesión',
        contentText: '¿Estás seguro de que deseas cerrar sesión?',
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () async {
              context.pop(); // Close dialog
              try {
                // Perform sign out
                await Supabase.instance.client.auth.signOut();
                await SessionManager().clearSessionData();

                // Nuclear reset of Riverpod state using the GlobalKey
                // This must happen to clear keepAlive providers
                RootApp.restart(null);
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(
                    context,
                    message: 'Error al cerrar sesión: $e',
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.bold),
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
        error: (error, stack) => FriendlyErrorWidget(error: error),
        data: (profile) {
          final currentFirstName = profile?.firstName ?? 'Usuario';
          final currentLastName = profile?.lastName ?? '';

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
                      if ((currentAvatarUrl ?? '').isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: currentAvatarUrl!,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 60,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) => const CircleAvatar(
                            radius: 60,
                            backgroundImage: AssetImage(
                              'assets/images/avatar_placeholder.png',
                            ),
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 60,
                            backgroundImage: AssetImage(
                              'assets/images/avatar_placeholder.png',
                            ),
                          ),
                        )
                      else
                        const CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage(
                            'assets/images/avatar_placeholder.png',
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
                      () {
                        final status =
                            profile?.verificationStatus ?? 'unverified';
                        Widget icon;
                        String text;
                        Color backgroundColor;
                        Color textColor;

                        switch (status) {
                          case 'verified':
                            text = 'Verificado';
                            icon = Image.asset(
                              'assets/icons/status_approved.png',
                              width: 14,
                              height: 14,
                            );
                            backgroundColor = Colors.green.withValues(alpha: 0.1);
                            textColor = Colors.green.shade700;
                            break;
                          case 'pending':
                            text = 'Pendiente de verificación';
                            icon = Image.asset(
                              'assets/icons/status_review.png',
                              width: 14,
                              height: 14,
                            );
                            backgroundColor = Colors.orange.withValues(alpha: 0.1);
                            textColor = Colors.orange.shade800;
                            break;
                          case 'rejected':
                            text = 'Rechazado';
                            icon = Image.asset(
                              'assets/icons/status_rejected.png',
                              width: 14,
                              height: 14,
                            );
                            backgroundColor = colors.error.withValues(alpha: 0.1);
                            textColor = colors.error;
                            break;
                          case 'unverified':
                          default:
                            text = 'No verificado';
                            icon = Icon(
                              Icons.info_outline,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            );
                            backgroundColor = colors.surfaceContainerHighest.withValues(alpha: 0.5);
                            textColor = colors.onSurfaceVariant;
                            break;
                        }

                        return StatusBadge(
                          icon: icon,
                          text: text,
                          backgroundColor: backgroundColor,
                          textColor: textColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          borderRadius: 16,
                          fontSize: 13,
                        );
                      }(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // MENU OPTIONS
                CustomMenuTile(
                  icon: Icons.person_outline,
                  title: 'Datos básicos',
                  subtitle: 'Nombre, ID, entre otros.',
                  onTap: () => context.push('/profile/basic-data'),
                ),
                CustomMenuTile(
                  icon: Icons.mail_outline,
                  title: 'Datos de contacto',
                  subtitle: 'Correo y teléfono.',
                  onTap: () => context.push('/profile/contact-data'),
                ),
                CustomMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Dirección principal',
                  subtitle: 'Tu dirección principal o fiscal',
                  onTap: () => context.push('/profile/main-address'),
                ),
                CustomMenuTile(
                  icon: Icons.star_border_outlined,
                  title: 'Historial de créditos',
                  subtitle: 'Saldo disponible y movimientos.',
                  onTap: () {
                    context.push('/profile/credits-history');
                  },
                ),
                CustomMenuTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Ocupación',
                  subtitle: 'A lo que te dedicas.',
                  onTap: () {
                    context.push('/profile/occupation');
                  },
                ),
                CustomMenuTile(
                  icon: Icons.security,
                  title: 'Seguridad',
                  subtitle: 'Contraseña.',
                  onTap: () {
                    context.push('/profile/security');
                  },
                ),
                CustomMenuTile(
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
