import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/assets/app_images.dart';

class ProjectCoverImage extends StatelessWidget {
  const ProjectCoverImage({
    super.key,
    this.imagePath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? imagePath;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();
    if (kIsWeb || path == null || path.isEmpty) {
      return _defaultCover();
    }
    return Image.file(
      File(path),
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _defaultCover(),
    );
  }

  Widget _defaultCover() {
    return Image.asset(
      AppImages.modernTownhouse,
      fit: fit,
      alignment: alignment,
    );
  }
}
