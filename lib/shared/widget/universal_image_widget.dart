import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agrozemex/core/theme/theme.dart';

/// Universal Production-Grade Image Renderer for AgroZemex.
/// Dynamically routes network URLs, local device file paths, and assets
/// without blocking the main isolate thread or crashing on invalid paths.
class UniversalImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallbackWidget;

  const UniversalImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final String path = imagePath.trim();

    final defaultFallback = fallbackWidget ??
        Container(
          width: width,
          height: height,
          color: AgroZemexTokens.surfaceContainerLow,
          child: const Center(
            child: Icon(
              Icons.grass,
              color: AgroZemexTokens.onSurfaceVariant,
              size: 48,
            ),
          ),
        );

    if (path.isEmpty) return defaultFallback;

    // 1. Network URLs (http:// or https://)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AgroZemexTokens.surfaceContainerLow,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }

    // 2. Local Device File Paths (e.g. /data/user/0/... or file://...)
    try {
      final cleanPath = path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        );
      }
    } catch (_) {
      return defaultFallback;
    }

    // 3. Asset Paths
    try {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    } catch (_) {
      return defaultFallback;
    }
  }
}
