import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';

class UserProfileAvatar extends ConsumerWidget {
  final double radius;
  final bool enabled;

  const UserProfileAvatar({
    super.key,
    this.radius = 18,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return InkWell(
      onTap: enabled ? () => context.push('/profile') : null,
      child: userProfileAsync.when(
        data: (profile) {
          final avatarUrl = profile?.avatarUrl;
          return avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: radius,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => CircleAvatar(
                    radius: radius,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: radius,
                    backgroundImage: const AssetImage('assets/images/avatar_placeholder.png'),
                  ),
                )
              : CircleAvatar(
                  radius: radius,
                  backgroundImage: const AssetImage('assets/images/avatar_placeholder.png'),
                );
        },
        loading: () => CircleAvatar(
          radius: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, stack) => CircleAvatar(
          radius: radius,
          backgroundImage: const AssetImage('assets/images/avatar_placeholder.png'),
        ),
      ),
    );
  }
}
