import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_theme.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ConstructionPlanApp extends StatelessWidget {
  const ConstructionPlanApp({
    super.key,
    this.debugShowCheckedModeBanner = false,
    this.materialLibraryStore,
  });

  final bool debugShowCheckedModeBanner;
  final MaterialLibraryStore? materialLibraryStore;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: AppConfig.appTitle,
                debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [Locale('vi'), Locale('en')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child ?? const SizedBox.shrink(),
                ),
                home: MainScreen(materialLibraryStore: materialLibraryStore),
              );
            },
          );
        },
      ),
    );
  }
}
