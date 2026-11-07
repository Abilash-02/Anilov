import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/auth/presentation/providers/auth_provider.dart';
import 'package:anilov/features/auth/presentation/widgets/connect_anilist_dialog.dart';
import 'package:anilov/features/common/widgets/anilov_logo.dart';
import 'package:anilov/features/sync/domain/models/sync_state.dart';
import 'package:anilov/features/sync/presentation/providers/sync_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  bool _hasProviderScope(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasProviderScope(context)) {
      return const _ReactiveProfileScreen();
    }
    return const _ProfileScreenContent();
  }
}

class _ReactiveProfileScreen extends ConsumerWidget {
  const _ReactiveProfileScreen();

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Not synced yet';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Synced just now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
    return 'Synced on ${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Dynamic Profile Header
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (authState.isAuthenticated && authState.user?.avatarUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: CachedNetworkImage(
                          imageUrl: authState.user!.avatarUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const AnilovLogo(
                            size: 52,
                            showWordmark: false,
                          ),
                        ),
                      )
                    else
                      const AnilovLogo(
                        size: 52,
                        showWordmark: false,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.isAuthenticated
                                ? (authState.user?.name ?? 'AniList User')
                                : 'Anilov User',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.isAuthenticated
                                ? 'AniList Connected • Cloud Sync Active'
                                : 'Local profile • Offline first',
                            style: TextStyle(
                              fontSize: 13,
                              color: authState.isAuthenticated
                                  ? AppTheme.accentCyan
                                  : (isDark
                                      ? AppTheme.darkOnSurfaceMuted
                                      : AppTheme.lightOnSurfaceMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (authState.isAuthenticated) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: syncState.isSyncing
                              ? null
                              : () async {
                                  await ref.read(syncNotifierProvider.notifier).syncNow();
                                  if (context.mounted) {
                                    final currentSync = ref.read(syncNotifierProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(currentSync.message ?? 'Sync completed.'),
                                        backgroundColor: currentSync.status == SyncStatus.error
                                            ? Colors.redAccent
                                            : AppTheme.violet,
                                      ),
                                    );
                                  }
                                },
                          icon: syncState.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync_rounded, size: 18),
                          label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Disconnect AniList',
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Disconnect AniList'),
                              content: const Text(
                                'Are you sure you want to log out from AniList? Your local watchlist entries will be preserved.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                  child: const Text('Disconnect'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(authNotifierProvider.notifier).logout();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatLastSync(syncState.lastSyncTime),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ConnectAniListDialog.show(context),
                      icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                      label: const Text('Connect AniList Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.violetLight,
                        side: const BorderSide(color: AppTheme.violet),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Section
          Text(
            'Activity & Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.cloud_sync_rounded,
            title: 'AniList Cloud Sync',
            subtitle: authState.isAuthenticated
                ? 'Connected as ${authState.user?.name ?? 'User'} • Tap to sync'
                : 'Connect AniList to back up and sync your watchlist',
            onTap: () {
              if (authState.isAuthenticated) {
                ref.read(syncNotifierProvider.notifier).syncNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting synchronization with AniList...'),
                    backgroundColor: AppTheme.violet,
                  ),
                );
              } else {
                ConnectAniListDialog.show(context);
              }
            },
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.history_rounded,
            title: 'Watch History',
            subtitle: 'Recently watched anime and episodes',
            onTap: () => context.go('/profile/history'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.video_library_rounded,
            title: 'Local Media Player',
            subtitle: 'Play user-selected local video files offline',
            onTap: () => context.go('/profile/player'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Appearance, notifications, and storage',
            onTap: () => context.go('/profile/settings'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'About & Attribution',
            subtitle: 'Licenses, AniList attribution, and app details',
            onTap: () => context.go('/profile/about'),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // App Header Box
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                const AnilovLogo(
                  size: 52,
                  showWordmark: false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anilov User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Local profile • Offline first',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Section
          Text(
            'Activity & Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.history_rounded,
            title: 'Watch History',
            subtitle: 'Recently watched anime and episodes',
            onTap: () => context.go('/profile/history'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.video_library_rounded,
            title: 'Local Media Player',
            subtitle: 'Play user-selected local video files offline',
            onTap: () => context.go('/profile/player'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Appearance, notifications, and storage',
            onTap: () => context.go('/profile/settings'),
          ),
          const SizedBox(height: 8),

          _ProfileMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'About & Attribution',
            subtitle: 'Licenses, AniList attribution, and app details',
            onTap: () => context.go('/profile/about'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.violetLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
