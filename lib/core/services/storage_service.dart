import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Compresses and uploads a photo. Returns the download URL.
  static Future<String> uploadPhoto({
    required String coupleId,
    required String memoryId,
    required File file,
  }) async {
    final compressed = await _compress(file, memoryId);
    final uploadFile = compressed ?? file;

    final ref = _storage
        .ref()
        .child('couples/$coupleId/photos/$memoryId.jpg');

    final task = await ref.putFile(
      uploadFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Clean up temp compressed file
    if (compressed != null && compressed.existsSync()) {
      compressed.deleteSync();
    }

    return await task.ref.getDownloadURL();
  }

  /// Compress to max 1080px wide, 80% quality.
  static Future<File?> _compress(File file, String id) async {
    try {
      final dir = await getTemporaryDirectory();
      final outPath = p.join(dir.path, 'compressed_$id.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        keepExif: false,
      );

      return result != null ? File(result.path) : null;
    } catch (_) {
      return null; // Fall back to original if compress fails
    }
  }

  /// Deletes a photo from Firebase Storage.
  static Future<void> deletePhoto({
    required String coupleId,
    required String memoryId,
  }) async {
    try {
      await _storage
          .ref()
          .child('couples/$coupleId/photos/$memoryId.jpg')
          .delete();
    } catch (_) {}
  }
}
