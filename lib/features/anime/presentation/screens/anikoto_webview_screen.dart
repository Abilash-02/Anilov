import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

/// Full-screen, landscape-capable native WebView screen for AniKoto.
/// Loads the official public episode page inside Anilov without launching Chrome.
/// Manages WebView lifecycle, cookies, session handling, orientation toggles,
/// loading progress, back navigation, and fallback mechanisms.
class AnikotoWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;
  final int? episodeNumber;
  final int? animeId;

  const AnikotoWebViewScreen({
    super.key,
    required this.initialUrl,
    this.title = 'AniKoto In-App Player',
    this.episodeNumber,
    this.animeId,
  });

  @override
  State<AnikotoWebViewScreen> createState() => _AnikotoWebViewScreenState();
}

class _AnikotoWebViewScreenState extends State<AnikotoWebViewScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLandscape = false;
  bool _showControls = true;
  String _currentUrl = '';

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  @override
  void dispose() {
    // Restore system orientation and UI modes on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _handleBackPress() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
    } else {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else if (widget.animeId != null) {
          context.go('/anime/${widget.animeId}');
        } else {
          context.go('/home');
        }
      }
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(_currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: !_isLandscape,
          bottom: !_isLandscape,
          left: false,
          right: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main WebView or non-mobile platform view
              if (isMobilePlatform)
                _buildNativeWebView(context)
              else
                _buildNonMobileView(context, isDark),

              // Top loading progress bar
              if (_isLoading && _progress < 1.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: Colors.transparent,
                    color: AppTheme.violetLight,
                    minHeight: 3,
                  ),
                ),

              // Error banner if page failed to load
              if (_errorMessage != null)
                _buildErrorOverlay(context, isDark),

              // Floating / Accessible Controls Bar
              if (_showControls)
                _buildFloatingControls(context, isDark),

              // Bottom control pill in landscape / immersive
              if (_isLandscape && !_showControls)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    tooltip: 'Show Controls',
                    onPressed: () => setState(() => _showControls = true),
                    child: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeWebView(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(widget.initialUrl),
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
        builtInZoomControls: true,
        displayZoomControls: false,
        supportZoom: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
            if (url != null) _currentUrl = url.toString();
          });
        }
      },
      onLoadStop: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (url != null) _currentUrl = url.toString();
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
            _errorMessage = 'Network Error: ${error.description} (${error.type})';
          });
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        if (mounted && request.isForMainFrame == true) {
          final statusCode = errorResponse.statusCode;
          if (statusCode != null && statusCode >= 400) {
            setState(() {
              _errorMessage = 'HTTP Error $statusCode: ${errorResponse.reasonPhrase ?? "Unable to load page"}';
            });
          }
        }
      },
    );
  }

  Widget _buildNonMobileView(BuildContext context, bool isDark) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppTheme.violetLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  widget.initialUrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: const Text(
                  'AniKoto In-App WebView Player\n\n'
                  'On Android devices, this screen renders the official AniKoto website directly '
                  'via native InAppWebView with full hardware acceleration, cookies, and session handling.\n\n'
                  'In strict compliance with project policies: no hidden media URLs are scraped, '
                  'no scripts are injected to defeat website protections, and anti-bot checks are not bypassed. '
                  'If video playback fails due to website restrictions, use the external browser fallback.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.violet),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reload WebView'),
                    onPressed: _reload,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    icon: const Icon(Icons.crop_landscape_rounded, size: 18),
                    label: Text(_isLandscape ? 'Portrait' : 'Landscape'),
                    onPressed: _toggleLandscape,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('Open in External Browser'),
                    onPressed: _openExternalBrowser,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context, bool isDark) {
    return Positioned(
      bottom: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2E1A1A),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Failed to load page.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _reload,
                child: const Text('Retry', style: TextStyle(color: AppTheme.violetLight)),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white70, size: 20),
                tooltip: 'Open in External Browser',
                onPressed: _openExternalBrowser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingControls(BuildContext context, bool isDark) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              tooltip: 'Back',
              onPressed: _handleBackPress,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              tooltip: 'Reload',
              onPressed: _reload,
            ),
            IconButton(
              icon: Icon(
                _isLandscape ? Icons.crop_portrait_rounded : Icons.crop_landscape_rounded,
                color: Colors.white70,
                size: 18,
              ),
              tooltip: _isLandscape ? 'Portrait Mode' : 'Landscape Mode',
              onPressed: _toggleLandscape,
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white70, size: 18),
              tooltip: 'Open in External Browser',
              onPressed: _openExternalBrowser,
            ),
            if (_isLandscape)
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 18),
                tooltip: 'Hide Controls',
                onPressed: () => setState(() => _showControls = false),
              ),
          ],
        ),
      ),
    );
  }
}
