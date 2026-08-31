import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> bootstrap({bool debugShowCheckedModeBanner = false}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await _initializeLocalStorage();

  runApp(
    ConstructionPlanApp(
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

Future<void> _initializeLocalStorage() async {
  if (kIsWeb) {
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorage.webStorageDirectory,
      );
      return;
    } catch (error) {
      debugPrint('Could not initialize web storage: $error');
      HydratedBloc.storage = InMemoryStorage();
      return;
    }
  }

  Directory? storageDirectory;
  try {
    storageDirectory = await getApplicationDocumentsDirectory();
  } catch (error) {
    debugPrint('Could not access documents storage: $error');
    try {
      storageDirectory = await getTemporaryDirectory();
    } catch (fallbackError) {
      debugPrint('Could not access temporary storage: $fallbackError');
    }
  }

  if (storageDirectory != null) {
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: storageDirectory,
      );
      return;
    } catch (error) {
      debugPrint('Could not initialize persistent storage: $error');
    }
  }

  HydratedBloc.storage = InMemoryStorage();
}
