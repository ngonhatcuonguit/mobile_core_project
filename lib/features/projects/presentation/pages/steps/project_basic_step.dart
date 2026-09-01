import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/widgets/media/image_source_bottom_sheet.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/core/data/vietnam_provinces.dart';
import 'package:flutter_core_project/features/projects/data/project_cover_image_service.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:image_picker/image_picker.dart';

class ProjectBasicStep extends StatefulWidget {
  const ProjectBasicStep({super.key});

  @override
  State<ProjectBasicStep> createState() => _ProjectBasicStepState();
}

class _ProjectBasicStepState extends State<ProjectBasicStep> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProjectCoverImageService _imageService =
      const ProjectCoverImageService();
  bool _processingImage = false;

  Future<void> _chooseImage() async {
    final source = await showImageSourceBottomSheet(context);
    if (source == null || !mounted) return;

    setState(() => _processingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) return;

      final savedPath = await _imageService.persistCompressed(image);
      if (!mounted) return;
      final cubit = context.read<ProjectWizardCubit>();
      final previousPath = cubit.state.imagePath;
      cubit.setImage(savedPath);
      await _imageService.delete(previousPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('project_image_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  Future<void> _removeImage(String imagePath) async {
    context.read<ProjectWizardCubit>().setImage(null);
    await _imageService.delete(imagePath);
  }

  Future<void> _chooseProvince(String selectedProvince) async {
    final province = await showModalBottomSheet<VietnamProvince>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: _ProvincePickerSheet(
            selectedProvince: selectedProvince,
          ),
        ),
      ),
    );
    if (province != null && mounted) {
      context.read<ProjectWizardCubit>().updateBasicInfo(
            location: province.name,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, state) {
        final cubit = context.read<ProjectWizardCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              title: context.tr('project_basic_title'),
              description: context.tr('project_basic_description'),
            ),
            const SizedBox(height: 22),
            InkWell(
              key: const Key('projectImagePicker'),
              onTap: _processingImage ? null : _chooseImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 154,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.38),
                  ),
                ),
                child: state.imagePath == null
                    ? Center(
                        child: _processingImage
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.primary,
                                    size: 34,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('project_choose_image'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.tr('project_image_optional'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!kIsWeb)
                            Image.file(
                              File(state.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          if (_processingImage)
                            const ColoredBox(
                              color: Color(0x66000000),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filledTonal(
                              tooltip: context.tr('delete'),
                              onPressed: _processingImage
                                  ? null
                                  : () => _removeImage(state.imagePath!),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('projectNameField'),
              initialValue: state.name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (value) => cubit.updateBasicInfo(name: value),
              decoration: InputDecoration(
                labelText: context.tr('project_name'),
                hintText: context.tr('project_name_hint'),
                prefixIcon: const Icon(Icons.home_work_outlined),
                errorText: state.showValidation && state.name.trim().isEmpty
                    ? context.tr('project_name_required')
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('projectLocationField'),
              onTap: () => _chooseProvince(state.location),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                isEmpty: state.location.isEmpty,
                decoration: InputDecoration(
                  labelText: context.tr('project_location'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  errorText:
                      state.showValidation && state.location.trim().isEmpty
                          ? context.tr('project_location_required')
                          : null,
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  state.location.isEmpty
                      ? context.tr('project_location_hint')
                      : state.location,
                  style: state.location.isEmpty
                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor,
                          )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProvincePickerSheet extends StatefulWidget {
  const _ProvincePickerSheet({required this.selectedProvince});

  final String selectedProvince;

  @override
  State<_ProvincePickerSheet> createState() => _ProvincePickerSheetState();
}

class _ProvincePickerSheetState extends State<_ProvincePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<VietnamProvince> _filteredProvinces = vietnamProvinces;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedItem());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSelectedItem() {
    if (!_scrollController.hasClients || widget.selectedProvince.isEmpty) {
      return;
    }
    final index = vietnamProvinces.indexWhere(
      (province) => province.name == widget.selectedProvince,
    );
    if (index < 0) return;
    final target = (index * 56.0 - 112).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  void _search(String query) {
    final normalizedQuery = _normalizeVietnamese(query.trim());
    setState(() {
      _filteredProvinces = normalizedQuery.isEmpty
          ? vietnamProvinces
          : vietnamProvinces
              .where(
                (province) => _normalizeVietnamese(province.name).contains(
                  normalizedQuery,
                ),
              )
              .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return SizedBox(
      height: height.clamp(480.0, 720.0),
      child: Column(
        children: [
          SizedBox(
            height: 56,
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
                    context.tr('project_select_province'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('provinceSearchField'),
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: _search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  hintText: context.tr('project_search_province'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('clear'),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.65),
                      width: 0.7,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredProvinces.isEmpty
                ? Center(child: Text(context.tr('project_province_not_found')))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _filteredProvinces.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 20,
                      endIndent: 20,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.72),
                    ),
                    itemBuilder: (context, index) {
                      final province = _filteredProvinces[index];
                      final selected = province.name == widget.selectedProvince;
                      return ListTile(
                        key: Key('province_${province.id}'),
                        selected: selected,
                        selectedTileColor:
                            AppColors.primary.withValues(alpha: 0.055),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        visualDensity: const VisualDensity(vertical: -1),
                        title: Text(
                          province.name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                        leading: Icon(
                          Icons.location_on_rounded,
                          size: 21,
                          color: selected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, province),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _normalizeVietnamese(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 7),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
