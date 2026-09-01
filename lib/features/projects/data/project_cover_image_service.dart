import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';

class ProjectCoverImageService {
  const ProjectCoverImageService();

  static const int maxDimension = 1600;
  static const int jpegQuality = 78;

  Future<String> persistCompressed(XFile source) async {
    if (kIsWeb) return source.path;

    final documents = await getApplicationDocumentsDirectory();
    final covers = Directory(path_util.join(documents.path, 'project_covers'));
    await covers.create(recursive: true);

    final fileName = 'project_${DateTime.now().microsecondsSinceEpoch}';
    final compressedPath = path_util.join(covers.path, '$fileName.jpg');
    final sourceFile = File(source.path);

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        source.path,
        compressedPath,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressed != null) {
        final compressedFile = File(compressed.path);
        if (await compressedFile.length() < await sourceFile.length()) {
          return compressed.path;
        }
        await compressedFile.delete();
      }
    } catch (_) {
      final partialFile = File(compressedPath);
      if (await partialFile.exists()) await partialFile.delete();
    }

    final sourceExtension = path_util.extension(source.name).toLowerCase();
    final safeExtension = sourceExtension.isEmpty ? '.jpg' : sourceExtension;
    return (await sourceFile.copy(
      path_util.join(covers.path, '$fileName$safeExtension'),
    ))
        .path;
  }

  Future<void> delete(String? imagePath) async {
    if (kIsWeb || imagePath == null || imagePath.isEmpty) return;
    final file = File(imagePath);
    if (path_util.basename(file.parent.path) != 'project_covers') return;
    if (await file.exists()) await file.delete();
  }
}
