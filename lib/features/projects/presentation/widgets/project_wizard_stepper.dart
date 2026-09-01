import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';

class ProjectWizardStepper extends StatelessWidget {
  const ProjectWizardStepper({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.stepLabel,
    required this.onStepPressed,
  });

  final int currentStep;
  final List<bool> completedSteps;
  final String stepLabel;
  final ValueChanged<int> onStepPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${currentStep + 1}/5',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stepLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '${((currentStep + 1) * 20)}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var index = 0; index < 5; index++) ...[
                  _StepNode(
                    index: index,
                    selected: index == currentStep,
                    completed: completedSteps[index],
                    onPressed: () => onStepPressed(index),
                  ),
                  if (index < 4)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 3,
                        color: index < currentStep
                            ? AppColors.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.selected,
    required this.completed,
    required this.onPressed,
  });

  final int index;
  final bool selected;
  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = selected || completed;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: AnimatedContainer(
          key: Key('projectWizardStep$index'),
          duration: const Duration(milliseconds: 220),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color:
                  active ? AppColors.primary : Theme.of(context).dividerColor,
              width: selected ? 3 : 2,
            ),
          ),
          alignment: Alignment.center,
          child: completed && !selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
              : Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
      ),
    );
  }
}
