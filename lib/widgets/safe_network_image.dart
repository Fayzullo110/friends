import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/ios_icons.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = url;

    final Widget fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Icon(
        IOSIcons.photo,
        size: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.45),
      ),
    );

    final Widget ph = placeholder ?? fallback;
    final Widget err = error ?? fallback;

    if (u == null || u.trim().isEmpty) {
      return ph;
    }

    Widget img = CachedNetworkImage(
      imageUrl: u,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => ph,
      errorWidget: (_, __, ___) => err,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 120),
    );

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }

    return img;
  }
}
