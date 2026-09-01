import 'package:flutter/material.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:image_picker/image_picker.dart';

Future<ImageSource?> showImageSourceBottomSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _ImageSourceBottomSheet(),
  );
}

class _ImageSourceBottomSheet extends StatelessWidget {
  const _ImageSourceBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 8,
                    child: IconButton(
                      tooltip: context.tr('cancel'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 58),
                    child: Text(
                      context.tr('project_image_source_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor.withValues(alpha: 0.75),
            ),
            _ImageSourceAction(
              key: const Key('projectImageGalleryOption'),
              icon: Icons.upload_rounded,
              label: context.tr('project_image_gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor.withValues(alpha: 0.75),
            ),
            _ImageSourceAction(
              key: const Key('projectImageCameraOption'),
              icon: Icons.photo_camera_rounded,
              label: context.tr('project_image_camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceAction extends StatelessWidget {
  const _ImageSourceAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 66),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Icon(icon, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
