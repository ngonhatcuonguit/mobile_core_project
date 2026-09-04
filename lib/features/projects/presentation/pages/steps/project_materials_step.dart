import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_cubit.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_state.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProjectMaterialsStep extends StatelessWidget {
  const ProjectMaterialsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, wizardState) {
        return BlocBuilder<MaterialLibraryCubit, MaterialLibraryState>(
          builder: (context, libraryState) {
            final accent = AppColors.linearShapeFor(context);
            final libraryMaterials = libraryState.items
                .map(_fromLibraryItem)
                .toList(growable: false);
            final suggestions = _suggestions(context)
                .where(
                  (suggestion) => !libraryMaterials.any(
                    (item) =>
                        item.name.toLowerCase() ==
                        suggestion.name.toLowerCase(),
                  ),
                )
                .toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeading(
                  title: context.tr('project_materials_title'),
                  description: context.tr('project_materials_description'),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${wizardState.materials.length} ${context.tr('project_materials_selected')}',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (libraryMaterials.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: context.tr('project_your_library'),
                    subtitle: context.tr('project_library_snapshot_hint'),
                  ),
                  const SizedBox(height: 10),
                  for (final material in libraryMaterials) ...[
                    _MaterialOption(
                      material: material,
                      selected: _isSelected(wizardState, material),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 22),
                _SectionTitle(
                  title: context.tr('project_suggested_materials'),
                  subtitle: libraryMaterials.isEmpty
                      ? context.tr('project_library_empty_suggestion')
                      : context.tr('project_suggestion_hint'),
                ),
                const SizedBox(height: 10),
                for (final material in suggestions) ...[
                  _MaterialOption(
                    material: material,
                    selected: _isSelected(wizardState, material),
                  ),
                  const SizedBox(height: 8),
                ],
                if (wizardState.showValidation &&
                    !wizardState.isStepValid(3)) ...[
                  const SizedBox(height: 8),
                  _ValidationNotice(
                    text: context.tr('project_materials_invalid'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  bool _isSelected(ProjectWizardState state, ProjectMaterial material) {
    return state.materials.any(
      (item) => item.selectionKey == material.selectionKey,
    );
  }

  ProjectMaterial _fromLibraryItem(MaterialLibraryItem item) {
    final catalogCode = item.catalogCode;
    return ProjectMaterial(
      selectionKey:
          catalogCode == null ? 'library:${item.id}' : 'catalog:$catalogCode',
      sourceLibraryId: item.id,
      catalogCode: catalogCode,
      name: item.name,
      unit: item.unit,
      unitPrice: item.price,
      type: item.type == LibraryItemType.material
          ? ProjectMaterialType.material
          : ProjectMaterialType.labor,
    );
  }

  List<ProjectMaterial> _suggestions(BuildContext context) {
    return [
      ProjectMaterial(
        selectionKey: 'catalog:brick',
        catalogCode: 'brick',
        name: context.tr('project_material_brick'),
        unit: 'piece',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:cement',
        catalogCode: 'cement',
        name: context.tr('project_material_cement'),
        unit: 'kg',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:sand',
        catalogCode: 'sand',
        name: context.tr('project_material_sand'),
        unit: 'm3',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:steel',
        catalogCode: 'steel',
        name: context.tr('project_material_steel'),
        unit: 'kg',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:stone',
        catalogCode: 'stone',
        name: context.tr('project_material_stone'),
        unit: 'm3',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:paint',
        catalogCode: 'paint',
        name: context.tr('project_material_paint'),
        unit: 'm2',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:labor',
        catalogCode: 'labor',
        name: context.tr('project_material_labor'),
        unit: 'm2',
        unitPrice: 0,
        type: ProjectMaterialType.labor,
      ),
    ];
  }
}

class _MaterialOption extends StatelessWidget {
  const _MaterialOption({required this.material, required this.selected});

  final ProjectMaterial material;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final hasPrice = material.unitPrice > 0;
    final accent = AppColors.linearShapeFor(context);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? accent : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        key: Key('projectMaterial_${material.selectionKey}'),
        value: selected,
        onChanged: (_) =>
            context.read<ProjectWizardCubit>().toggleMaterial(material),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        title: Text(
          material.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          hasPrice
              ? '${_formatPrice(material.unitPrice)} / ${material.unit}'
              : context.tr('project_price_not_set'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Icon(
          material.type == ProjectMaterialType.material
              ? Icons.inventory_2_outlined
              : Icons.engineering_outlined,
          color: selected ? accent : null,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ValidationNotice extends StatelessWidget {
  const _ValidationNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
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

String _formatPrice(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} ₫';
}
