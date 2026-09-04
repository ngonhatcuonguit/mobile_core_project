import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/services/localization_service.dart';

/// A reusable settings widget that can be added to any page
class SettingsWidget extends StatelessWidget {
  final bool showLanguage;
  final bool showTheme;

  const SettingsWidget({
    super.key,
    this.showLanguage = true,
    this.showTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTheme) _SettingsRow(child: _buildThemeToggle(context)),
        if (showTheme && showLanguage) const SizedBox(height: 16),
        if (showLanguage) _SettingsRow(child: _buildLanguageToggle(context)),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;

        return SwitchListTile.adaptive(
          title: Text(localizations?.translate('theme') ?? 'Theme'),
          subtitle: Text(
            isDark
                ? (localizations?.translate('dark_mode') ?? 'Dark Mode')
                : (localizations?.translate('light_mode') ?? 'Light Mode'),
          ),
          value: isDark,
          onChanged: (_) {
            context.read<ThemeCubit>().toggleTheme();
          },
          activeThumbColor: AppColors.linearShapeFor(context),
          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        );
      },
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isVietnamese = locale.languageCode == 'vi';

        return SwitchListTile.adaptive(
          title: Text(localizations?.translate('language') ?? 'Language'),
          subtitle: Text(
            isVietnamese
                ? (localizations?.translate('vietnamese') ?? 'Vietnamese')
                : (localizations?.translate('english') ?? 'English'),
          ),
          value: isVietnamese,
          onChanged: (_) {
            context.read<LocaleCubit>().toggleLanguage();
          },
          activeThumbColor: AppColors.linearShapeFor(context),
          secondary: const Icon(Icons.language),
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.settingRowGradientFor(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
