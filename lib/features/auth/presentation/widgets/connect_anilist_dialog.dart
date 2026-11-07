import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ConnectAniListDialog extends ConsumerStatefulWidget {
  const ConnectAniListDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ConnectAniListDialog(),
    );
  }

  @override
  ConsumerState<ConnectAniListDialog> createState() => _ConnectAniListDialogState();
}

class _ConnectAniListDialogState extends ConsumerState<ConnectAniListDialog> {
  final _clientIdController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _useManualToken = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingClientId();
  }

  Future<void> _loadExistingClientId() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final id = await authNotifier.getClientId();
    if (id != null && mounted) {
      _clientIdController.text = id;
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);

    if (_useManualToken) {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter an AniList access token.';
        });
        return;
      }

      final success = await authNotifier.loginWithToken(token);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to AniList successfully!'),
              backgroundColor: AppTheme.violet,
            ),
          );
        } else {
          setState(() {
            _errorMessage = ref.read(authNotifierProvider).errorMessage ?? 'Login failed.';
          });
        }
      }
    } else {
      final clientId = _clientIdController.text.trim();
      if (clientId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter your AniList Client ID.';
        });
        return;
      }

      await authNotifier.setClientId(clientId);

      final err = await authNotifier.startOAuthFlow(
        explicitClientId: clientId,
        launchUrlCallback: (url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return false;
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (err != null) {
          setState(() => _errorMessage = err);
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening AniList in browser... Approve to complete login.'),
              backgroundColor: AppTheme.violet,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.violet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cloud_sync_rounded, color: AppTheme.violetLight, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Connect AniList', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in to synchronize your anime watchlist, watched episodes, and ratings with AniList.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 16),

            if (!_useManualToken) ...[
              TextField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'AniList Client ID',
                  hintText: 'e.g. 12345',
                  prefixIcon: Icon(Icons.key_rounded, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 8),
              Text(
                'Register an API Client at anilist.co/settings/developer with Redirect URI:\nanilov://auth',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                ),
              ),
            ] else ...[
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'OAuth Access Token',
                  hintText: 'Paste token from AniList',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 2,
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _useManualToken = !_useManualToken;
                  _errorMessage = null;
                });
              },
              child: Text(
                _useManualToken
                    ? 'Switch to Browser OAuth Login'
                    : 'Developer or Testing? Enter Token Directly',
                style: const TextStyle(
                  color: AppTheme.violetLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleConnect,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.violet),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_useManualToken ? 'Submit Token' : 'Connect via Browser'),
        ),
      ],
    );
  }
}
