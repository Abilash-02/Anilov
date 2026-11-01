// Bottom sheet modal for adding/editing a watchlist entry

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/watch_status.dart';
import '../../domain/models/watchlist_item.dart';
import '../providers/watchlist_providers.dart';

class WatchlistEditSheet extends ConsumerStatefulWidget {
  final int animeId;
  final String title;
  final String? coverUrl;
  final String? format;
  final int? totalEpisodes;
  final WatchlistItem? existingItem;

  const WatchlistEditSheet({
    super.key,
    required this.animeId,
    required this.title,
    this.coverUrl,
    this.format,
    this.totalEpisodes,
    this.existingItem,
  });

  static Future<void> show(
    BuildContext context, {
    required int animeId,
    required String title,
    String? coverUrl,
    String? format,
    int? totalEpisodes,
    WatchlistItem? existingItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchlistEditSheet(
        animeId: animeId,
        title: title,
        coverUrl: coverUrl,
        format: format,
        totalEpisodes: totalEpisodes,
        existingItem: existingItem,
      ),
    );
  }

  @override
  ConsumerState<WatchlistEditSheet> createState() => _WatchlistEditSheetState();
}

class _WatchlistEditSheetState extends ConsumerState<WatchlistEditSheet> {
  late WatchStatus _status;
  late int _progress;
  double? _score;

  @override
  void initState() {
    super.initState();
    _status = widget.existingItem?.status ?? WatchStatus.watching;
    _progress = widget.existingItem?.progress ?? 0;
    _score = widget.existingItem?.score;
  }

  void _save() {
    final now = DateTime.now();
    final item = WatchlistItem(
      animeId: widget.animeId,
      title: widget.title,
      coverUrl: widget.coverUrl ?? widget.existingItem?.coverUrl,
      format: widget.format ?? widget.existingItem?.format,
      totalEpisodes: widget.totalEpisodes ?? widget.existingItem?.totalEpisodes,
      status: _status,
      progress: _progress,
      score: _score,
      updatedAt: now,
      createdAt: widget.existingItem?.createdAt ?? now,
    );

    final repo = ref.read(watchlistRepositoryProvider);
    repo.saveWatchlistItem(item).then((_) {
      if (_progress > 0) {
        ref.read(historyRepositoryProvider).recordHistory(
              animeId: widget.animeId,
              title: widget.title,
              coverUrl: widget.coverUrl ?? widget.existingItem?.coverUrl,
              episode: _progress,
            );
        ref.invalidate(historyNotifierProvider);
      }
      ref.invalidate(watchlistCountsProvider);
      ref.invalidate(continueWatchingProvider);
      ref.invalidate(watchlistItemProvider(widget.animeId));
      ref.invalidate(watchlistNotifierProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem != null
                  ? 'Updated "${widget.title}"'
                  : 'Added "${widget.title}" to watchlist',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove from Watchlist?'),
        content: Text(
          'Are you sure you want to remove "${widget.title}" and your watched progress from your watchlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogCtx); // close dialog
              ref.read(watchlistNotifierProvider.notifier).removeItem(widget.animeId);
              Navigator.pop(context); // close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${widget.title}" from watchlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxEps = widget.totalEpisodes ?? widget.existingItem?.totalEpisodes;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3E3E4C) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.existingItem != null ? 'Edit Watchlist' : 'Add to Watchlist',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (widget.existingItem != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Remove from Watchlist',
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Status Selector Chips
            Text(
              'Status',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WatchStatus.values.map((status) {
                final isSelected = _status == status;
                return ChoiceChip(
                  label: Text(status.displayName),
                  selected: isSelected,
                  selectedColor: AppTheme.violet.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.violetLight,
                  backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.violetLight
                        : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _status = status;
                        if (status == WatchStatus.completed && maxEps != null && maxEps > 0) {
                          _progress = maxEps;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Episode Progress
            Text(
              'Episode Progress',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    maxEps != null ? 'Episode $_progress of $maxEps' : 'Episode $_progress',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _progress > 0
                            ? () {
                                setState(() {
                                  _progress--;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: (maxEps == null || _progress < maxEps)
                            ? () {
                                setState(() {
                                  _progress++;
                                  if (maxEps != null && _progress >= maxEps) {
                                    _status = WatchStatus.completed;
                                  } else if (_status == WatchStatus.planning) {
                                    _status = WatchStatus.watching;
                                  }
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating / Score (Optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score (Optional)',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _score != null ? '${_score!.toStringAsFixed(1)} / 10' : 'Not rated',
                  style: TextStyle(
                    fontSize: 13,
                    color: _score != null
                        ? Colors.amber
                        : (isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: _score ?? 0.0,
              min: 0.0,
              max: 10.0,
              divisions: 20,
              label: _score != null ? _score!.toStringAsFixed(1) : 'None',
              activeColor: AppTheme.violetLight,
              onChanged: (val) {
                setState(() {
                  _score = val > 0 ? val : null;
                });
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: Text(
                  widget.existingItem != null ? 'Save Changes' : 'Add to Watchlist',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
