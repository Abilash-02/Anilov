import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

/// Embedded AniKoto In-App WebView player widget.
/// Renders the official AniKoto watch page directly inside Anilov player surfaces
/// without launching Chrome or external browsers automatically.
class AnikotoInAppPlayer extends StatefulWidget {
  final String watchUrl;
  final String title;
  final int episodeNumber;
  final int? animeId;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  const AnikotoInAppPlayer({
    super.key,
    required this.watchUrl,
    required this.title,
    required this.episodeNumber,
    this.animeId,
    this.isFullscreen = false,
    this.onToggleFullscreen,
  });

  @override
  State<AnikotoInAppPlayer> createState() => _AnikotoInAppPlayerState();
}

class _AnikotoInAppPlayerState extends State<AnikotoInAppPlayer> {
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(widget.watchUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open external browser: $e')),
          );
        }
      }
    }
  }

  void _openFullScreenView() {
    context.push(
      '/anikoto-webview?url=${Uri.encodeComponent(widget.watchUrl)}&title=${Uri.encodeComponent(widget.title)}&ep=${widget.episodeNumber}&animeId=${widget.animeId ?? 0}',
    );
  }

  void _reload() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (_webViewController != null) {
      _webViewController!.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Native WebView on mobile devices; Clean interactive preview on tests/desktop
          if (isMobilePlatform)
            _buildNativeWebView(context)
          else
            _buildPlatformFallback(context),

          // Loading Progress Bar (active only on mobile webview during live page loads)
          if (isMobilePlatform && _isLoading && _progress > 0 && _progress < 1.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                color: AppTheme.violetLight,
                minHeight: 3,
              ),
            ),

          // Overlay Error State
          if (_errorMessage != null)
            _buildErrorOverlay(context),

          // Quick control strip
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                    tooltip: 'Full-Screen In-App WebView',
                    onPressed: _openFullScreenView,
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Open in External Browser',
                    onPressed: _openExternalBrowser,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeWebView(BuildContext context) {
    return InAppWebView(
      key: ValueKey('anikoto_webview_${widget.watchUrl}'),
      initialUrlRequest: URLRequest(
        url: WebUri(widget.watchUrl),
      ),
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        useHybridComposition: true,
        transparentBackground: false,
        supportMultipleWindows: false,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      },
      onLoadStop: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onProgressChanged: (controller, progress) {
        if (mounted) {
          setState(() {
            _progress = progress / 100.0;
            if (progress >= 100) _isLoading = false;
          });
        }
      },
      onReceivedError: (controller, request, error) {
        if (mounted && request.isForMainFrame == true) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Connection error: ${error.description}';
          });
        }
      },
    );
  }

  Widget _buildPlatformFallback(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(widget.isFullscreen ? 24.0 : 16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_browser_rounded,
                  color: AppTheme.violetLight,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Official Episode ${widget.episodeNumber} on AniKoto',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const Text(
                  'AniKoto (anikoto.cz) enforces "X-Frame-Options: SAMEORIGIN" and does not offer an authorized third-party embed API. '
                  'In compliance with safety policies, hidden streams are not scraped or bypassed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.violet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: Text('Watch Episode ${widget.episodeNumber} on AniKoto'),
                    onPressed: _openFullScreenView,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text('Open Full-Screen WebView'),
                    onPressed: _openFullScreenView,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    icon: const Icon(Icons.video_library_outlined, size: 16),
                    label: const Text('Open Local Player'),
                    onPressed: () => context.push('/player'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 36),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load AniKoto page.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  onPressed: _reload,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  label: const Text('Open Externally'),
                  onPressed: _openExternalBrowser,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
