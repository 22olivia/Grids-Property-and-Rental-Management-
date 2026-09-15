import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Network image with a graceful, on-brand fallback.
///
/// The placeholder is always painted underneath, so the app looks intentional
/// whether or not the device has connectivity — which matters for offline APK
/// testing. A deterministic gradient is derived from the URL so each image
/// keeps a stable identity between rebuilds.
class ResivynImage extends StatelessWidget {
  const ResivynImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.icon = Icons.apartment_rounded,
    this.borderRadius,
    this.width,
    this.height,
  });

  final String url;
  final BoxFit fit;
  final IconData icon;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  static const _palettes = <List<Color>>[
    [Color(0xFF0B2348), Color(0xFF1B4A6B)],
    [Color(0xFF0E3B47), Color(0xFF00A99D)],
    [Color(0xFF16324F), Color(0xFF3E6B8A)],
    [Color(0xFF1F3A5F), Color(0xFF00887E)],
    [Color(0xFF243B55), Color(0xFF141E30)],
  ];

  List<Color> get _gradient {
    var hash = 0;
    for (final code in url.codeUnits) {
      hash = (hash * 31 + code) & 0x7FFFFFFF;
    }
    return _palettes[hash % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        // Always-present base layer.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.22),
              size: 40,
            ),
          ),
        ),
        Image.network(
          url,
          fit: fit,
          gaplessPlayback: true,
          // Fall through to the gradient on any failure (offline, 404, DNS).
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
        ),
      ],
    );

    final sized = SizedBox(width: width, height: height, child: content);

    if (borderRadius == null) return sized;
    return ClipRRect(borderRadius: borderRadius!, child: sized);
  }
}

/// Circular avatar backed by [ResivynImage], with initials as the fallback.
class ResivynAvatar extends StatelessWidget {
  const ResivynAvatar({
    super.key,
    required this.url,
    required this.name,
    this.size = 44,
    this.ring = false,
    this.onTap,
    this.child,
  });

  /// A network URL or a local `file://` path (from the device gallery/camera).
  final String url;
  final String name;
  final double size;
  final bool ring;
  final VoidCallback? onTap;

  /// An optional layer rendered above the image (e.g. a camera badge).
  final Widget? child;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get _isLocal {
    if (url.isEmpty) return false;
    return url.startsWith('file://') ||
        url.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(url);
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (_isLocal) {
      final filePath = url.startsWith('file://')
          ? url.replaceFirst(RegExp(r'^file://'), '')
          : url;
      image = Image.file(
        File(filePath),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const SizedBox.shrink(),
      );
    }

    final avatar = Container(
      width: size,
      height: size,
      padding: ring ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      decoration: ring
          ? const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [RC.teal, RC.navy]),
            )
          : null,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: RC.navy,
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.36,
                  ),
                ),
              ),
            ),
            image,
            if (child != null) child!,
          ],
        ),
      ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }
}
