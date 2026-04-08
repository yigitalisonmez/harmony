import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a memory photo from either a local file or a remote URL.
/// Local file takes priority. Remote images are cached to disk.
class MemoryPhotoView extends StatelessWidget {
  const MemoryPhotoView({
    super.key,
    required this.photoPath,
    required this.photoUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String photoPath;
  final String? photoUrl;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    // Local file: shown immediately (just uploaded or own device)
    if (photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(file, fit: fit, cacheWidth: cacheWidth);
      }
    }

    // Remote URL: cached to disk after first load
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: fit,
        memCacheWidth: cacheWidth,
        placeholder: (_, __) => _placeholder(loading: true),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  static Widget _placeholder({bool loading = false}) => Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF333333),
                  ),
                )
              : const Icon(Icons.image_not_supported_outlined,
                  color: Colors.white24, size: 48),
        ),
      );
}
