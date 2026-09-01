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
    final profile = userProfileAsync.valueOrNull;
    final avatarUrl = profile?.avatarUrl;

    Widget avatarContent;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundImage:
              const AssetImage('assets/images/avatar_placeholder.png'),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundImage:
              const AssetImage('assets/images/avatar_placeholder.png'),
        ),
      );
    } else if (userProfileAsync.isLoading && profile == null) {
      avatarContent = CircleAvatar(
        radius: radius,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundImage:
            const AssetImage('assets/images/avatar_placeholder.png'),
      );
    }

    return InkWell(
      onTap: enabled ? () => context.push('/profile') : null,
      borderRadius: BorderRadius.circular(radius),
      child: avatarContent,
    );
  }
}
