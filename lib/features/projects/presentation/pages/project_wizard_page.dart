import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/data/project_cover_image_service.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/steps/project_basic_step.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/steps/project_details_step.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/steps/project_floors_roof_step.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/steps/project_foundation_step.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/steps/project_materials_step.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_wizard_stepper.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProjectWizardPage extends StatelessWidget {
  const ProjectWizardPage({super.key, this.initialProject});

  final ConstructionProject? initialProject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectWizardCubit(initialProject: initialProject),
      child: _ProjectWizardView(initialProject: initialProject),
    );
  }
}

class _ProjectWizardView extends StatefulWidget {
  const _ProjectWizardView({this.initialProject});

  final ConstructionProject? initialProject;

  @override
  State<_ProjectWizardView> createState() => _ProjectWizardViewState();
}

class _ProjectWizardViewState extends State<_ProjectWizardView> {
  final ScrollController _scrollController = ScrollController();
  bool _saving = false;
  bool _allowPop = false;

  static const _stepKeys = [
    'project_step_basic',
    'project_step_floors',
    'project_step_foundation',
    'project_step_materials',
    'project_step_details',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('project_exit_title')),
        content: Text(context.tr('project_exit_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('project_continue_editing')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('project_exit')),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _closeWithResult();
  }

  void _closeWithResult([bool? result]) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    final wizard = context.read<ProjectWizardCubit>();
    if (!wizard.next()) return;
    setState(() => _saving = true);
    try {
      final updatedProject = wizard.buildProject();
      final projectCubit = context.read<ProjectCubit>();
      if (widget.initialProject == null) {
        await projectCubit.create(updatedProject);
      } else {
        await projectCubit.update(updatedProject);
        final previousImage = widget.initialProject!.imagePath;
        if (previousImage != updatedProject.imagePath) {
          await const ProjectCoverImageService().delete(previousImage);
        }
      }
      if (mounted) _closeWithResult(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('project_save_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: BlocConsumer<ProjectWizardCubit, ProjectWizardState>(
        listenWhen: (previous, current) =>
            previous.currentStep != current.currentStep,
        listener: (_, __) => _scrollToTop(),
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                key: const Key('closeProjectWizardButton'),
                tooltip: context.tr('project_back'),
                onPressed: _requestClose,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                context.tr(
                  widget.initialProject == null
                      ? 'project_add_title'
                      : 'project_edit_title',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            body: Column(
              children: [
                ProjectWizardStepper(
                  currentStep: state.currentStep,
                  completedSteps: List.generate(5, state.isStepValid),
                  stepLabel: context.tr(_stepKeys[state.currentStep]),
                  onStepPressed:
                      context.read<ProjectWizardCubit>().goToCompletedStep,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: SingleChildScrollView(
                          key: ValueKey(state.currentStep),
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                          child: _stepBody(state.currentStep),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _WizardActions(
              currentStep: state.currentStep,
              saving: _saving,
              onBack: state.currentStep == 0
                  ? _requestClose
                  : context.read<ProjectWizardCubit>().back,
              onNext: () {
                if (context.read<ProjectWizardCubit>().next()) _scrollToTop();
              },
              onSave: _save,
            ),
          );
        },
      ),
    );
  }

  Widget _stepBody(int step) {
    switch (step) {
      case 0:
        return const ProjectBasicStep();
      case 1:
        return const ProjectFloorsRoofStep();
      case 2:
        return const ProjectFoundationStep();
      case 3:
        return const ProjectMaterialsStep();
      case 4:
        return const ProjectDetailsStep();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WizardActions extends StatelessWidget {
  const _WizardActions({
    required this.currentStep,
    required this.saving,
    required this.onBack,
    required this.onNext,
    required this.onSave,
  });

  final int currentStep;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('projectWizardBackButton'),
                  onPressed: saving ? null : onBack,
                  icon: Icon(
                    currentStep == 0
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                  ),
                  label: Text(
                    context.tr(currentStep == 0 ? 'cancel' : 'project_back'),
                    maxLines: 1,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.055),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: Key(
                    currentStep == 4
                        ? 'saveProjectButton'
                        : 'projectWizardNextButton',
                  ),
                  onPressed: saving
                      ? null
                      : currentStep == 4
                          ? onSave
                          : onNext,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          currentStep == 4
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    context.tr(
                      currentStep == 4
                          ? 'project_complete'
                          : 'project_continue',
                    ),
                    maxLines: 1,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
