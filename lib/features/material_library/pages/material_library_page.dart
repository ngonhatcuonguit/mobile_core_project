import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_cubit.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_state.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class MaterialLibraryPage extends StatefulWidget {
  const MaterialLibraryPage({super.key});

  @override
  State<MaterialLibraryPage> createState() => _MaterialLibraryPageState();
}

class _MaterialLibraryPageState extends State<MaterialLibraryPage> {
  Future<void> _loadItems() async {
    await context.read<MaterialLibraryCubit>().load();
  }

  Future<void> _openEditor([MaterialLibraryItem? item]) async {
    final isEditing = item != null;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ItemEditorSheet(
        initialItem: item,
        onSubmit: (draft) async {
          await context.read<MaterialLibraryCubit>().save(
                isEditing ? draft.copyWith(id: item.id) : draft,
                isEditing: isEditing,
              );
        },
      ),
    );
    if (saved != true || !mounted) return;
    _showMessage(isEditing ? 'library_updated' : 'library_created');
  }

  Future<void> _openDetails(MaterialLibraryItem item) async {
    final editRequested = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemDetailsSheet(item: item),
    );
    if (editRequested == true && mounted) await _openEditor(item);
  }

  Future<void> _confirmDelete(MaterialLibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(context.tr('library_delete_title')),
        content: Text(
          context.tr('library_delete_message').replaceAll('{name}', item.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || item.id == null || !mounted) return;
    try {
      await context.read<MaterialLibraryCubit>().delete(item.id!);
      if (mounted) _showMessage('library_deleted');
    } catch (_) {
      if (mounted) _showMessage('library_save_error');
    }
  }

  void _showMessage(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr(key))));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaterialLibraryCubit, MaterialLibraryState>(
      builder: (context, state) {
        final items = state.items;
        final isLoading = state.status == MaterialLibraryStatus.loading &&
            state.items.isEmpty;
        final hasLoadError = state.status == MaterialLibraryStatus.failure &&
            state.items.isEmpty;
        final materials = items
            .where((item) => item.type == LibraryItemType.material)
            .toList();
        final labor =
            items.where((item) => item.type == LibraryItemType.labor).toList();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            toolbarHeight: 60,
            title: Text(
              context.tr('materials_title'),
              key: const Key('materialLibraryAppBarTitle'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadItems,
                child: CustomScrollView(
                  key: const Key('materialLibraryList'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasLoadError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LibraryMessage(
                          icon: Icons.storage_rounded,
                          title: context.tr('library_load_error'),
                          description: context.tr('library_load_error_detail'),
                          actionLabel: context.tr('retry'),
                          onAction: _loadItems,
                        ),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LibraryMessage(
                          icon: Icons.inventory_2_outlined,
                          title: context.tr('library_empty_title'),
                          description: context.tr('library_empty_description'),
                          actionLabel: context.tr('library_add'),
                          onAction: _openEditor,
                        ),
                      )
                    else ...[
                      _LibraryGroup(
                        title: context.tr('library_material_group'),
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFFEF9B36),
                        items: materials,
                        onTap: _openDetails,
                        onEdit: _openEditor,
                        onDelete: _confirmDelete,
                      ),
                      _LibraryGroup(
                        title: context.tr('library_labor_group'),
                        icon: Icons.engineering_rounded,
                        color: const Color(0xFF4B91F1),
                        items: labor,
                        onTap: _openDetails,
                        onEdit: _openEditor,
                        onDelete: _confirmDelete,
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 230)),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: math.max(
                  12,
                  MediaQuery.paddingOf(context).bottom - 12,
                ),
                child: FloatingActionButton.extended(
                  key: const Key('addLibraryItemButton'),
                  heroTag: 'add-library-item',
                  onPressed: _openEditor,
                  elevation: 5,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.tr('library_add_short')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryGroup extends StatelessWidget {
  const _LibraryGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<MaterialLibraryItem> items;
  final ValueChanged<MaterialLibraryItem> onTap;
  final ValueChanged<MaterialLibraryItem> onEdit;
  final ValueChanged<MaterialLibraryItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              final item = items[index];
              return _LibraryItemCard(
                item: item,
                color: color,
                onTap: () => onTap(item),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _ItemAction { edit, delete }

class _LibraryItemCard extends StatelessWidget {
  const _LibraryItemCard({
    required this.item,
    required this.color,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final MaterialLibraryItem item;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF373440) : const Color(0xFFF0EDF4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 6, 13),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.type == LibraryItemType.material
                        ? Icons.foundation_rounded
                        : Icons.handyman_rounded,
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${_formatPrice(context, item.price)} ₫',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${_localizedUnit(context, item.unit)}',
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_ItemAction>(
                  tooltip: context.tr('more_actions'),
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (action) {
                    if (action == _ItemAction.edit) {
                      onEdit();
                    } else {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ItemAction.edit,
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: context.tr('edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ItemAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: context.tr('delete'),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 190),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 37),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailsSheet extends StatelessWidget {
  const _ItemDetailsSheet({required this.item});

  final MaterialLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.type == LibraryItemType.material
        ? const Color(0xFFEF9B36)
        : const Color(0xFF4B91F1);
    return _SheetSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    item.type == LibraryItemType.material
                        ? Icons.foundation_rounded
                        : Icons.engineering_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.type == LibraryItemType.material
                            ? context.tr('library_material_group')
                            : context.tr('library_labor_group'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _DetailRow(
              label: context.tr('library_id'),
              value: '#${item.id ?? '-'}',
            ),
            _DetailRow(
              label: context.tr('library_price'),
              value: '${_formatPrice(context, item.price)} ₫',
            ),
            _DetailRow(
              label: context.tr('library_unit'),
              value: _localizedUnit(context, item.unit),
            ),
            if (item.hasPieceDimensions)
              _DetailRow(
                label: context.tr('library_dimensions'),
                value: '${_formatDimension(item.length!)} × '
                    '${_formatDimension(item.width!)} × '
                    '${_formatDimension(item.height!)} m',
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('editFromDetailButton'),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr('library_edit')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({
    required this.initialItem,
    required this.onSubmit,
  });

  final MaterialLibraryItem? initialItem;
  final Future<void> Function(MaterialLibraryItem item) onSubmit;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  static const _presetUnits = [
    'piece',
    'm3',
    'm2',
    'm',
    'kg',
    'ton',
    'set',
    'package',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _customUnitController;
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late LibraryItemType _type;
  late String _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item == null ? '' : item.price.round().toString(),
    );
    _type = item?.type ?? LibraryItemType.material;
    final unit = item?.unit ?? 'piece';
    _selectedUnit = _presetUnits.contains(unit) ? unit : 'custom';
    _customUnitController = TextEditingController(
      text: _selectedUnit == 'custom' ? unit : '',
    );
    _lengthController = TextEditingController(
      text: _dimensionInput(item?.length),
    );
    _widthController = TextEditingController(
      text: _dimensionInput(item?.width),
    );
    _heightController = TextEditingController(
      text: _dimensionInput(item?.height),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customUnitController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _selectType(LibraryItemType type) {
    setState(() {
      _type = type;
      if (type == LibraryItemType.labor) _selectedUnit = 'm2';
    });
  }

  Future<void> _chooseUnit() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UnitPickerSheet(
        units: const [..._presetUnits, 'custom'],
        selectedUnit: _selectedUnit,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedUnit = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final item = MaterialLibraryItem(
      id: widget.initialItem?.id,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      unit: _selectedUnit == 'custom'
          ? _customUnitController.text.trim()
          : _selectedUnit,
      type: _type,
      length: _selectedUnit == 'piece'
          ? _parseDimension(_lengthController.text)
          : null,
      width: _selectedUnit == 'piece'
          ? _parseDimension(_widthController.text)
          : null,
      height: _selectedUnit == 'piece'
          ? _parseDimension(_heightController.text)
          : null,
    );
    try {
      await widget.onSubmit(item);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.tr('library_save_error'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialItem != null;
    return _SheetSurface(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                Text(
                  editing
                      ? context.tr('library_edit_title')
                      : context.tr('library_add_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('library_type'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: LibraryItemType.values.map((type) {
                    final selected = _type == type;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: type == LibraryItemType.material ? 6 : 0,
                          left: type == LibraryItemType.labor ? 6 : 0,
                        ),
                        child: ChoiceChip(
                          key: Key('libraryType_${type.name}'),
                          selected: selected,
                          showCheckmark: false,
                          avatar: Icon(
                            type == LibraryItemType.material
                                ? Icons.inventory_2_outlined
                                : Icons.engineering_outlined,
                            size: 19,
                            color: selected ? Colors.white : AppColors.primary,
                          ),
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              type == LibraryItemType.material
                                  ? context.tr('library_material')
                                  : context.tr('library_labor'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => _selectType(type),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('libraryNameField'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('library_name'),
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.tr('library_name_required')
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('libraryPriceField'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.tr('library_price'),
                    hintText: context.tr('library_price_hint'),
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: '₫',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('library_price_required');
                    }
                    final price = double.tryParse(value);
                    return price == null || price < 0
                        ? context.tr('library_price_invalid')
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  key: const Key('libraryUnitField'),
                  onTap: _chooseUnit,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.tr('library_unit'),
                      prefixIcon: const Icon(Icons.straighten_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedUnit == 'custom'
                                ? context.tr('unit_custom')
                                : _localizedUnit(context, _selectedUnit),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                if (_selectedUnit == 'piece') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('library_piece_dimensions'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('library_piece_dimensions_hint'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _DimensionField(
                                key: const Key('libraryLengthField'),
                                controller: _lengthController,
                                label: context.tr('library_length'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DimensionField(
                                key: const Key('libraryWidthField'),
                                controller: _widthController,
                                label: context.tr('library_width'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DimensionField(
                                key: const Key('libraryHeightField'),
                                controller: _heightController,
                                label: context.tr('library_height'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (_selectedUnit == 'custom') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('libraryCustomUnitField'),
                    controller: _customUnitController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('library_custom_unit'),
                      hintText: context.tr('library_custom_unit_hint'),
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      if (_selectedUnit == 'custom' &&
                          (value == null || value.trim().isEmpty)) {
                        return context.tr('library_unit_required');
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const Key('saveLibraryItemButton'),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            editing
                                ? context.tr('save_changes')
                                : context.tr('library_create'),
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

class _DimensionField extends StatelessWidget {
  const _DimensionField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'm',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        errorMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.tr('library_dimension_required');
        }
        final dimension = _parseDimension(value);
        if (dimension == null || dimension <= 0) {
          return context.tr('library_dimension_invalid');
        }
        return null;
      },
    );
  }
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({
    required this.units,
    required this.selectedUnit,
  });

  final List<String> units;
  final String selectedUnit;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: _SheetHandle(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Text(
                context.tr('library_choose_unit'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final selected = unit == selectedUnit;
                  return Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: ListTile(
                      key: Key('unitOption_$unit'),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading: Icon(
                        unit == 'custom'
                            ? Icons.edit_note_rounded
                            : Icons.straighten_rounded,
                      ),
                      title: Text(
                        unit == 'custom'
                            ? context.tr('unit_custom')
                            : _localizedUnit(context, unit),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: Key('selectedUnitIndicator'),
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, unit),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        key: const Key('bottomSheetSafeArea'),
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: child,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

String _localizedUnit(BuildContext context, String unit) {
  const keys = {
    'piece': 'unit_piece',
    'm3': 'unit_cubic_meter',
    'm2': 'unit_square_meter',
    'm': 'unit_meter',
    'kg': 'unit_kilogram',
    'ton': 'unit_ton',
    'set': 'unit_set',
    'package': 'unit_package',
  };
  final key = keys[unit];
  return key == null ? unit : context.tr(key);
}

String _formatPrice(BuildContext context, double value) {
  final digits = value.round().toString();
  final separator =
      Localizations.localeOf(context).languageCode == 'vi' ? '.' : ',';
  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => separator,
  );
}

double? _parseDimension(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

String _dimensionInput(double? value) {
  if (value == null) return '';
  return _formatDimension(value);
}

String _formatDimension(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(
        RegExp(r'\.$'),
        '',
      );
}
